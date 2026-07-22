part of '../local_training_repository.dart';

class _LocalTrainingPlanStore {
  _LocalTrainingPlanStore(this.database, this._syncQueue);

  final LocalTrainingDatabase database;
  final LocalSyncQueueRepository _syncQueue;

  Stream<List<LocalTrainingPlanModel>> watchPlans({bool? archived}) {
    final query = database.select(database.localRoutines)
      ..where(
        (routine) =>
            routine.deleted.equals(false) &
            (archived == null ? const Constant(true) : routine.archived.equals(archived)),
      )
      ..orderBy([(routine) => OrderingTerm.desc(routine.updatedAt)]);

    return query.watch().asyncMap(_buildPlans);
  }

  Future<List<LocalTrainingPlanModel>> getPlans() async {
    final rows =
        await (database.select(database.localRoutines)
              ..where((routine) => routine.deleted.equals(false))
              ..orderBy([(routine) => OrderingTerm.desc(routine.updatedAt)]))
            .get();

    return _buildPlans(rows);
  }

  Future<int> savePlan(LocalTrainingPlanModel plan) async {
    final now = DateTime.now();
    for (final day in plan.days.values) {
      for (final action in day.actions) {
        action.name = canonicalExerciseReference(action.name);
      }
    }
    return database.transaction(() async {
      final routineId = plan.id == null
          ? await database
                .into(database.localRoutines)
                .insert(
                  LocalRoutinesCompanion.insert(
                    syncId: Value(plan.syncId ?? SyncId.newId()),
                    name: plan.name,
                    totalWeeks: Value(plan.totalWeeks),
                    daysPerWeek: Value(plan.daysPerWeek),
                    archived: Value(plan.archived),
                    completedWeeksJson: Value(_encodeCompletedWeeks(plan.completedWeeks)),
                    syncStatus: const Value(localSyncPending),
                    deleted: const Value(false),
                    createdAt: now,
                    updatedAt: now,
                  ),
                )
          : plan.id!;

      if (plan.id != null) {
        await (database.update(
          database.localRoutines,
        )..where((routine) => routine.id.equals(routineId))).write(
          LocalRoutinesCompanion(
            name: Value(plan.name),
            totalWeeks: Value(plan.totalWeeks),
            daysPerWeek: Value(plan.daysPerWeek),
            archived: Value(plan.archived),
            completedWeeksJson: Value(_encodeCompletedWeeks(plan.completedWeeks)),
            syncStatus: const Value(localSyncPending),
            updatedAt: Value(now),
          ),
        );
        await _replacePlanChildren(routineId);
      }

      for (final day in plan.days.values) {
        final dayId = await database
            .into(database.localTrainingDays)
            .insert(
              LocalTrainingDaysCompanion.insert(
                syncId: Value(day.syncId ?? SyncId.newId()),
                routineId: routineId,
                week: day.week,
                day: day.day,
                name: day.name,
                actionsJson: Value(
                  jsonEncode(
                    day.actions
                        .map(
                          (action) => action
                              .copyWith(
                                name: canonicalExerciseReference(action.name),
                              )
                              .toJson(),
                        )
                        .toList(),
                  ),
                ),
                syncStatus: const Value(localSyncPending),
                updatedAt: now,
              ),
            );

        for (var i = 0; i < day.actions.length; i++) {
          final slotId = await database
              .into(database.localSlots)
              .insert(
                LocalSlotsCompanion.insert(
                  syncId: Value(SyncId.newId()),
                  dayId: dayId,
                  order: i,
                  syncStatus: const Value(localSyncPending),
                ),
              );
          final action = day.actions[i];
          await database
              .into(database.localSlotEntries)
              .insert(
                LocalSlotEntriesCompanion.insert(
                  syncId: Value(action.syncId ?? SyncId.newId()),
                  slotId: slotId,
                  exerciseName: canonicalExerciseReference(action.name),
                  targetSets: Value(action.targetSets),
                  targetReps: Value(action.targetReps),
                  targetWeight: Value(action.targetWeight),
                  recordMode: Value(action.recordMode),
                  syncStatus: const Value(localSyncPending),
                ),
              );
        }
      }

      await _syncQueue.enqueue(
        'routine',
        routineId,
        plan.id == null ? 'create' : 'update',
      );
      return routineId;
    });
  }

  Future<void> deletePlan(int routineId) async {
    final now = DateTime.now();
    await database.transaction(() async {
      await (database.update(
        database.localRoutines,
      )..where((routine) => routine.id.equals(routineId))).write(
        LocalRoutinesCompanion(
          deleted: const Value(true),
          syncStatus: const Value(localSyncPending),
          updatedAt: Value(now),
        ),
      );
      await _syncQueue.enqueue('routine', routineId, 'delete');
    });
  }

  Future<void> setPlanArchived(int routineId, bool archived) async {
    final now = DateTime.now();
    await database.transaction(() async {
      await (database.update(
        database.localRoutines,
      )..where((routine) => routine.id.equals(routineId))).write(
        LocalRoutinesCompanion(
          archived: Value(archived),
          syncStatus: const Value(localSyncPending),
          updatedAt: Value(now),
        ),
      );
      await _syncQueue.enqueue('routine', routineId, 'update');
    });
  }

  Future<Set<int>> toggleCompletedWeek(int routineId, int week) async {
    final routine = await (database.select(
      database.localRoutines,
    )..where((row) => row.id.equals(routineId))).getSingle();
    final completedWeeks = _decodeCompletedWeeks(routine.completedWeeksJson);
    if (!completedWeeks.add(week)) {
      completedWeeks.remove(week);
    }
    final now = DateTime.now();
    await database.transaction(() async {
      await (database.update(
        database.localRoutines,
      )..where((row) => row.id.equals(routineId))).write(
        LocalRoutinesCompanion(
          completedWeeksJson: Value(_encodeCompletedWeeks(completedWeeks)),
          syncStatus: const Value(localSyncPending),
          updatedAt: Value(now),
        ),
      );
      await _syncQueue.enqueue('routine', routineId, 'update');
    });
    return completedWeeks;
  }

  Set<int> _decodeCompletedWeeks(String raw) {
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<num>()
          .map((value) => value.toInt())
          .where((value) => value > 0)
          .toSet();
    } on Object {
      return <int>{};
    }
  }

  String _encodeCompletedWeeks(Set<int> weeks) {
    final sorted = weeks.where((week) => week > 0).toList()..sort();
    return jsonEncode(sorted);
  }

  Future<List<LocalTrainingPlanModel>> _buildPlans(List<LocalRoutine> routines) async {
    final daysByRoutineId = await _loadDaysForRoutines(routines.map((routine) => routine.id));
    return routines
        .map(
          (routine) => LocalTrainingPlanModel(
            id: routine.id,
            syncId: routine.syncId,
            name: routine.name,
            totalWeeks: routine.totalWeeks,
            daysPerWeek: routine.daysPerWeek,
            archived: routine.archived,
            completedWeeks: _decodeCompletedWeeks(routine.completedWeeksJson),
            syncStatus: routine.syncStatus,
            days: daysByRoutineId[routine.id] ?? <String, LocalTrainingDayModel>{},
          ),
        )
        .toList();
  }

  Future<Map<int, Map<String, LocalTrainingDayModel>>> _loadDaysForRoutines(
    Iterable<int> routineIds,
  ) async {
    final ids = routineIds.toSet().toList();
    if (ids.isEmpty) {
      return <int, Map<String, LocalTrainingDayModel>>{};
    }

    final dayRows =
        await (database.select(database.localTrainingDays)
              ..where((day) => day.routineId.isIn(ids))
              ..orderBy([
                (day) => OrderingTerm.asc(day.routineId),
                (day) => OrderingTerm.asc(day.week),
                (day) => OrderingTerm.asc(day.day),
              ]))
            .get();
    if (dayRows.isEmpty) {
      return <int, Map<String, LocalTrainingDayModel>>{};
    }

    final actionsByDayId = <int, List<LocalTrainingActionModel>>{};
    for (final day in dayRows) {
      actionsByDayId[day.id] = (jsonDecode(day.actionsJson) as List<dynamic>)
          .map(LocalTrainingActionModel.fromJson)
          .toList();
    }

    await _hydrateActionTargetsFromSlots(actionsByDayId);

    final result = <int, Map<String, LocalTrainingDayModel>>{};
    for (final day in dayRows) {
      final days = result.putIfAbsent(day.routineId, () => <String, LocalTrainingDayModel>{});
      days['${day.week}-${day.day}'] = LocalTrainingDayModel(
        id: day.id,
        syncId: day.syncId,
        week: day.week,
        day: day.day,
        name: day.name,
        actions: actionsByDayId[day.id] ?? <LocalTrainingActionModel>[],
      );
    }
    return result;
  }

  Future<void> _hydrateActionTargetsFromSlots(
    Map<int, List<LocalTrainingActionModel>> actionsByDayId,
  ) async {
    final dayIds = actionsByDayId.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();
    if (dayIds.isEmpty) {
      return;
    }

    final slots =
        await (database.select(database.localSlots)
              ..where((slot) => slot.dayId.isIn(dayIds))
              ..orderBy([
                (slot) => OrderingTerm.asc(slot.dayId),
                (slot) => OrderingTerm.asc(slot.order),
              ]))
            .get();
    if (slots.isEmpty) {
      return;
    }

    final slotIds = slots.map((slot) => slot.id).toList();
    final entries = await (database.select(
      database.localSlotEntries,
    )..where((entry) => entry.slotId.isIn(slotIds))).get();
    final entryBySlotId = <int, LocalSlotEntry>{};
    for (final entry in entries) {
      entryBySlotId.putIfAbsent(entry.slotId, () => entry);
    }

    for (final slot in slots) {
      final actions = actionsByDayId[slot.dayId];
      if (actions == null || slot.order < 0 || slot.order >= actions.length) {
        continue;
      }
      final entry = entryBySlotId[slot.id];
      if (entry == null) {
        continue;
      }

      actions[slot.order] = actions[slot.order].copyWith(
        syncId: entry.syncId,
        name: entry.exerciseName,
        targetSets: entry.targetSets,
        targetReps: entry.targetReps,
        targetWeight: entry.targetWeight,
        recordMode: normalizeLocalRecordMode(entry.recordMode),
        targetDurationSeconds: actions[slot.order].targetDurationSeconds,
        targetRestSeconds: actions[slot.order].targetRestSeconds,
        note: actions[slot.order].note,
      );
    }
  }

  Future<void> _replacePlanChildren(int routineId) async {
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.routineId.equals(routineId))).get();
    final referencedDayIds = await _referencedTrainingDayIds(days.map((day) => day.id));
    for (final day in days) {
      final slots = await (database.select(
        database.localSlots,
      )..where((slot) => slot.dayId.equals(day.id))).get();
      for (final slot in slots) {
        await (database.delete(
          database.localSlotEntries,
        )..where((entry) => entry.slotId.equals(slot.id))).go();
      }
      await (database.delete(
        database.localSlots,
      )..where((slot) => slot.dayId.equals(day.id))).go();
      if (!referencedDayIds.contains(day.id)) {
        await (database.delete(
          database.localTrainingDays,
        )..where((row) => row.id.equals(day.id))).go();
      }
    }
  }

  Future<Set<int>> _referencedTrainingDayIds(Iterable<int> dayIds) async {
    final ids = dayIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final sessionRefs = await (database.select(
      database.localWorkoutSessions,
    )..where((session) => session.dayId.isIn(ids))).get();
    final logRefs = await (database.select(
      database.localWorkoutLogs,
    )..where((log) => log.dayId.isIn(ids))).get();
    return {
      ...sessionRefs.map((session) => session.dayId).whereType<int>(),
      ...logRefs.map((log) => log.dayId).whereType<int>(),
    };
  }
}

part of '../local_training_repository.dart';

class _LocalTrainingSeedService {
  _LocalTrainingSeedService(this.database);

  final LocalTrainingDatabase database;

  Future<void> ensureSeedData() async {
    final hasServerDemo = await (database.select(
      database.localRoutines,
    )..where((routine) => routine.remoteId.equals(184))).getSingleOrNull();
    if (hasServerDemo != null) {
      await standardizeExerciseNames();
      return;
    }

    final imported = await _tryImportDemoTrainingData();
    if (imported) {
      await standardizeExerciseNames();
      return;
    }

    final count = await database.localRoutines.count().getSingle();
    if (count > 0) {
      await standardizeExerciseNames();
      return;
    }

    return;
  }

  Future<int> standardizeExerciseNames() async {
    var changed = 0;
    await database.transaction(() async {
      changed += await _standardizeTrainingDays();
      changed += await _standardizeSlotEntries();
      changed += await _standardizeWorkoutLogs();
    });
    return changed;
  }

  Future<int> _standardizeTrainingDays() async {
    final rows = await database.select(database.localTrainingDays).get();
    var changed = 0;
    for (final row in rows) {
      List<dynamic> decoded;
      try {
        decoded = jsonDecode(row.actionsJson) as List<dynamic>;
      } catch (_) {
        continue;
      }

      final actions = decoded.map(LocalTrainingActionModel.fromJson).toList();
      var hasChange = false;
      final updatedActions = actions.map((action) {
        final standardName = standardExerciseNameFor(action.name);
        if (standardName != action.name) {
          hasChange = true;
          return action.copyWith(name: standardName);
        }
        return action;
      }).toList();

      if (!hasChange) {
        continue;
      }

      await (database.update(
        database.localTrainingDays,
      )..where((day) => day.id.equals(row.id))).write(
        LocalTrainingDaysCompanion(
          actionsJson: Value(
            jsonEncode(
              updatedActions.map((action) => action.toJson()).toList(),
            ),
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
      changed += 1;
    }
    return changed;
  }

  Future<int> _standardizeSlotEntries() async {
    final rows = await database.select(database.localSlotEntries).get();
    var changed = 0;
    for (final row in rows) {
      final standardName = standardExerciseNameFor(row.exerciseName);
      if (standardName == row.exerciseName) {
        continue;
      }
      await (database.update(database.localSlotEntries)..where((entry) => entry.id.equals(row.id)))
          .write(LocalSlotEntriesCompanion(exerciseName: Value(standardName)));
      changed += 1;
    }
    return changed;
  }

  Future<int> _standardizeWorkoutLogs() async {
    final rows = await database.select(database.localWorkoutLogs).get();
    var changed = 0;
    for (final row in rows) {
      final standardName = standardExerciseNameFor(row.exerciseName);
      if (standardName == row.exerciseName) {
        continue;
      }
      await (database.update(database.localWorkoutLogs)..where((log) => log.id.equals(row.id)))
          .write(LocalWorkoutLogsCompanion(exerciseName: Value(standardName)));
      changed += 1;
    }
    return changed;
  }

  Future<bool> _tryImportDemoTrainingData() async {
    Map<String, dynamic> data;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/demo_training_data.json',
      );
      data = jsonDecode(raw) as Map<String, dynamic>;
    } on Object {
      return false;
    }

    final routines = data['routines'];
    if (routines is! List || routines.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    await database.transaction(() async {
      await _clearTrainingData();

      final routineIds = <int, int>{};
      final dayIds = <int, int>{};
      final sessionIds = <int, int>{};

      for (final item in routines.whereType<Map>()) {
        final remoteId = (item['remoteId'] as num?)?.toInt();
        if (remoteId == null) {
          continue;
        }
        final createdAt = _parseDateTime(item['createdAt']) ?? now;
        final localId = await database
            .into(database.localRoutines)
            .insert(
              LocalRoutinesCompanion.insert(
                remoteId: Value(remoteId),
                name: item['name'] as String? ?? '导入训练计划',
                totalWeeks: Value((item['totalWeeks'] as num?)?.toInt() ?? 8),
                daysPerWeek: Value((item['daysPerWeek'] as num?)?.toInt() ?? 7),
                syncStatus: const Value(localSyncSynced),
                deleted: const Value(false),
                createdAt: createdAt,
                updatedAt: now,
              ),
            );
        routineIds[remoteId] = localId;
      }

      for (final item in (data['days'] as List? ?? const []).whereType<Map>()) {
        final remoteId = (item['remoteId'] as num?)?.toInt();
        final routineRemoteId = (item['routineRemoteId'] as num?)?.toInt();
        final routineId = routineIds[routineRemoteId];
        if (remoteId == null || routineId == null) {
          continue;
        }

        final actions = (item['actions'] as List? ?? const []).whereType<Map>().map((action) {
          final recordMode = normalizeLocalRecordMode(action['recordMode']);
          return LocalTrainingActionModel(
            name: canonicalExerciseReference(
              action['name'] as String? ?? '未命名动作',
            ),
            targetSets: (action['targetSets'] as num?)?.toInt(),
            targetReps: (action['targetReps'] as num?)?.toInt() ?? 8,
            targetWeight: (action['targetWeight'] as num?)?.toDouble(),
            targetRestSeconds: (action['targetRestSeconds'] as num?)?.toInt(),
            targetDurationSeconds: (action['targetDurationSeconds'] as num?)?.toInt(),
            recordMode: recordMode,
            note: action['note'] as String? ?? '',
          );
        }).toList();

        final dayId = await database
            .into(database.localTrainingDays)
            .insert(
              LocalTrainingDaysCompanion.insert(
                remoteId: Value(remoteId),
                routineId: routineId,
                week: (item['week'] as num?)?.toInt() ?? 1,
                day: (item['day'] as num?)?.toInt() ?? 1,
                name: item['name'] as String? ?? '训练日',
                actionsJson: Value(
                  jsonEncode(actions.map((action) => action.toJson()).toList()),
                ),
                syncStatus: const Value(localSyncSynced),
                updatedAt: now,
              ),
            );
        dayIds[remoteId] = dayId;

        for (var i = 0; i < actions.length; i++) {
          final slotId = await database
              .into(database.localSlots)
              .insert(
                LocalSlotsCompanion.insert(
                  dayId: dayId,
                  order: i,
                  syncStatus: const Value(localSyncSynced),
                ),
              );
          final action = actions[i];
          await database
              .into(database.localSlotEntries)
              .insert(
                LocalSlotEntriesCompanion.insert(
                  slotId: slotId,
                  exerciseName: action.name,
                  targetSets: Value(action.targetSets),
                  targetReps: Value(action.targetReps),
                  targetWeight: Value(action.targetWeight),
                  recordMode: Value(action.recordMode),
                  syncStatus: const Value(localSyncSynced),
                ),
              );
        }
      }

      for (final item in (data['sessions'] as List? ?? const []).whereType<Map>()) {
        final remoteId = (item['remoteId'] as num?)?.toInt();
        final routineRemoteId = (item['routineRemoteId'] as num?)?.toInt();
        final dayRemoteId = (item['dayRemoteId'] as num?)?.toInt();
        final routineId = routineIds[routineRemoteId];
        if (remoteId == null || routineId == null) {
          continue;
        }
        final startedAt = _parseDateTime(item['startedAt']) ?? now;
        final localId = await database
            .into(database.localWorkoutSessions)
            .insert(
              LocalWorkoutSessionsCompanion.insert(
                remoteId: Value(remoteId),
                routineId: routineId,
                dayId: Value(dayIds[dayRemoteId]),
                startedAt: startedAt,
                endedAt: Value(
                  _parseDateTime(item['endedAt']) ?? startedAt.add(const Duration(minutes: 45)),
                ),
                note: Value(item['note'] as String? ?? '来自导入数据的训练记录'),
                syncStatus: const Value(localSyncSynced),
                updatedAt: now,
              ),
            );
        sessionIds[remoteId] = localId;
      }

      for (final item in (data['logs'] as List? ?? const []).whereType<Map>()) {
        final remoteId = (item['remoteId'] as num?)?.toInt();
        final sessionRemoteId = (item['sessionRemoteId'] as num?)?.toInt();
        final routineRemoteId = (item['routineRemoteId'] as num?)?.toInt();
        final dayRemoteId = (item['dayRemoteId'] as num?)?.toInt();
        final sessionId = sessionIds[sessionRemoteId];
        final routineId = routineIds[routineRemoteId];
        if (remoteId == null || sessionId == null || routineId == null) {
          continue;
        }
        await database
            .into(database.localWorkoutLogs)
            .insert(
              LocalWorkoutLogsCompanion.insert(
                remoteId: Value(remoteId),
                sessionId: sessionId,
                routineId: routineId,
                dayId: Value(dayIds[dayRemoteId]),
                exerciseName: canonicalExerciseReference(
                  item['exerciseName'] as String? ?? '未命名动作',
                ),
                setIndex: (item['setIndex'] as num?)?.toInt() ?? 1,
                weight: Value((item['weight'] as num?)?.toDouble() ?? 0),
                reps: Value((item['reps'] as num?)?.toInt() ?? 0),
                rir: Value((item['rir'] as num?)?.toDouble()),
                durationSeconds: Value(
                  (item['durationSeconds'] as num?)?.toInt() ?? 0,
                ),
                note: Value(item['note'] as String? ?? ''),
                recordMode: Value(normalizeLocalRecordMode(item['recordMode'])),
                syncStatus: const Value(localSyncSynced),
                createdAt: _parseDateTime(item['createdAt']) ?? now,
              ),
            );
      }
    });

    return true;
  }

  Future<void> _clearTrainingData() async {
    await database.delete(database.localSyncQueue).go();
    await database.delete(database.localWorkoutLogs).go();
    await database.delete(database.localWorkoutSessions).go();
    await database.delete(database.localSlotEntries).go();
    await database.delete(database.localSlots).go();
    await database.delete(database.localTrainingDays).go();
    await database.delete(database.localRoutines).go();
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

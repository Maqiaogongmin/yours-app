import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/exercise_standardization.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/sync_identity.dart';

class LocalTrainingRepository {
  final LocalTrainingDatabase _initialDatabase;

  LocalTrainingRepository(this._initialDatabase);

  LocalTrainingDatabase get database => locator.isRegistered<LocalTrainingDatabase>()
      ? locator<LocalTrainingDatabase>()
      : _initialDatabase;

  LocalSyncQueueRepository get _syncQueue => LocalSyncQueueRepository(database);

  Stream<List<LocalTrainingPlanModel>> watchPlans({bool? archived}) {
    final query = database.select(database.localRoutines)
      ..where(
        (routine) =>
            routine.deleted.equals(false) &
            (archived == null ? const Constant(true) : routine.archived.equals(archived)),
      )
      ..orderBy([(routine) => OrderingTerm.desc(routine.updatedAt)]);

    return query.watch().asyncMap((rows) async {
      final plans = <LocalTrainingPlanModel>[];
      for (final routine in rows) {
        final days = await _loadDays(routine.id);
        plans.add(
          LocalTrainingPlanModel(
            id: routine.id,
            syncId: routine.syncId,
            name: routine.name,
            totalWeeks: routine.totalWeeks,
            daysPerWeek: routine.daysPerWeek,
            archived: routine.archived,
            completedWeeks: _decodeCompletedWeeks(routine.completedWeeksJson),
            syncStatus: routine.syncStatus,
            days: days,
          ),
        );
      }
      return plans;
    });
  }

  Future<List<LocalTrainingPlanModel>> getPlans() async {
    final rows =
        await (database.select(database.localRoutines)
              ..where((routine) => routine.deleted.equals(false))
              ..orderBy([(routine) => OrderingTerm.desc(routine.updatedAt)]))
            .get();

    final plans = <LocalTrainingPlanModel>[];
    for (final routine in rows) {
      plans.add(
        LocalTrainingPlanModel(
          id: routine.id,
          syncId: routine.syncId,
          name: routine.name,
          totalWeeks: routine.totalWeeks,
          daysPerWeek: routine.daysPerWeek,
          archived: routine.archived,
          completedWeeks: _decodeCompletedWeeks(routine.completedWeeksJson),
          syncStatus: routine.syncStatus,
          days: await _loadDays(routine.id),
        ),
      );
    }
    return plans;
  }

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

        final actions = (item['actions'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (action) => LocalTrainingActionModel(
                name: canonicalExerciseReference(
                  action['name'] as String? ?? '未命名动作',
                ),
                targetSets: (action['targetSets'] as num?)?.toInt() ?? 3,
                targetReps: (action['targetReps'] as num?)?.toInt() ?? 8,
                targetWeight: (action['targetWeight'] as num?)?.toDouble(),
                targetRestSeconds: (action['targetRestSeconds'] as num?)?.toInt(),
                recordMode: normalizeLocalRecordMode(action['recordMode']),
                note: action['note'] as String? ?? '',
              ),
            )
            .toList();

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

  Future<int> startSession(
    LocalTrainingPlanModel plan,
    LocalTrainingDayModel? day,
  ) async {
    final now = DateTime.now();
    final sessionId = await database
        .into(database.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            syncId: Value(SyncId.newId()),
            routineId: plan.id!,
            dayId: Value(day?.id),
            startedAt: now,
            syncStatus: const Value(localSyncPending),
            updatedAt: now,
          ),
        );
    await _syncQueue.enqueue('workout_session', sessionId, 'create');
    return sessionId;
  }

  Future<void> finishSession(int sessionId, {String note = ''}) async {
    final now = DateTime.now();
    await (database.update(
      database.localWorkoutSessions,
    )..where((session) => session.id.equals(sessionId))).write(
      LocalWorkoutSessionsCompanion(
        endedAt: Value(now),
        note: Value(note),
        syncStatus: const Value(localSyncPending),
        updatedAt: Value(now),
      ),
    );
    await _syncQueue.enqueue('workout_session', sessionId, 'update');
  }

  Future<LocalWorkoutSessionResumeModel?> findOpenSessionForDay({
    required int routineId,
    int? dayId,
  }) async {
    final sessionsQuery = database.select(database.localWorkoutSessions)
      ..where(
        (session) =>
            session.routineId.equals(routineId) &
            session.endedAt.isNull() &
            (dayId == null ? session.dayId.isNull() : session.dayId.equals(dayId)),
      )
      ..orderBy([(session) => OrderingTerm.desc(session.startedAt)]);
    final sessions = await sessionsQuery.get();
    for (final session in sessions) {
      final logs =
          await (database.select(database.localWorkoutLogs)
                ..where((log) => log.sessionId.equals(session.id))
                ..orderBy([
                  (log) => OrderingTerm.asc(log.createdAt),
                  (log) => OrderingTerm.asc(log.id),
                  (log) => OrderingTerm.asc(log.setIndex),
                ]))
              .get();
      if (logs.isEmpty) {
        continue;
      }
      return LocalWorkoutSessionResumeModel(
        sessionId: session.id,
        startedAt: session.startedAt,
        logs: logs
            .map(
              (log) => LocalWorkoutLogEditModel(
                id: log.id,
                sessionId: log.sessionId,
                exerciseName: log.exerciseName,
                setIndex: log.setIndex,
                weight: log.weight,
                reps: log.reps,
                note: log.note,
                recordMode: normalizeLocalRecordMode(log.recordMode),
                durationSeconds: log.durationSeconds,
                createdAt: log.createdAt,
              ),
            )
            .toList(),
      );
    }
    return null;
  }

  Future<int> addLog({
    required int sessionId,
    required int routineId,
    int? dayId,
    required String exerciseName,
    required int setIndex,
    required double weight,
    required int reps,
    double? rir,
    required int durationSeconds,
    String note = '',
    String recordMode = localRecordModeStandard,
  }) async {
    final logId = await database
        .into(database.localWorkoutLogs)
        .insert(
          LocalWorkoutLogsCompanion.insert(
            syncId: Value(SyncId.newId()),
            sessionId: sessionId,
            routineId: routineId,
            dayId: Value(dayId),
            exerciseName: canonicalExerciseReference(exerciseName),
            setIndex: setIndex,
            weight: Value(weight),
            reps: Value(reps),
            rir: Value(rir),
            durationSeconds: Value(durationSeconds),
            note: Value(note.trim()),
            recordMode: Value(normalizeLocalRecordMode(recordMode)),
            syncStatus: const Value(localSyncPending),
            createdAt: DateTime.now(),
          ),
        );
    await _syncQueue.enqueue('workout_log', logId, 'create');
    return logId;
  }

  Future<void> deleteWorkoutLog(int logId) async {
    await database.transaction(() async {
      final log = await (database.select(
        database.localWorkoutLogs,
      )..where((row) => row.id.equals(logId))).getSingleOrNull();
      final removedPendingCreate = await _syncQueue.removePendingCreate('workout_log', logId);
      await _syncQueue.removePendingNonDelete('workout_log', logId);
      await (database.delete(
        database.localWorkoutLogs,
      )..where((log) => log.id.equals(logId))).go();
      if (log != null && removedPendingCreate == 0 && log.syncId.trim().isNotEmpty) {
        await _syncQueue.enqueue(
          'workout_log',
          logId,
          'delete',
          entitySyncId: 'workout_log:${log.syncId}',
        );
      }
    });
  }

  Future<void> deleteWorkoutSession(int sessionId) async {
    await database.transaction(() async {
      final session = await (database.select(
        database.localWorkoutSessions,
      )..where((row) => row.id.equals(sessionId))).getSingleOrNull();
      final logs = await (database.select(
        database.localWorkoutLogs,
      )..where((log) => log.sessionId.equals(sessionId))).get();
      for (final log in logs) {
        await _syncQueue.removePendingCreate('workout_log', log.id);
        await _syncQueue.removePendingNonDelete('workout_log', log.id);
      }
      final removedPendingCreate = await _syncQueue.removePendingCreate(
        'workout_session',
        sessionId,
      );
      await _syncQueue.removePendingNonDelete('workout_session', sessionId);
      await (database.delete(
        database.localWorkoutLogs,
      )..where((log) => log.sessionId.equals(sessionId))).go();
      await (database.delete(
        database.localWorkoutSessions,
      )..where((session) => session.id.equals(sessionId))).go();
      if (session != null && removedPendingCreate == 0 && session.syncId.trim().isNotEmpty) {
        await _syncQueue.enqueue(
          'workout_session',
          sessionId,
          'delete',
          entitySyncId: 'workout_session:${session.syncId}',
        );
      }
    });
  }

  /// Delete all logs for a given session + exercise + set index combination.
  /// Used to ensure at-most-one record per set before inserting a correction.
  Future<void> deleteSetLogs({
    required int sessionId,
    required String exerciseName,
    required int setIndex,
  }) async {
    final reference = canonicalExerciseReference(exerciseName);
    final rows =
        await (database.select(database.localWorkoutLogs)..where(
              (log) =>
                  log.sessionId.equals(sessionId) &
                  log.exerciseName.equals(reference) &
                  log.setIndex.equals(setIndex),
            ))
            .get();
    for (final row in rows) {
      await deleteWorkoutLog(row.id);
    }
  }

  Future<List<LocalWorkoutLogEditModel>> getLogsForDate(DateTime date) async {
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));
    final logs =
        await (database.select(database.localWorkoutLogs)
              ..where((log) => log.createdAt.isBetweenValues(from, to))
              ..orderBy([
                (log) => OrderingTerm.asc(log.sessionId),
                (log) => OrderingTerm.asc(log.createdAt),
                (log) => OrderingTerm.asc(log.id),
                (log) => OrderingTerm.asc(log.setIndex),
              ]))
            .get();
    final usedSetIndexes = <String, Set<int>>{};
    return logs.map((log) {
      final groupKey = '${log.sessionId}:${log.exerciseName}';
      final used = usedSetIndexes.putIfAbsent(groupKey, () => <int>{});
      var displaySetIndex = log.setIndex;
      if (displaySetIndex <= 0 || used.contains(displaySetIndex)) {
        displaySetIndex = 1;
        while (used.contains(displaySetIndex)) {
          displaySetIndex += 1;
        }
      }
      used.add(displaySetIndex);
      return LocalWorkoutLogEditModel(
        id: log.id,
        sessionId: log.sessionId,
        exerciseName: log.exerciseName,
        setIndex: displaySetIndex,
        weight: log.weight,
        reps: log.reps,
        note: log.note,
        recordMode: normalizeLocalRecordMode(log.recordMode),
        durationSeconds: log.durationSeconds,
        createdAt: log.createdAt,
      );
    }).toList();
  }

  Future<List<LocalWorkoutSessionEditModel>> getWorkoutSessionsForDate(DateTime date) async {
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));
    final sessions =
        await (database.select(database.localWorkoutSessions)
              ..where((session) => session.startedAt.isBetweenValues(from, to))
              ..orderBy([(session) => OrderingTerm.asc(session.startedAt)]))
            .get();
    final result = <LocalWorkoutSessionEditModel>[];
    for (final session in sessions) {
      final logs =
          await (database.select(database.localWorkoutLogs)
                ..where((log) => log.sessionId.equals(session.id))
                ..orderBy([
                  (log) => OrderingTerm.asc(log.createdAt),
                  (log) => OrderingTerm.asc(log.id),
                  (log) => OrderingTerm.asc(log.setIndex),
                ]))
              .get();
      if (logs.isEmpty && session.endedAt != null) {
        continue;
      }
      final usedSetIndexes = <String, Set<int>>{};
      result.add(
        LocalWorkoutSessionEditModel(
          id: session.id,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          note: session.note,
          logs: logs.map((log) {
            final groupKey = '${log.sessionId}:${log.exerciseName}';
            final used = usedSetIndexes.putIfAbsent(groupKey, () => <int>{});
            var displaySetIndex = log.setIndex;
            if (displaySetIndex <= 0 || used.contains(displaySetIndex)) {
              displaySetIndex = 1;
              while (used.contains(displaySetIndex)) {
                displaySetIndex += 1;
              }
            }
            used.add(displaySetIndex);
            return LocalWorkoutLogEditModel(
              id: log.id,
              sessionId: log.sessionId,
              exerciseName: log.exerciseName,
              setIndex: displaySetIndex,
              weight: log.weight,
              reps: log.reps,
              note: log.note,
              recordMode: normalizeLocalRecordMode(log.recordMode),
              durationSeconds: log.durationSeconds,
              createdAt: log.createdAt,
            );
          }).toList(),
        ),
      );
    }
    return result;
  }

  Future<void> updateWorkoutLog({
    required int logId,
    required int setIndex,
    required double weight,
    required int reps,
    required String note,
    required int durationSeconds,
  }) async {
    await (database.update(
      database.localWorkoutLogs,
    )..where((log) => log.id.equals(logId))).write(
      LocalWorkoutLogsCompanion(
        setIndex: Value(setIndex.clamp(1, 99)),
        weight: Value(weight),
        reps: Value(reps.clamp(0, 999)),
        note: Value(note.trim()),
        durationSeconds: Value(durationSeconds.clamp(0, 24 * 60 * 60)),
        syncStatus: const Value(localSyncPending),
      ),
    );
    await _syncQueue.enqueue('workout_log', logId, 'update');
  }

  Future<void> updateWorkoutSession({
    required int sessionId,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String note,
  }) async {
    if (endedAt != null) {
      if (endedAt.isBefore(startedAt)) {
        throw ArgumentError('结束时间不能早于开始时间');
      }
      if (!_isSameDate(startedAt, endedAt)) {
        throw ArgumentError('暂不支持跨午夜训练记录');
      }
    }
    final now = DateTime.now();
    final updated =
        await (database.update(
          database.localWorkoutSessions,
        )..where((session) => session.id.equals(sessionId))).write(
          LocalWorkoutSessionsCompanion(
            startedAt: Value(startedAt),
            endedAt: Value(endedAt),
            note: Value(note.trim()),
            syncStatus: const Value(localSyncPending),
            updatedAt: Value(now),
          ),
        );
    if (updated == 0) {
      throw StateError('训练记录不存在');
    }
    await _syncQueue.enqueue('workout_session', sessionId, 'update');
  }

  Future<int> completeEmptyWorkoutSession({
    required int sessionId,
    required DateTime startedAt,
    required DateTime endedAt,
    required String sessionNote,
    required String exerciseName,
    required String recordMode,
    required int setIndex,
    required double weight,
    required int reps,
    required String actionNote,
  }) async {
    if (endedAt.isBefore(startedAt)) {
      throw ArgumentError('结束时间不能早于开始时间');
    }
    if (!_isSameDate(startedAt, endedAt)) {
      throw ArgumentError('暂不支持跨午夜训练记录');
    }
    final trimmedExercise = canonicalExerciseReference(exerciseName);
    if (trimmedExercise.isEmpty) {
      throw ArgumentError('请填写动作名称');
    }

    final session = await (database.select(
      database.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      throw StateError('训练记录不存在');
    }
    final existingLog =
        await (database.select(database.localWorkoutLogs)
              ..where((log) => log.sessionId.equals(sessionId))
              ..limit(1))
            .getSingleOrNull();
    if (existingLog != null) {
      throw StateError('训练记录已经包含动作数据');
    }

    int? validDayId;
    if (session.dayId != null) {
      final day = await (database.select(
        database.localTrainingDays,
      )..where((row) => row.id.equals(session.dayId!))).getSingleOrNull();
      validDayId = day?.id;
    }
    final normalizedMode = normalizeLocalRecordMode(recordMode);
    final durationSeconds = normalizedMode == localRecordModeFree
        ? endedAt.difference(startedAt).inSeconds
        : 0;
    final now = DateTime.now();
    late final int logId;
    await database.transaction(() async {
      await (database.update(
        database.localWorkoutSessions,
      )..where((row) => row.id.equals(sessionId))).write(
        LocalWorkoutSessionsCompanion(
          dayId: Value(validDayId),
          startedAt: Value(startedAt),
          endedAt: Value(endedAt),
          note: Value(sessionNote.trim()),
          syncStatus: const Value(localSyncPending),
          updatedAt: Value(now),
        ),
      );
      logId = await database
          .into(database.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              syncId: Value(SyncId.newId()),
              sessionId: sessionId,
              routineId: session.routineId,
              dayId: Value(validDayId),
              exerciseName: trimmedExercise,
              setIndex: normalizedMode == localRecordModeFree ? 1 : setIndex.clamp(1, 99),
              weight: Value(normalizedMode == localRecordModeFree ? 0 : weight),
              reps: Value(normalizedMode == localRecordModeFree ? 0 : reps.clamp(0, 999)),
              durationSeconds: Value(durationSeconds.clamp(0, 24 * 60 * 60)),
              note: Value(actionNote.trim()),
              recordMode: Value(normalizedMode),
              syncStatus: const Value(localSyncPending),
              createdAt: endedAt,
            ),
          );
    });
    await _syncQueue.enqueue('workout_session', sessionId, 'update');
    await _syncQueue.enqueue('workout_log', logId, 'create');
    return logId;
  }

  Future<LocalTrainingStats> getStats({
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions = await (database.select(
      database.localWorkoutSessions,
    )..where((session) => session.startedAt.isBetweenValues(from, to))).get();
    final logs = await (database.select(
      database.localWorkoutLogs,
    )..where((log) => log.createdAt.isBetweenValues(from, to))).get();

    final standardLogs = logs
        .where((log) => normalizeLocalRecordMode(log.recordMode) != localRecordModeFree)
        .toList();
    final volume = standardLogs.fold<num>(0, (sum, log) => sum + log.weight * log.reps);
    final duration = sessions.fold<Duration>(Duration.zero, (sum, session) {
      final ended = session.endedAt;
      if (ended == null) {
        return sum;
      }
      return sum + ended.difference(session.startedAt);
    });

    return LocalTrainingStats(
      sessionCount: sessions.length,
      setCount: standardLogs.length,
      totalVolume: volume,
      duration: duration,
      freeRecordCount: logs.length - standardLogs.length,
    );
  }

  Future<Map<DateTime, LocalTrainingDailyRecord>> getDailyRecordsForMonth(
    DateTime month,
  ) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    final sessions =
        await (database.select(database.localWorkoutSessions)
              ..where((session) => session.startedAt.isBetweenValues(from, to))
              ..orderBy([(session) => OrderingTerm.asc(session.startedAt)]))
            .get();

    final records = <DateTime, _DailyRecordAccumulator>{};
    for (final session in sessions) {
      final logs = await (database.select(
        database.localWorkoutLogs,
      )..where((log) => log.sessionId.equals(session.id))).get();
      if (logs.isEmpty && session.endedAt != null) {
        continue;
      }
      final dayKey = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      final accumulator = records.putIfAbsent(
        dayKey,
        () => _DailyRecordAccumulator(dayKey),
      );
      accumulator.sessionCount += 1;
      final standardLogs = logs
          .where((log) => normalizeLocalRecordMode(log.recordMode) != localRecordModeFree)
          .toList();
      accumulator.setCount += standardLogs.length;
      accumulator.freeRecordCount += logs.length - standardLogs.length;
      accumulator.totalVolume += standardLogs.fold<num>(
        0,
        (sum, log) => sum + log.weight * log.reps,
      );
      final ended = session.endedAt;
      if (ended != null) {
        accumulator.duration += ended.difference(session.startedAt);
      }
      final note = session.note.trim();
      if (note.isNotEmpty) {
        accumulator.notes.add(note);
      }
      if (note.contains('未完成训练计划')) {
        accumulator.incomplete = true;
      }
    }

    return records.map((date, record) => MapEntry(date, record.toRecord()));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<Map<String, LocalTrainingDayModel>> _loadDays(int routineId) async {
    final rows =
        await (database.select(database.localTrainingDays)
              ..where((day) => day.routineId.equals(routineId))
              ..orderBy([
                (day) => OrderingTerm.asc(day.week),
                (day) => OrderingTerm.asc(day.day),
              ]))
            .get();

    final result = <String, LocalTrainingDayModel>{};
    for (final row in rows) {
      final actions = (jsonDecode(row.actionsJson) as List<dynamic>)
          .map(LocalTrainingActionModel.fromJson)
          .toList();
      await _hydrateActionTargetsFromSlots(row.id, actions);
      result['${row.week}-${row.day}'] = LocalTrainingDayModel(
        id: row.id,
        syncId: row.syncId,
        week: row.week,
        day: row.day,
        name: row.name,
        actions: actions,
      );
    }
    return result;
  }

  Future<void> _hydrateActionTargetsFromSlots(
    int dayId,
    List<LocalTrainingActionModel> actions,
  ) async {
    if (actions.isEmpty) {
      return;
    }

    final slots =
        await (database.select(database.localSlots)
              ..where((slot) => slot.dayId.equals(dayId))
              ..orderBy([(slot) => OrderingTerm.asc(slot.order)]))
            .get();

    for (final slot in slots) {
      if (slot.order < 0 || slot.order >= actions.length) {
        continue;
      }
      final entry = await (database.select(
        database.localSlotEntries,
      )..where((entry) => entry.slotId.equals(slot.id))).getSingleOrNull();
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
      );
    }
  }

  Future<void> _replacePlanChildren(int routineId) async {
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.routineId.equals(routineId))).get();
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
    }
    await (database.delete(
      database.localTrainingDays,
    )..where((day) => day.routineId.equals(routineId))).go();
  }
}

class _DailyRecordAccumulator {
  final DateTime date;
  var sessionCount = 0;
  var setCount = 0;
  num totalVolume = 0;
  var duration = Duration.zero;
  var incomplete = false;
  var freeRecordCount = 0;
  final notes = <String>[];

  _DailyRecordAccumulator(this.date);

  LocalTrainingDailyRecord toRecord() {
    return LocalTrainingDailyRecord(
      date: date,
      name: incomplete ? '未完成训练' : '训练记录',
      sessionCount: sessionCount,
      setCount: setCount,
      totalVolume: totalVolume,
      duration: duration,
      freeRecordCount: freeRecordCount,
      note: notes.isEmpty ? '当天训练已保存到本地数据库。' : notes.join('\n'),
      incomplete: incomplete,
    );
  }
}

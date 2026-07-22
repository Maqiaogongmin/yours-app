part of '../local_training_repository.dart';

mixin _WorkoutSessionWriteMixin {
  LocalTrainingDatabase get database;
  LocalSyncQueueRepository get _syncQueue;
  Future<LocalWorkoutLog?> _repairSingleFreeLogDuration({
    required LocalWorkoutSession session,
    required LocalWorkoutLog log,
    required DateTime endedAt,
  });

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
            routineNameSnapshot: Value(plan.name.trim()),
            routineSyncIdSnapshot: Value(plan.syncId?.trim() ?? ''),
            dayNameSnapshot: Value(day?.name.trim() ?? ''),
            dayWeekSnapshot: Value(day?.week),
            dayIndexSnapshot: Value(day?.day),
            daySyncIdSnapshot: Value(day?.syncId?.trim() ?? ''),
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
    final session = await (database.select(
      database.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingleOrNull();
    final logs = await (database.select(
      database.localWorkoutLogs,
    )..where((row) => row.sessionId.equals(sessionId))).get();
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
    if (session != null && logs.length == 1) {
      await _repairSingleFreeLogDuration(session: session, log: logs.single, endedAt: now);
    }
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
    final logsBySessionId = _groupWorkoutLogsBySession(
      await _loadWorkoutLogsForSessionIds(
        database,
        sessions.map((session) => session.id),
      ),
    );
    final draftsBySessionId = await _loadWorkoutDraftsForSessionIds(
      database,
      sessions.map((session) => session.id),
    );
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
      final drafts = draftsBySessionId[session.id] ?? <LocalWorkoutInputDraft>[];
      if (logs.isEmpty && drafts.isEmpty) {
        continue;
      }
      return LocalWorkoutSessionResumeModel(
        sessionId: session.id,
        startedAt: session.startedAt,
        logs: logs.map(_toWorkoutLogEditModel).toList(),
        drafts: drafts,
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
    double? actualWeight,
    int? actualReps,
    int? actualDurationSeconds,
    int? restSeconds,
    bool hasActualValues = false,
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
            actualWeight: Value(actualWeight),
            actualReps: Value(actualReps),
            actualDurationSeconds: Value(actualDurationSeconds),
            restSeconds: Value(restSeconds),
            hasActualValues: Value(hasActualValues),
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
        database.localWorkoutSetDrafts,
      )..where((draft) => draft.sessionId.equals(sessionId))).go();
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
}

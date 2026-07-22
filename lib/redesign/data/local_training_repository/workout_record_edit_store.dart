part of '../local_training_repository.dart';

mixin _WorkoutEditMixin {
  LocalTrainingDatabase get database;
  LocalSyncQueueRepository get _syncQueue;
  Future<void> updateWorkoutLog({
    required int logId,
    required int setIndex,
    required double weight,
    required int reps,
    required String note,
    required int durationSeconds,
    double? actualWeight,
    int? actualReps,
    int? actualDurationSeconds,
    int? restSeconds,
    bool hasActualValues = false,
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
        actualWeight: Value(actualWeight),
        actualReps: Value(actualReps),
        actualDurationSeconds: Value(actualDurationSeconds),
        restSeconds: Value(restSeconds),
        hasActualValues: Value(hasActualValues),
        syncStatus: const Value(localSyncPending),
      ),
    );
    await _syncQueue.enqueue('workout_log', logId, 'update');
  }

  Future<void> saveWorkoutInputDraft({
    required int sessionId,
    required LocalWorkoutInputDraft draft,
  }) async {
    final existing =
        await (database.select(database.localWorkoutSetDrafts)..where(
              (row) =>
                  row.sessionId.equals(sessionId) &
                  row.actionIndex.equals(draft.actionIndex) &
                  row.setIndex.equals(draft.setIndex),
            ))
            .getSingleOrNull();
    final companion = LocalWorkoutSetDraftsCompanion(
      sessionId: Value(sessionId),
      actionIndex: Value(draft.actionIndex),
      setIndex: Value(draft.setIndex),
      weightText: Value(draft.weightText),
      repsText: Value(draft.repsText),
      durationText: Value(draft.durationText),
      restText: Value(draft.restText),
      noteText: Value(draft.noteText),
      updatedAt: Value(DateTime.now()),
    );
    if (existing == null) {
      await database.into(database.localWorkoutSetDrafts).insert(companion);
    } else {
      await (database.update(
        database.localWorkoutSetDrafts,
      )..where((row) => row.id.equals(existing.id))).write(companion);
    }
  }

  Future<void> deleteWorkoutInputDraft({
    required int sessionId,
    required int actionIndex,
    required int setIndex,
  }) {
    return (database.delete(database.localWorkoutSetDrafts)..where(
          (row) =>
              row.sessionId.equals(sessionId) &
              row.actionIndex.equals(actionIndex) &
              row.setIndex.equals(setIndex),
        ))
        .go();
  }

  Future<void> deleteWorkoutInputDraftsForSession(int sessionId) {
    return (database.delete(
      database.localWorkoutSetDrafts,
    )..where((row) => row.sessionId.equals(sessionId))).go();
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
}

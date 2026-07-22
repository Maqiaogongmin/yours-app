part of '../server_sync_event_applier.dart';

extension _WorkoutLogServerSyncEventApplier on ServerSyncEventApplier {
  Future<bool> _applyRemoteWorkoutLogEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    final db = locator<LocalTrainingDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final logId = await _localLogIdBySyncId(db, syncId);
    if (action == 'delete') {
      await _recordDeleteTombstone(
        entityType: 'workout_log',
        entitySyncId: 'workout_log:$syncId',
        entityId: logId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (logId == null) {
        return true;
      }
      await (db.delete(db.localWorkoutLogs)..where((row) => row.id.equals(logId))).go();
      return true;
    }
    if (snapshot == null) {
      return true;
    }
    final remoteUpdatedAt =
        _date(snapshot['updatedAt']) ?? _date(snapshot['createdAt']) ?? DateTime.now();
    if (await _deleteTombstoneIsNotOlder('workout_log:$syncId', remoteUpdatedAt)) {
      return true;
    }
    return _upsertRemoteWorkoutLog(db, snapshot);
  }

  Future<bool> _upsertRemoteWorkoutLog(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
  ) async {
    final syncId = _asString(snapshot['syncId']);
    if (syncId.isEmpty) {
      return true;
    }
    final logId = await _localLogIdBySyncId(db, syncId);
    final createdAt = _date(snapshot['createdAt']);
    if (createdAt == null) {
      return true;
    }
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? createdAt;
    if (logId == null && await _hasDuplicateLocalWorkoutLog(db, snapshot, createdAt)) {
      return true;
    }
    final routineId = await _ensureHistoryRoutine(
      db,
      _asString(snapshot['routineSyncId']),
      remoteUpdatedAt,
    );
    if (routineId == null) {
      return true;
    }
    final sessionId = await _ensureHistorySession(
      db,
      _asString(snapshot['sessionSyncId']),
      routineId: routineId,
      startedAt: createdAt,
      updatedAt: remoteUpdatedAt,
    );
    if (sessionId == null) {
      return true;
    }
    final dayId = await _localTrainingDayIdBySyncId(db, _asString(snapshot['daySyncId']));
    if (await _deleteTombstoneIsNotOlder('workout_log:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (logId == null) {
      await db
          .into(db.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              syncId: Value(syncId),
              remoteId: Value(_asInt(snapshot['remoteId'])),
              sessionId: sessionId,
              routineId: routineId,
              dayId: Value(dayId),
              exerciseName: canonicalExerciseReference(
                _asString(snapshot['exerciseName'], fallback: '同步动作'),
              ),
              setIndex: _asInt(snapshot['setIndex']) ?? 1,
              weight: Value(_asDouble(snapshot['weight']) ?? 0),
              reps: Value(_asInt(snapshot['reps']) ?? 0),
              rir: Value(_asDouble(snapshot['rir'])),
              durationSeconds: Value(_asInt(snapshot['durationSeconds']) ?? 0),
              actualWeight: Value(_asDouble(snapshot['actualWeight'])),
              actualReps: Value(_asInt(snapshot['actualReps'])),
              actualDurationSeconds: Value(_asInt(snapshot['actualDurationSeconds'])),
              restSeconds: Value(_asInt(snapshot['restSeconds'])),
              hasActualValues: Value(snapshot['hasActualValues'] == true),
              recordMode: Value(normalizeLocalRecordMode(snapshot['recordMode'])),
              note: Value(_asString(snapshot['note'])),
              syncStatus: const Value(localSyncSynced),
              createdAt: createdAt,
            ),
          );
      return true;
    }
    await (db.update(db.localWorkoutLogs)..where((row) => row.id.equals(logId))).write(
      LocalWorkoutLogsCompanion(
        syncId: Value(syncId),
        remoteId: Value(_asInt(snapshot['remoteId'])),
        sessionId: Value(sessionId),
        routineId: Value(routineId),
        dayId: Value(dayId),
        exerciseName: Value(
          canonicalExerciseReference(
            _asString(snapshot['exerciseName'], fallback: '同步动作'),
          ),
        ),
        setIndex: Value(_asInt(snapshot['setIndex']) ?? 1),
        weight: Value(_asDouble(snapshot['weight']) ?? 0),
        reps: Value(_asInt(snapshot['reps']) ?? 0),
        rir: Value(_asDouble(snapshot['rir'])),
        durationSeconds: Value(_asInt(snapshot['durationSeconds']) ?? 0),
        actualWeight: Value(_asDouble(snapshot['actualWeight'])),
        actualReps: Value(_asInt(snapshot['actualReps'])),
        actualDurationSeconds: Value(_asInt(snapshot['actualDurationSeconds'])),
        restSeconds: Value(_asInt(snapshot['restSeconds'])),
        hasActualValues: Value(snapshot['hasActualValues'] == true),
        recordMode: Value(normalizeLocalRecordMode(snapshot['recordMode'])),
        note: Value(_asString(snapshot['note'])),
        syncStatus: const Value(localSyncSynced),
        createdAt: Value(createdAt),
      ),
    );
    return true;
  }

  Future<bool> _hasDuplicateLocalWorkoutLog(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
    DateTime createdAt, {
    int? sessionId,
  }) async {
    final query = db.select(db.localWorkoutLogs)
      ..where(
        (row) =>
            row.createdAt.equals(createdAt) &
            row.exerciseName.equals(
              canonicalExerciseReference(
                _asString(snapshot['exerciseName'], fallback: '同步动作'),
              ),
            ) &
            row.setIndex.equals(_asInt(snapshot['setIndex']) ?? 1) &
            row.weight.equals(_asDouble(snapshot['weight']) ?? 0) &
            row.reps.equals(_asInt(snapshot['reps']) ?? 0) &
            (_asDouble(snapshot['rir']) == null
                ? row.rir.isNull()
                : row.rir.equals(_asDouble(snapshot['rir'])!)) &
            row.durationSeconds.equals(_asInt(snapshot['durationSeconds']) ?? 0) &
            row.recordMode.equals(normalizeLocalRecordMode(snapshot['recordMode'])) &
            row.note.equals(_asString(snapshot['note'])),
      );
    if (sessionId != null) {
      query.where((row) => row.sessionId.equals(sessionId));
    }
    query.limit(1);
    return await query.getSingleOrNull() != null;
  }
}

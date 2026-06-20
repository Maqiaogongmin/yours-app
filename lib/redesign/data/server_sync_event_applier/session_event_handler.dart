part of '../server_sync_event_applier.dart';

extension _SessionServerSyncEventApplier on ServerSyncEventApplier {
  Future<bool> _applyRemoteSessionEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    final db = locator<LocalTrainingDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final sessionId = await _localSessionIdBySyncId(db, syncId);
    if (action == 'delete') {
      await _recordDeleteTombstone(
        entityType: 'workout_session',
        entitySyncId: 'workout_session:$syncId',
        entityId: sessionId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (sessionId == null) {
        return true;
      }
      await db.transaction(() async {
        await (db.delete(
          db.localWorkoutLogs,
        )..where((row) => row.sessionId.equals(sessionId))).go();
        await (db.delete(
          db.localWorkoutSessions,
        )..where((row) => row.id.equals(sessionId))).go();
      });
      return true;
    }
    if (snapshot == null) {
      return true;
    }
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? DateTime.now();
    final dayId = await _localTrainingDayIdBySyncId(db, _asString(snapshot['daySyncId']));
    final startedAt = _date(snapshot['startedAt']);
    if (startedAt == null) {
      return true;
    }
    if (sessionId == null && await _hasDuplicateLocalSession(db, snapshot, startedAt)) {
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
    if (!await _localRoutineExists(db, routineId)) {
      return true;
    }
    if (await _deleteTombstoneIsNotOlder('workout_session:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (sessionId != null && await _localSessionIsNewer(db, sessionId, remoteUpdatedAt)) {
      return true;
    }
    await db.transaction(() async {
      final localSessionId =
          sessionId ??
          await db
              .into(db.localWorkoutSessions)
              .insert(
                LocalWorkoutSessionsCompanion.insert(
                  syncId: Value(syncId),
                  remoteId: Value(_asInt(snapshot['remoteId'])),
                  routineId: routineId,
                  dayId: Value(dayId),
                  startedAt: startedAt,
                  endedAt: Value(_date(snapshot['endedAt'])),
                  note: Value(_asString(snapshot['note'])),
                  syncStatus: const Value(localSyncSynced),
                  updatedAt: remoteUpdatedAt,
                ),
              );
      if (sessionId != null) {
        await (db.update(
          db.localWorkoutSessions,
        )..where((row) => row.id.equals(localSessionId))).write(
          LocalWorkoutSessionsCompanion(
            syncId: Value(syncId),
            remoteId: Value(_asInt(snapshot['remoteId'])),
            routineId: Value(routineId),
            dayId: Value(dayId),
            startedAt: Value(startedAt),
            endedAt: Value(_date(snapshot['endedAt'])),
            note: Value(_asString(snapshot['note'])),
            syncStatus: const Value(localSyncSynced),
            updatedAt: Value(remoteUpdatedAt),
          ),
        );
      }
      final logsValue = snapshot['logs'];
      if (logsValue is! List) {
        return;
      }
      final remoteLogSyncIds = <String>{};
      for (final item in logsValue) {
        final log = _asMap(item);
        final logSyncId = _asString(log?['syncId']);
        if (log == null || logSyncId.isEmpty) {
          continue;
        }
        remoteLogSyncIds.add(logSyncId);
        await _upsertRemoteWorkoutLog(db, log);
      }
      final localLogs = await (db.select(
        db.localWorkoutLogs,
      )..where((row) => row.sessionId.equals(localSessionId))).get();
      for (final log in localLogs) {
        if (!remoteLogSyncIds.contains(log.syncId)) {
          await (db.delete(db.localWorkoutLogs)..where((row) => row.id.equals(log.id))).go();
        }
      }
    });
    return true;
  }

  Future<bool> _hasDuplicateLocalSession(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
    DateTime startedAt,
  ) async {
    final endedAt = _date(snapshot['endedAt']);
    final note = _asString(snapshot['note']);
    final candidates =
        await (db.select(db.localWorkoutSessions)..where(
              (row) =>
                  row.startedAt.equals(startedAt) &
                  (endedAt == null ? row.endedAt.isNull() : row.endedAt.equals(endedAt)) &
                  row.note.equals(note),
            ))
            .get();
    if (candidates.isEmpty) {
      return false;
    }
    final logs = _asList(snapshot['logs']).whereType<Map>().toList();
    if (logs.isEmpty) {
      return true;
    }
    for (final candidate in candidates) {
      var allLogsAlreadyExist = true;
      for (final log in logs) {
        final createdAt = _date(log['createdAt']);
        if (createdAt == null ||
            !await _hasDuplicateLocalWorkoutLog(
              db,
              Map<String, dynamic>.from(log),
              createdAt,
              sessionId: candidate.id,
            )) {
          allLogsAlreadyExist = false;
          break;
        }
      }
      if (allLogsAlreadyExist) {
        return true;
      }
    }
    return false;
  }
}

part of '../local_training_repository.dart';

class _LocalWorkoutRecordStore {
  _LocalWorkoutRecordStore(this.database, this._syncQueue);

  final LocalTrainingDatabase database;
  final LocalSyncQueueRepository _syncQueue;

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
    final logsBySessionId = _groupWorkoutLogsBySession(
      await _loadWorkoutLogsForSessionIds(
        database,
        sessions.map((session) => session.id),
      ),
    );
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
      if (logs.isEmpty) {
        continue;
      }
      return LocalWorkoutSessionResumeModel(
        sessionId: session.id,
        startedAt: session.startedAt,
        logs: logs.map(_toWorkoutLogEditModel).toList(),
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
    final logsBySessionId = _groupWorkoutLogsBySession(
      await _loadWorkoutLogsForSessionIds(
        database,
        sessions.map((session) => session.id),
      ),
    );
    final dayIds = <int>{...sessions.map((session) => session.dayId).whereType<int>()};
    final sessionDayIdsBySessionId = <int, int>{};
    for (final MapEntry(key: sessionId, value: logs) in logsBySessionId.entries) {
      for (final log in logs) {
        final dayId = log.dayId;
        if (dayId != null) {
          dayIds.add(dayId);
          sessionDayIdsBySessionId.putIfAbsent(sessionId, () => dayId);
        }
      }
    }
    final dayNamesById = await _loadTrainingDayNames(dayIds);
    final scheduleNamesBySessionId = await _resolveScheduleDayNamesBySessionId(
      sessions,
      dayNamesById,
    );
    final result = <LocalWorkoutSessionEditModel>[];
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
      if (logs.isEmpty && session.endedAt != null) {
        continue;
      }
      final dayId = session.dayId ?? sessionDayIdsBySessionId[session.id];
      final dayName = dayId == null ? '' : dayNamesById[dayId] ?? '';
      result.add(
        LocalWorkoutSessionEditModel(
          id: session.id,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          dayId: dayId,
          dayName: dayName.isEmpty ? scheduleNamesBySessionId[session.id] ?? '' : dayName,
          note: session.note,
          logs: _toWorkoutLogEditModelsWithDisplayIndexes(logs),
        ),
      );
    }
    return result;
  }

  Future<Map<int, String>> _loadTrainingDayNames(Iterable<int> dayIds) async {
    final ids = dayIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.id.isIn(ids))).get();
    return {for (final day in days) day.id: day.name};
  }

  Future<Map<int, String>> _resolveScheduleDayNamesBySessionId(
    List<LocalWorkoutSession> sessions,
    Map<int, String> directDayNamesById,
  ) async {
    final unresolved = sessions
        .where(
          (session) =>
              session.dayId != null && (directDayNamesById[session.dayId]?.trim().isEmpty ?? true),
        )
        .toList();
    if (unresolved.isEmpty) {
      return const {};
    }
    final routineIds = unresolved.map((session) => session.routineId).toSet().toList();
    final anchors = await _loadScheduleAnchors(routineIds);
    if (anchors.isEmpty) {
      return const {};
    }
    final routines = await (database.select(
      database.localRoutines,
    )..where((routine) => routine.id.isIn(routineIds))).get();
    final routinesById = {for (final routine in routines) routine.id: routine};
    final scheduleNamesByRoutine = await _loadScheduleNamesByRoutine(routineIds);
    final resolved = <int, String>{};
    for (final session in unresolved) {
      final routine = routinesById[session.routineId];
      final routineAnchors = anchors[session.routineId];
      if (routine == null || routineAnchors == null || routineAnchors.isEmpty) {
        continue;
      }
      final anchor = _closestScheduleAnchor(session.startedAt, routineAnchors);
      if (anchor == null) {
        continue;
      }
      final daysPerWeek = routine.daysPerWeek;
      final totalDays = routine.totalWeeks * daysPerWeek;
      if (daysPerWeek <= 0 || totalDays <= 0) {
        continue;
      }
      final targetIndex =
          (anchor.week - 1) * daysPerWeek +
          (anchor.day - 1) +
          _dateOnly(session.startedAt).difference(_dateOnly(anchor.startedAt)).inDays;
      if (targetIndex < 0 || targetIndex >= totalDays) {
        continue;
      }
      final targetWeek = targetIndex ~/ daysPerWeek + 1;
      final targetDay = targetIndex % daysPerWeek + 1;
      final name =
          scheduleNamesByRoutine[session.routineId]?[_scheduleDayKey(targetWeek, targetDay)]
              ?.trim() ??
          '';
      if (name.isNotEmpty) {
        resolved[session.id] = name;
      }
    }
    return resolved;
  }

  Future<Map<int, List<_ScheduleAnchor>>> _loadScheduleAnchors(
    Iterable<int> routineIds,
  ) async {
    final ids = routineIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final anchorSessions =
        await (database.select(database.localWorkoutSessions)
              ..where(
                (session) => session.routineId.isIn(ids) & session.dayId.isNotNull(),
              )
              ..orderBy([(session) => OrderingTerm.asc(session.startedAt)]))
            .get();
    final anchorDayIds = anchorSessions
        .map((session) => session.dayId)
        .whereType<int>()
        .toSet()
        .toList();
    if (anchorDayIds.isEmpty) {
      return const {};
    }
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.id.isIn(anchorDayIds))).get();
    final daysById = {for (final day in days) day.id: day};
    final anchors = <int, List<_ScheduleAnchor>>{};
    for (final session in anchorSessions) {
      final dayId = session.dayId;
      if (dayId == null) {
        continue;
      }
      final day = daysById[dayId];
      if (day == null) {
        continue;
      }
      anchors
          .putIfAbsent(session.routineId, () => [])
          .add(
            _ScheduleAnchor(
              startedAt: session.startedAt,
              week: day.week,
              day: day.day,
            ),
          );
    }
    return anchors;
  }

  Future<Map<int, Map<String, String>>> _loadScheduleNamesByRoutine(
    Iterable<int> routineIds,
  ) async {
    final ids = routineIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.routineId.isIn(ids))).get();
    final result = <int, Map<String, String>>{};
    for (final day in days) {
      result.putIfAbsent(day.routineId, () => {})[_scheduleDayKey(day.week, day.day)] = day.name;
    }
    return result;
  }

  _ScheduleAnchor? _closestScheduleAnchor(
    DateTime target,
    List<_ScheduleAnchor> anchors,
  ) {
    _ScheduleAnchor? closest;
    var closestDistance = 1 << 62;
    for (final anchor in anchors) {
      final distance = _dateOnly(target).difference(_dateOnly(anchor.startedAt)).inDays.abs();
      if (distance < closestDistance) {
        closest = anchor;
        closestDistance = distance;
      }
    }
    return closest;
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
}

class _ScheduleAnchor {
  final DateTime startedAt;
  final int week;
  final int day;

  const _ScheduleAnchor({
    required this.startedAt,
    required this.week,
    required this.day,
  });
}

String _scheduleDayKey(int week, int day) => '$week-$day';

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

Future<List<LocalWorkoutLog>> _loadWorkoutLogsForSessionIds(
  LocalTrainingDatabase database,
  Iterable<int> sessionIds,
) async {
  final ids = sessionIds.toSet().toList();
  if (ids.isEmpty) {
    return <LocalWorkoutLog>[];
  }
  return (database.select(database.localWorkoutLogs)
        ..where((log) => log.sessionId.isIn(ids))
        ..orderBy([
          (log) => OrderingTerm.asc(log.sessionId),
          (log) => OrderingTerm.asc(log.createdAt),
          (log) => OrderingTerm.asc(log.id),
          (log) => OrderingTerm.asc(log.setIndex),
        ]))
      .get();
}

Map<int, List<LocalWorkoutLog>> _groupWorkoutLogsBySession(
  Iterable<LocalWorkoutLog> logs,
) {
  final result = <int, List<LocalWorkoutLog>>{};
  for (final log in logs) {
    result.putIfAbsent(log.sessionId, () => <LocalWorkoutLog>[]).add(log);
  }
  return result;
}

LocalWorkoutLogEditModel _toWorkoutLogEditModel(
  LocalWorkoutLog log, {
  int? displaySetIndex,
}) {
  return LocalWorkoutLogEditModel(
    id: log.id,
    sessionId: log.sessionId,
    exerciseName: log.exerciseName,
    setIndex: displaySetIndex ?? log.setIndex,
    weight: log.weight,
    reps: log.reps,
    note: log.note,
    recordMode: normalizeLocalRecordMode(log.recordMode),
    durationSeconds: log.durationSeconds,
    createdAt: log.createdAt,
  );
}

List<LocalWorkoutLogEditModel> _toWorkoutLogEditModelsWithDisplayIndexes(
  Iterable<LocalWorkoutLog> logs,
) {
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
    return _toWorkoutLogEditModel(log, displaySetIndex: displaySetIndex);
  }).toList();
}

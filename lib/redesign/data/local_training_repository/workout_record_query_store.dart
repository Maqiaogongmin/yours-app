part of '../local_training_repository.dart';

mixin _WorkoutQueryMixin {
  LocalTrainingDatabase get database;
  LocalSyncQueueRepository get _syncQueue;
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
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
      if (logs.length != 1 || session.endedAt == null) {
        continue;
      }
      final repaired = await _repairSingleFreeLogDuration(
        session: session,
        log: logs.single,
        endedAt: session.endedAt!,
      );
      if (repaired != null) {
        logsBySessionId[session.id] = [repaired];
      }
    }
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
    final daysById = await _loadTrainingDays(dayIds);
    final result = <LocalWorkoutSessionEditModel>[];
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
      if (logs.isEmpty && session.endedAt != null) {
        continue;
      }
      final dayId = session.dayId ?? sessionDayIdsBySessionId[session.id];
      final directDay = dayId == null ? null : daysById[dayId];
      final snapshotDayName = session.dayNameSnapshot.trim();
      final snapshotRoutineName = session.routineNameSnapshot.trim();
      result.add(
        LocalWorkoutSessionEditModel(
          id: session.id,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          dayId: dayId,
          routineName: snapshotRoutineName,
          routineSyncId: session.routineSyncIdSnapshot.trim(),
          dayName: snapshotDayName.isNotEmpty ? snapshotDayName : directDay?.name ?? '',
          dayWeek: session.dayWeekSnapshot ?? directDay?.week,
          dayIndex: session.dayIndexSnapshot ?? directDay?.day,
          daySyncId: session.daySyncIdSnapshot.trim().isNotEmpty
              ? session.daySyncIdSnapshot.trim()
              : directDay?.syncId ?? '',
          note: session.note,
          logs: _toWorkoutLogEditModelsWithDisplayIndexes(logs),
        ),
      );
    }
    return result;
  }

  Future<LocalWorkoutLog?> _repairSingleFreeLogDuration({
    required LocalWorkoutSession session,
    required LocalWorkoutLog log,
    required DateTime endedAt,
  }) async {
    if (normalizeLocalRecordMode(log.recordMode) != localRecordModeFree ||
        log.durationSeconds != 0 ||
        endedAt.isBefore(session.startedAt)) {
      return null;
    }
    final durationSeconds = endedAt.difference(session.startedAt).inSeconds.clamp(0, 24 * 60 * 60);
    if (durationSeconds == 0) {
      return null;
    }
    await (database.update(
      database.localWorkoutLogs,
    )..where((row) => row.id.equals(log.id))).write(
      LocalWorkoutLogsCompanion(
        durationSeconds: Value(durationSeconds),
        syncStatus: const Value(localSyncPending),
      ),
    );
    await _syncQueue.enqueue('workout_log', log.id, 'update');
    return log.copyWith(durationSeconds: durationSeconds, syncStatus: localSyncPending);
  }

  Future<Map<int, _TrainingDayReference>> _loadTrainingDays(Iterable<int> dayIds) async {
    final ids = dayIds.toSet().toList();
    if (ids.isEmpty) {
      return const {};
    }
    final days = await (database.select(
      database.localTrainingDays,
    )..where((day) => day.id.isIn(ids))).get();
    return {
      for (final day in days)
        day.id: _TrainingDayReference(
          name: day.name,
          week: day.week,
          day: day.day,
          syncId: day.syncId,
        ),
    };
  }
}

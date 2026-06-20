part of '../local_training_repository.dart';

class _LocalTrainingStatsReader {
  _LocalTrainingStatsReader(this.database);

  final LocalTrainingDatabase database;

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

    final logsBySessionId = _groupWorkoutLogsBySession(
      await _loadWorkoutLogsForSessionIds(
        database,
        sessions.map((session) => session.id),
      ),
    );

    final records = <DateTime, _DailyRecordAccumulator>{};
    for (final session in sessions) {
      final logs = logsBySessionId[session.id] ?? <LocalWorkoutLog>[];
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

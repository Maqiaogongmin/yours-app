part of '../local_training_repository.dart';

class _TrainingDayReference {
  const _TrainingDayReference({
    required this.name,
    required this.week,
    required this.day,
    required this.syncId,
  });

  final String name;
  final int week;
  final int day;
  final String syncId;
}

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

Future<Map<int, List<LocalWorkoutInputDraft>>> _loadWorkoutDraftsForSessionIds(
  LocalTrainingDatabase database,
  Iterable<int> sessionIds,
) async {
  final ids = sessionIds.toSet().toList();
  if (ids.isEmpty) {
    return const {};
  }
  final rows =
      await (database.select(database.localWorkoutSetDrafts)
            ..where((draft) => draft.sessionId.isIn(ids))
            ..orderBy([
              (draft) => OrderingTerm.asc(draft.actionIndex),
              (draft) => OrderingTerm.asc(draft.setIndex),
            ]))
          .get();
  final result = <int, List<LocalWorkoutInputDraft>>{};
  for (final row in rows) {
    result
        .putIfAbsent(row.sessionId, () => <LocalWorkoutInputDraft>[])
        .add(
          LocalWorkoutInputDraft(
            actionIndex: row.actionIndex,
            setIndex: row.setIndex,
            weightText: row.weightText,
            repsText: row.repsText,
            durationText: row.durationText,
            restText: row.restText,
            noteText: row.noteText,
          ),
        );
  }
  return result;
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
    actualWeight: log.actualWeight,
    actualReps: log.actualReps,
    actualDurationSeconds: log.actualDurationSeconds,
    restSeconds: log.restSeconds,
    hasActualValues: log.hasActualValues,
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

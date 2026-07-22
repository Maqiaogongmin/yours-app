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

part 'local_training_repository/training_seed_service.dart';
part 'local_training_repository/training_plan_store.dart';
part 'local_training_repository/workout_record_store.dart';
part 'local_training_repository/workout_session_write_store.dart';
part 'local_training_repository/workout_record_query_store.dart';
part 'local_training_repository/workout_record_edit_store.dart';
part 'local_training_repository/workout_record_helpers.dart';
part 'local_training_repository/training_stats_reader.dart';

class LocalTrainingRepository {
  final LocalTrainingDatabase _initialDatabase;

  LocalTrainingRepository(this._initialDatabase);

  LocalTrainingDatabase get database => locator.isRegistered<LocalTrainingDatabase>()
      ? locator<LocalTrainingDatabase>()
      : _initialDatabase;

  LocalSyncQueueRepository get _syncQueue => LocalSyncQueueRepository(database);

  _LocalTrainingPlanStore get _plans => _LocalTrainingPlanStore(database, _syncQueue);
  _LocalTrainingSeedService get _seed => _LocalTrainingSeedService(database);
  _LocalWorkoutRecordStore get _workouts => _LocalWorkoutRecordStore(database, _syncQueue);
  _LocalTrainingStatsReader get _stats => _LocalTrainingStatsReader(database);

  Stream<List<LocalTrainingPlanModel>> watchPlans({bool? archived}) {
    return _plans.watchPlans(archived: archived);
  }

  Future<List<LocalTrainingPlanModel>> getPlans() async {
    return _plans.getPlans();
  }

  Future<void> ensureSeedData() async {
    await _seed.ensureSeedData();
  }

  Future<int> standardizeExerciseNames() async {
    return _seed.standardizeExerciseNames();
  }

  Future<int> savePlan(LocalTrainingPlanModel plan) async {
    return _plans.savePlan(plan);
  }

  Future<void> deletePlan(int routineId) async {
    await _plans.deletePlan(routineId);
  }

  Future<void> setPlanArchived(int routineId, bool archived) async {
    await _plans.setPlanArchived(routineId, archived);
  }

  Future<Set<int>> toggleCompletedWeek(int routineId, int week) async {
    return _plans.toggleCompletedWeek(routineId, week);
  }

  Future<int> startSession(LocalTrainingPlanModel plan, LocalTrainingDayModel? day) async {
    return _workouts.startSession(plan, day);
  }

  Future<void> finishSession(int sessionId, {String note = ''}) async {
    await _workouts.finishSession(sessionId, note: note);
  }

  Future<LocalWorkoutSessionResumeModel?> findOpenSessionForDay({
    required int routineId,
    int? dayId,
  }) async {
    return _workouts.findOpenSessionForDay(routineId: routineId, dayId: dayId);
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
    return _workouts.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: dayId,
      exerciseName: exerciseName,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      rir: rir,
      durationSeconds: durationSeconds,
      actualWeight: actualWeight,
      actualReps: actualReps,
      actualDurationSeconds: actualDurationSeconds,
      restSeconds: restSeconds,
      hasActualValues: hasActualValues,
      note: note,
      recordMode: recordMode,
    );
  }

  Future<void> deleteWorkoutLog(int logId) async {
    await _workouts.deleteWorkoutLog(logId);
  }

  Future<void> deleteWorkoutSession(int sessionId) async {
    await _workouts.deleteWorkoutSession(sessionId);
  }

  Future<void> deleteSetLogs({
    required int sessionId,
    required String exerciseName,
    required int setIndex,
  }) async {
    await _workouts.deleteSetLogs(
      sessionId: sessionId,
      exerciseName: exerciseName,
      setIndex: setIndex,
    );
  }

  Future<List<LocalWorkoutLogEditModel>> getLogsForDate(DateTime date) async {
    return _workouts.getLogsForDate(date);
  }

  Future<List<LocalWorkoutSessionEditModel>> getWorkoutSessionsForDate(DateTime date) async {
    return _workouts.getWorkoutSessionsForDate(date);
  }

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
    await _workouts.updateWorkoutLog(
      logId: logId,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      note: note,
      durationSeconds: durationSeconds,
      actualWeight: actualWeight,
      actualReps: actualReps,
      actualDurationSeconds: actualDurationSeconds,
      restSeconds: restSeconds,
      hasActualValues: hasActualValues,
    );
  }

  Future<void> saveWorkoutInputDraft({
    required int sessionId,
    required LocalWorkoutInputDraft draft,
  }) => _workouts.saveWorkoutInputDraft(sessionId: sessionId, draft: draft);

  Future<void> deleteWorkoutInputDraft({
    required int sessionId,
    required int actionIndex,
    required int setIndex,
  }) => _workouts.deleteWorkoutInputDraft(
    sessionId: sessionId,
    actionIndex: actionIndex,
    setIndex: setIndex,
  );

  Future<void> deleteWorkoutInputDraftsForSession(int sessionId) =>
      _workouts.deleteWorkoutInputDraftsForSession(sessionId);

  Future<void> updateWorkoutSession({
    required int sessionId,
    required DateTime startedAt,
    required DateTime? endedAt,
    required String note,
  }) async {
    await _workouts.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      note: note,
    );
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
    return _workouts.completeEmptyWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      sessionNote: sessionNote,
      exerciseName: exerciseName,
      recordMode: recordMode,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      actionNote: actionNote,
    );
  }

  Future<LocalTrainingStats> getStats({required DateTime from, required DateTime to}) async {
    return _stats.getStats(from: from, to: to);
  }

  Future<Map<DateTime, LocalTrainingDailyRecord>> getDailyRecordsForMonth(DateTime month) async {
    return _stats.getDailyRecordsForMonth(month);
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

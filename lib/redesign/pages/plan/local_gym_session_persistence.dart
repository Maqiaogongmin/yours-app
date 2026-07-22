part of 'local_gym_session_controller.dart';

mixin _LocalGymSessionPersistence on ChangeNotifier, _LocalGymSessionState {
  Future<void> saveSet({
    required double? weight,
    required int? reps,
    required int? restSeconds,
  }) async {
    final sessionId = _sessionId;
    final routineId = _plan?.id;
    if (sessionId == null || routineId == null || _actions.isEmpty || _saving || _finished) {
      return;
    }

    _saving = true;
    notifyListeners();

    // Delete any existing log for this session + exercise + set
    // at the database level, so correcting a saved set always overwrites.
    await _repository.deleteSetLogs(
      sessionId: sessionId,
      exerciseName: currentExercise,
      setIndex: _setIndex,
    );
    // Also purge matching snapshots from in-memory history.
    _history.removeWhere(
      (s) => s.exerciseIndex == _exerciseIndex && s.setIndex == _setIndex,
    );

    final logId = await _repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: _day?.id,
      exerciseName: currentExercise,
      setIndex: _setIndex,
      weight: weight ?? 0,
      reps: reps ?? 0,
      rir: null,
      durationSeconds: 0,
      actualWeight: weight,
      actualReps: reps,
      actualDurationSeconds: null,
      restSeconds: restSeconds,
      hasActualValues: true,
      note: currentSetNote,
      recordMode: localRecordModeStandard,
    );

    _history.add(
      _CompletedSetSnapshot(
        exerciseIndex: _exerciseIndex,
        setIndex: _setIndex,
        logId: logId,
        weight: weight,
        reps: reps,
        restSeconds: restSeconds,
        recordMode: localRecordModeStandard,
        durationSeconds: null,
      ),
    );
    await _clearCurrentInputDraft();
    _saving = false;
    final isLastSet = _setIndex >= currentTargetSets;
    final isLastExercise = _exerciseIndex >= _actions.length - 1;
    if (isLastSet && isLastExercise) {
      _finishWorkoutState();
      return;
    }

    final safeRest = restSeconds?.clamp(0, 3600);
    if (safeRest == null || safeRest == 0) {
      advanceAfterRest();
    } else {
      _startRest(safeRest);
    }
  }

  Future<void> completeFreeRecord({
    required double? weight,
    required int? durationSeconds,
    required int? restSeconds,
  }) async {
    final sessionId = _sessionId;
    final routineId = _plan?.id;
    if (sessionId == null || routineId == null || _actions.isEmpty || _saving || _finished) {
      return;
    }
    if (!isCurrentFreeRecord) {
      return;
    }

    _saving = true;
    notifyListeners();

    final safeDurationSeconds = durationSeconds?.clamp(0, 24 * 60 * 60);
    final safeRestSeconds = restSeconds?.clamp(0, 3600);

    await _repository.deleteSetLogs(
      sessionId: sessionId,
      exerciseName: currentExercise,
      setIndex: _setIndex,
    );
    _history.removeWhere(
      (s) => s.exerciseIndex == _exerciseIndex && s.setIndex == _setIndex,
    );

    final logId = await _repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: _day?.id,
      exerciseName: currentExercise,
      setIndex: _setIndex,
      weight: weight ?? 0,
      reps: 0,
      rir: null,
      durationSeconds: safeDurationSeconds ?? 0,
      actualWeight: weight,
      actualReps: null,
      actualDurationSeconds: safeDurationSeconds,
      restSeconds: safeRestSeconds,
      hasActualValues: true,
      note: currentSetNote,
      recordMode: localRecordModeFree,
    );

    _history.add(
      _CompletedSetSnapshot(
        exerciseIndex: _exerciseIndex,
        setIndex: _setIndex,
        logId: logId,
        weight: weight,
        reps: 0,
        restSeconds: safeRestSeconds,
        recordMode: localRecordModeFree,
        durationSeconds: safeDurationSeconds,
      ),
    );
    await _clearCurrentInputDraft();
    _saving = false;
    final isLastSet = _setIndex >= currentTargetSets;
    final isLastExercise = _exerciseIndex >= _actions.length - 1;
    if (isLastSet && isLastExercise) {
      _finishWorkoutState();
      return;
    }

    if (safeRestSeconds == null || safeRestSeconds == 0) {
      advanceAfterRest();
    } else {
      _startRest(safeRestSeconds);
    }
  }
}

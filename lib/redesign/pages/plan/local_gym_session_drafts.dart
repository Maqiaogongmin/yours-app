part of 'local_gym_session_controller.dart';

mixin _LocalGymSessionDrafts on ChangeNotifier, _LocalGymSessionState {
  Future<void> updateCurrentInputDraft({
    String? weightText,
    String? repsText,
    String? durationText,
    String? restText,
    String? noteText,
    bool markNoteEdited = false,
  }) {
    if (_actions.isEmpty || _finished) {
      return Future.value();
    }
    final previous = _inputDrafts[_currentSetKey];
    final previousNote = previous?.noteText ?? _setNoteDrafts[_currentSetKey] ?? '';
    final previousNoteEdited = previous?.noteEdited ?? currentSetNoteEdited;
    final next =
        (previous ??
                LocalWorkoutInputDraft(
                  actionIndex: _exerciseIndex,
                  setIndex: _setIndex,
                  noteText: previousNote,
                  noteEdited: previousNoteEdited,
                ))
            .copyWith(
              weightText: weightText,
              repsText: repsText,
              durationText: durationText,
              restText: restText,
              noteText: noteText,
              noteEdited: previousNoteEdited || markNoteEdited,
            );
    _inputDrafts[_currentSetKey] = next;
    _setNoteDrafts[_currentSetKey] = next.noteText;
    _setNoteEdited[_currentSetKey] = next.noteEdited;
    final snapshotIndex = _currentSetSnapshotIndex;
    final savedLogId = snapshotIndex == -1 ? null : _history[snapshotIndex].logId;
    final noteChanged =
        previousNoteEdited != next.noteEdited || (next.noteEdited && previousNote != next.noteText);
    final sessionId = _sessionId;
    if (sessionId == null) {
      return Future.value();
    }
    _draftWriteQueue = _draftWriteQueue.then((_) async {
      await _repository.saveWorkoutInputDraft(sessionId: sessionId, draft: next);
      if (savedLogId != null && noteChanged) {
        await _repository.updateWorkoutLogNote(
          logId: savedLogId,
          note: next.noteEdited ? next.noteText : '',
          noteEdited: next.noteEdited,
        );
      }
    });
    return _draftWriteQueue;
  }

  @override
  Future<void> flushInputDrafts() => _draftWriteQueue;

  @override
  Future<void> _clearCurrentInputDraft() async {
    final sessionId = _sessionId;
    _inputDrafts.remove(_currentSetKey);
    if (sessionId != null) {
      await _repository.deleteWorkoutInputDraft(
        sessionId: sessionId,
        actionIndex: _exerciseIndex,
        setIndex: _setIndex,
      );
    }
  }

  /// 返回当前组最后一次保存的实际数据（重量/次数/休息时间）。
  /// 如果该组尚未保存过任何记录，返回 null。
  CompletedSetUndo? getSavedDataForCurrentSet() {
    for (var i = _history.length - 1; i >= 0; i--) {
      final s = _history[i];
      if (s.exerciseIndex == _exerciseIndex && s.setIndex == _setIndex) {
        return s.toUndo();
      }
    }
    return null;
  }

  @override
  int get _currentSetSnapshotIndex {
    return _history.lastIndexWhere(
      (snapshot) => snapshot.exerciseIndex == _exerciseIndex && snapshot.setIndex == _setIndex,
    );
  }

  bool matches(LocalTrainingPlanModel plan, LocalTrainingDayModel? day) {
    return _active &&
        _plan?.id == plan.id &&
        _day?.week == day?.week &&
        _day?.day == day?.day &&
        _day?.name == day?.name;
  }

  Future<void> startOrResume(LocalTrainingPlanModel plan, LocalTrainingDayModel? day) async {
    final selectedDay = day ?? plan.firstWorkoutDay;
    if (matches(plan, selectedDay)) {
      return;
    }

    _restTicker?.cancel();
    _plan = plan.deepCopy();
    _day = selectedDay?.copyWith();
    _actions = (_day?.actions ?? []).map((action) => action.copyWith()).toList();
    _history.clear();
    _setNoteDrafts.clear();
    _setNoteEdited.clear();
    _inputDrafts.clear();
    // A training session owns its draft-write queue. Reusing a completed or
    // failed Future from an earlier session can prevent every later draft and
    // set save from running.
    _draftWriteQueue = Future.value();
    _sessionId = null;
    _exerciseIndex = 0;
    _setIndex = 1;
    _elapsedOffset = Duration.zero;
    _actionStartedAt = DateTime.now();
    _actionStartedAtByIndex.clear();
    _actionStartedAtByIndex[0] = _actionStartedAt;
    _clearRest();
    _saving = false;
    _finished = false;
    _active = _actions.isNotEmpty;

    _stopwatch
      ..reset()
      ..start();
    _ensureTicker();
    notifyListeners();

    if (plan.id == null || _actions.isEmpty) {
      return;
    }

    final openSession = await _repository.findOpenSessionForDay(
      routineId: plan.id!,
      dayId: selectedDay?.id,
    );
    if (openSession == null) {
      _sessionId = await _repository.startSession(plan, selectedDay);
    } else {
      _restoreOpenSession(openSession);
    }
    notifyListeners();
  }

  void _restoreOpenSession(LocalWorkoutSessionResumeModel session) {
    _sessionId = session.sessionId;
    _elapsedOffset = DateTime.now().difference(session.startedAt);
    if (_elapsedOffset.isNegative) {
      _elapsedOffset = Duration.zero;
    }
    _history.clear();
    _setNoteDrafts.clear();
    _setNoteEdited.clear();
    _inputDrafts
      ..clear()
      ..addEntries(
        session.drafts.map(
          (draft) => MapEntry(
            '${draft.actionIndex}:${draft.setIndex}',
            draft,
          ),
        ),
      );
    for (final draft in session.drafts) {
      final key = '${draft.actionIndex}:${draft.setIndex}';
      _setNoteDrafts[key] = draft.noteText;
      _setNoteEdited[key] = draft.noteEdited;
    }
    _actionStartedAtByIndex.clear();

    for (final log in session.logs) {
      final actionIndex = _actions.indexWhere(
        (action) => sameExerciseIdentity(action.name, log.exerciseName),
      );
      if (actionIndex == -1) {
        continue;
      }
      final setIndex = log.setIndex <= 0 ? 1 : log.setIndex;
      _history.add(
        _CompletedSetSnapshot(
          exerciseIndex: actionIndex,
          setIndex: setIndex,
          logId: log.id,
          weight: log.recordedWeight,
          reps: log.recordedReps,
          restSeconds: log.restSeconds,
          recordMode: normalizeLocalRecordMode(log.recordMode),
          durationSeconds: log.recordedDurationSeconds,
        ),
      );
      final key = '$actionIndex:$setIndex';
      if (!_inputDrafts.containsKey(key)) {
        _setNoteDrafts[key] = log.note;
        _setNoteEdited[key] = log.noteEdited;
      }
    }

    if (_history.isEmpty) {
      _exerciseIndex = 0;
      _setIndex = 1;
      _markActionStartedIfNeeded(_exerciseIndex);
      return;
    }

    final last = _history.last;
    _exerciseIndex = last.exerciseIndex;
    _setIndex = last.setIndex;
    _moveToNextSet();
    _markActionStartedIfNeeded(_exerciseIndex);
  }
}

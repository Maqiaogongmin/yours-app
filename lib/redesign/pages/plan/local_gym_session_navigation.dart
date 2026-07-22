part of 'local_gym_session_controller.dart';

mixin _LocalGymSessionNavigation on ChangeNotifier, _LocalGymSessionState {
  void replaceCurrentAction(LocalTrainingActionModel action) {
    if (_actions.isEmpty || _finished || action.name.trim().isEmpty) {
      return;
    }
    _actions[_exerciseIndex] = action.copyWith(name: action.name);
    notifyListeners();
  }

  void replaceCurrentExercise(String exerciseName) {
    if (_actions.isEmpty) {
      return;
    }
    replaceCurrentAction(currentAction.copyWith(name: exerciseName));
  }

  @override
  void advanceAfterRest() {
    if (_finished || _actions.isEmpty) {
      return;
    }
    final nextExerciseIndex = _restNextExerciseIndex;
    final nextSetIndex = _restNextSetIndex;
    _clearRest();
    if (nextExerciseIndex != null && nextSetIndex != null) {
      final exerciseChanged = _exerciseIndex != nextExerciseIndex;
      _exerciseIndex = nextExerciseIndex;
      _setIndex = nextSetIndex;
      if (exerciseChanged) {
        _markActionStartedIfNeeded(_exerciseIndex);
      }
    } else {
      _moveToNextSet();
    }
    notifyListeners();
  }

  bool previewNextSet() {
    if (_actions.isEmpty || !canPreviewNextSet) {
      return false;
    }
    _finished = false;
    // 如果倒计时已完成，清除休息状态，避免滑动预览时残留"完成"界面。
    if (isRestComplete) {
      _clearRest();
    }
    _moveToNextSet();
    notifyListeners();
    return true;
  }

  bool previewPreviousSet() {
    if (_actions.isEmpty || !canPreviewPreviousSet) {
      return false;
    }
    _finished = false;
    // 如果倒计时已完成，清除休息状态，避免滑动预览时残留"完成"界面。
    if (isRestComplete) {
      _clearRest();
    }
    if (_setIndex <= 1) {
      _exerciseIndex -= 1;
      _setIndex = currentTargetSets;
      _markActionStartedIfNeeded(_exerciseIndex);
    } else {
      _setIndex -= 1;
    }
    notifyListeners();
    return true;
  }

  void updateCurrentSetNote(String note) {
    if (_actions.isEmpty || _finished) {
      return;
    }
    _setNoteDrafts[_currentSetKey] = note;
  }

  @override
  void _moveToNextSet() {
    final previousExerciseIndex = _exerciseIndex;
    if (_setIndex >= currentTargetSets) {
      if (_exerciseIndex < _actions.length - 1) {
        _exerciseIndex += 1;
        _setIndex = 1;
      }
      // 如果倒计时已完成，清除休息状态，避免滑动预览时残留"完成"界面。
      if (isRestComplete) {
        _clearRest();
      }
    } else {
      _setIndex += 1;
    }
    if (_exerciseIndex != previousExerciseIndex) {
      _markActionStartedIfNeeded(_exerciseIndex);
    }
  }

  Future<CompletedSetUndo?> undoCurrentSet() async {
    if (!_active || _saving) {
      return null;
    }

    final snapshotIndex = _currentSetSnapshotIndex;
    if (snapshotIndex == -1) {
      return null;
    }

    final snapshot = _history.removeAt(snapshotIndex);
    _clearRest();
    _finished = false;
    _saving = false;
    _exerciseIndex = snapshot.exerciseIndex;
    _setIndex = snapshot.setIndex;
    _actionStartedAtByIndex[snapshot.exerciseIndex] = DateTime.now();
    _actionStartedAt = _actionStartedAtByIndex[snapshot.exerciseIndex]!;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    _ensureTicker();
    await _repository.deleteWorkoutLog(snapshot.logId);
    notifyListeners();
    return snapshot.toUndo();
  }

  Future<CompletedSetUndo?> undoLastCompletedSet() async {
    if (!_active || _history.isEmpty || _saving) {
      return null;
    }

    final snapshot = _history.removeLast();
    _clearRest();
    _finished = false;
    _saving = false;
    _exerciseIndex = snapshot.exerciseIndex;
    _setIndex = snapshot.setIndex;
    _actionStartedAtByIndex[snapshot.exerciseIndex] = DateTime.now();
    _actionStartedAt = _actionStartedAtByIndex[snapshot.exerciseIndex]!;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    }
    _ensureTicker();
    await _repository.deleteWorkoutLog(snapshot.logId);
    notifyListeners();
    return snapshot.toUndo();
  }

  Future<void> finishSessionLocal({
    String note = '',
    bool markIncomplete = false,
  }) async {
    final sessionId = _sessionId;
    final finalNote = _buildFinalNote(note: note, markIncomplete: markIncomplete);
    _saving = true;
    _finishWorkoutState();
    if (sessionId != null) {
      await flushInputDrafts();
      await _repository.deleteWorkoutInputDraftsForSession(sessionId);
      await _repository.finishSession(sessionId, note: finalNote);
    }
    _inputDrafts.clear();
    _saving = false;
    _active = false;
    notifyListeners();
  }

  Future<LocalGymFinishResult> createFinishBackup() async {
    LocalGymFinishResult result;
    try {
      final backup = await _backupService.createAutomaticBackupIfNeeded(
        reason: 'training_finish',
        force: true,
      );
      result = LocalGymFinishResult(
        backupCreated: true,
        backupFileName: backup == null ? null : _basename(backup.file.path),
      );
    } on Object catch (error) {
      result = LocalGymFinishResult(backupCreated: false, backupError: error);
    }
    return result;
  }

  Future<LocalGymFinishResult> finishSession({
    String note = '',
    bool markIncomplete = false,
  }) async {
    await finishSessionLocal(note: note, markIncomplete: markIncomplete);
    return createFinishBackup();
  }

  String _basename(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  String _buildFinalNote({required String note, required bool markIncomplete}) {
    return note.trim();
  }

  @override
  void _startRest(int seconds) {
    _restTicker?.cancel();
    _captureRestAdvanceTarget();
    _restEndsAt = DateTime.now().add(Duration(seconds: seconds));
    notifyListeners();
    _restTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isResting) {
        _restTicker?.cancel();
        return;
      }
      notifyListeners();
      if (isRestComplete) {
        _restTicker?.cancel();
      }
    });
  }

  void _captureRestAdvanceTarget() {
    if (_setIndex >= currentTargetSets) {
      if (_exerciseIndex < _actions.length - 1) {
        _restNextExerciseIndex = _exerciseIndex + 1;
        _restNextSetIndex = 1;
      } else {
        _restNextExerciseIndex = _exerciseIndex;
        _restNextSetIndex = _setIndex;
      }
    } else {
      _restNextExerciseIndex = _exerciseIndex;
      _restNextSetIndex = _setIndex + 1;
    }
  }

  @override
  void _clearRest() {
    _restTicker?.cancel();
    _restEndsAt = null;
    _restNextExerciseIndex = null;
    _restNextSetIndex = null;
  }

  DateTime _actionStartedAtFor(int actionIndex) {
    return _actionStartedAtByIndex[actionIndex] ?? _actionStartedAt;
  }

  @override
  void _markActionStartedIfNeeded(int actionIndex) {
    _actionStartedAtByIndex.putIfAbsent(actionIndex, DateTime.now);
    _actionStartedAt = _actionStartedAtByIndex[actionIndex] ?? DateTime.now();
  }

  @override
  void _finishWorkoutState() {
    _clearRest();
    _ticker?.cancel();
    _ticker = null;
    _finished = true;
    _stopwatch.stop();
    notifyListeners();
  }

  @override
  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active && !_finished) {
        notifyListeners();
      }
    });
  }
}

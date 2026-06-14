import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';

class CompletedSetUndo {
  final double weight;
  final int reps;
  final int restSeconds;
  final String recordMode;
  final int durationSeconds;

  const CompletedSetUndo({
    required this.weight,
    required this.reps,
    required this.restSeconds,
    this.recordMode = localRecordModeStandard,
    this.durationSeconds = 0,
  });
}

class LocalGymFinishResult {
  final bool backupCreated;
  final String? backupFileName;
  final Object? backupError;

  const LocalGymFinishResult({
    required this.backupCreated,
    this.backupFileName,
    this.backupError,
  });
}

class _CompletedSetSnapshot {
  final int exerciseIndex;
  final int setIndex;
  final int logId;
  final double weight;
  final int reps;
  final int restSeconds;
  final String recordMode;
  final int durationSeconds;

  const _CompletedSetSnapshot({
    required this.exerciseIndex,
    required this.setIndex,
    required this.logId,
    required this.weight,
    required this.reps,
    required this.restSeconds,
    this.recordMode = localRecordModeStandard,
    this.durationSeconds = 0,
  });

  CompletedSetUndo toUndo() {
    return CompletedSetUndo(
      weight: weight,
      reps: reps,
      restSeconds: restSeconds,
      recordMode: recordMode,
      durationSeconds: durationSeconds,
    );
  }
}

class LocalGymSessionController extends ChangeNotifier {
  LocalGymSessionController._();

  static final LocalGymSessionController instance = LocalGymSessionController._();

  static const int defaultSetsPerExercise = 3;

  final LocalTrainingRepository _repository = LocalTrainingRepository(
    locator<LocalTrainingDatabase>(),
  );
  final BackupService _backupService = BackupService();
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsedOffset = Duration.zero;

  Timer? _ticker;
  Timer? _restTicker;
  LocalTrainingPlanModel? _plan;
  LocalTrainingDayModel? _day;
  List<LocalTrainingActionModel> _actions = [];
  final List<_CompletedSetSnapshot> _history = [];
  final Map<String, String> _setNoteDrafts = {};
  int? _sessionId;
  DateTime _actionStartedAt = DateTime.now();
  final Map<int, DateTime> _actionStartedAtByIndex = {};
  int _exerciseIndex = 0;
  int _setIndex = 1;
  DateTime? _restEndsAt;
  int? _restNextExerciseIndex;
  int? _restNextSetIndex;
  bool _saving = false;
  bool _finished = false;
  bool _active = false;

  LocalTrainingPlanModel? get plan => _plan;
  LocalTrainingDayModel? get day => _day;
  List<LocalTrainingActionModel> get actions => _actions;
  int get exerciseIndex => _exerciseIndex;
  int get setIndex => _setIndex;
  int get restRemainingSeconds {
    final restEndsAt = _restEndsAt;
    if (restEndsAt == null) {
      return 0;
    }
    final remaining = restEndsAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get isSaving => _saving;
  bool get isFinished => _finished;
  bool get isActive => _active;
  bool get isResting => _restEndsAt != null;
  bool get isRestComplete => isResting && restRemainingSeconds == 0;
  bool get canUndoSet => _history.isNotEmpty;
  bool get canUndoCurrentSet => _currentSetSnapshotIndex != -1;
  bool get hasCompletedSets => _history.isNotEmpty;
  bool get canPreviewPreviousSet => _exerciseIndex > 0 || _setIndex > 1;
  bool get canPreviewNextSet {
    if (_actions.isEmpty || _finished) {
      return false;
    }
    return _exerciseIndex < _actions.length - 1 || _setIndex < currentTargetSets;
  }

  Duration get elapsed => _elapsedOffset + _stopwatch.elapsed;
  bool get hasActions => _actions.isNotEmpty;

  LocalTrainingActionModel get currentAction => _actions[_exerciseIndex];
  String get currentExercise => currentAction.name;
  bool get isCurrentFreeRecord => currentAction.recordMode == localRecordModeFree;
  int get currentTargetSets => isCurrentFreeRecord ? 1 : currentAction.targetSets;
  int get currentTargetReps => currentAction.targetReps;
  double? get currentTargetWeight => currentAction.targetWeight;
  int? get currentTargetRestSeconds => currentAction.targetRestSeconds;
  String get currentNote => currentAction.note;
  String get currentSetNote => _setNoteDrafts[_currentSetKey] ?? currentNote;
  Duration get currentActionElapsed {
    final value = DateTime.now().difference(_actionStartedAtFor(_exerciseIndex));
    return value.isNegative ? Duration.zero : value;
  }

  int get completedStandardSetCount =>
      _history.where((item) => item.recordMode != localRecordModeFree).length;
  int get completedFreeRecordCount =>
      _history.where((item) => item.recordMode == localRecordModeFree).length;

  String get _currentSetKey => '$_exerciseIndex:$_setIndex';

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
    _actionStartedAtByIndex.clear();

    for (final log in session.logs) {
      final actionIndex = _actions.indexWhere(
        (action) => sameExerciseIdentity(action.name, log.exerciseName),
      );
      if (actionIndex == -1) {
        continue;
      }
      final setIndex = log.setIndex <= 0 ? 1 : log.setIndex;
      final restSeconds = _actions[actionIndex].targetRestSeconds ?? 90;
      _history.add(
        _CompletedSetSnapshot(
          exerciseIndex: actionIndex,
          setIndex: setIndex,
          logId: log.id,
          weight: log.weight,
          reps: log.reps,
          restSeconds: restSeconds,
          recordMode: normalizeLocalRecordMode(log.recordMode),
          durationSeconds: log.durationSeconds,
        ),
      );
      if (log.note.trim().isNotEmpty) {
        _setNoteDrafts['$actionIndex:$setIndex'] = log.note;
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

  Future<void> saveSet({
    required double weight,
    required int reps,
    required int restSeconds,
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
      weight: weight,
      reps: reps,
      rir: null,
      durationSeconds: elapsed.inSeconds,
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
        durationSeconds: elapsed.inSeconds,
      ),
    );
    _saving = false;
    final isLastSet = _setIndex >= currentTargetSets;
    final isLastExercise = _exerciseIndex >= _actions.length - 1;
    if (isLastSet && isLastExercise) {
      _finishWorkoutState();
      return;
    }

    final safeRest = restSeconds.clamp(0, 3600);
    if (safeRest == 0) {
      advanceAfterRest();
    } else {
      _startRest(safeRest);
    }
  }

  Future<void> completeFreeRecord() async {
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

    await _repository.deleteSetLogs(
      sessionId: sessionId,
      exerciseName: currentExercise,
      setIndex: 1,
    );
    _history.removeWhere((s) => s.exerciseIndex == _exerciseIndex && s.setIndex == 1);

    final durationSeconds = currentActionElapsed.inSeconds.clamp(0, 24 * 60 * 60);
    final logId = await _repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: _day?.id,
      exerciseName: currentExercise,
      setIndex: 1,
      weight: 0,
      reps: 0,
      rir: null,
      durationSeconds: durationSeconds,
      note: currentSetNote,
      recordMode: localRecordModeFree,
    );

    _history.add(
      _CompletedSetSnapshot(
        exerciseIndex: _exerciseIndex,
        setIndex: 1,
        logId: logId,
        weight: 0,
        reps: 0,
        restSeconds: 0,
        recordMode: localRecordModeFree,
        durationSeconds: durationSeconds,
      ),
    );
    _saving = false;
    final isLastExercise = _exerciseIndex >= _actions.length - 1;
    if (isLastExercise) {
      _finishWorkoutState();
      return;
    }
    _moveToNextSet();
    notifyListeners();
  }

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
    await _repository.deleteWorkoutLog(snapshot.logId);
    notifyListeners();
    return snapshot.toUndo();
  }

  Future<LocalGymFinishResult> finishSession({
    String note = '',
    bool markIncomplete = false,
  }) async {
    final sessionId = _sessionId;
    final finalNote = _buildFinalNote(note: note, markIncomplete: markIncomplete);
    _saving = true;
    _finishWorkoutState();
    if (sessionId != null) {
      await _repository.finishSession(sessionId, note: finalNote);
    }

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

    _saving = false;
    _active = false;
    notifyListeners();
    return result;
  }

  String _basename(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  String _buildFinalNote({required String note, required bool markIncomplete}) {
    final trimmedNote = note.trim();
    if (!markIncomplete || !hasCompletedSets) {
      return trimmedNote;
    }
    const incompleteNote = '未完成训练计划';
    if (trimmedNote.isEmpty) {
      return incompleteNote;
    }
    if (trimmedNote.contains(incompleteNote)) {
      return trimmedNote;
    }
    return '$trimmedNote\n$incompleteNote';
  }

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

  void _clearRest() {
    _restTicker?.cancel();
    _restEndsAt = null;
    _restNextExerciseIndex = null;
    _restNextSetIndex = null;
  }

  DateTime _actionStartedAtFor(int actionIndex) {
    return _actionStartedAtByIndex[actionIndex] ?? _actionStartedAt;
  }

  void _markActionStartedIfNeeded(int actionIndex) {
    _actionStartedAtByIndex.putIfAbsent(actionIndex, DateTime.now);
    _actionStartedAt = _actionStartedAtByIndex[actionIndex] ?? DateTime.now();
  }

  void _finishWorkoutState() {
    _clearRest();
    _finished = true;
    _stopwatch.stop();
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active && !_finished) {
        notifyListeners();
      }
    });
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
part 'local_gym_session_state.dart';
part 'local_gym_session_drafts.dart';
part 'local_gym_session_persistence.dart';
part 'local_gym_session_navigation.dart';

class CompletedSetUndo {
  final double? weight;
  final int? reps;
  final int? restSeconds;
  final String recordMode;
  final int? durationSeconds;

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
  final double? weight;
  final int? reps;
  final int? restSeconds;
  final String recordMode;
  final int? durationSeconds;

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

class LocalGymSessionController extends ChangeNotifier
    with
        _LocalGymSessionState,
        _LocalGymSessionDrafts,
        _LocalGymSessionPersistence,
        _LocalGymSessionNavigation {
  LocalGymSessionController._() {
    _ticker = null;
    _restTicker = null;
    _sessionId = null;
    _restNextExerciseIndex = null;
    _restNextSetIndex = null;
  }

  static final LocalGymSessionController instance = LocalGymSessionController._();

  static const int defaultSetsPerExercise = 3;

  @override
  LocalTrainingRepository get _repository => LocalTrainingRepository(
    locator<LocalTrainingDatabase>(),
  );
  @override
  final BackupService _backupService = BackupService();
  @override
  final Stopwatch _stopwatch = Stopwatch();
  @override
  Duration _elapsedOffset = Duration.zero;

  @override
  late Timer? _ticker;
  @override
  late Timer? _restTicker;
  @override
  LocalTrainingPlanModel? _plan;
  @override
  LocalTrainingDayModel? _day;
  @override
  List<LocalTrainingActionModel> _actions = [];
  @override
  final List<_CompletedSetSnapshot> _history = [];
  @override
  final Map<String, String> _setNoteDrafts = {};
  @override
  final Map<String, LocalWorkoutInputDraft> _inputDrafts = {};
  @override
  Future<void> _draftWriteQueue = Future.value();
  @override
  late int? _sessionId;
  @override
  DateTime _actionStartedAt = DateTime.now();
  @override
  final Map<int, DateTime> _actionStartedAtByIndex = {};
  @override
  int _exerciseIndex = 0;
  @override
  int _setIndex = 1;
  @override
  DateTime? _restEndsAt;
  @override
  late int? _restNextExerciseIndex;
  @override
  late int? _restNextSetIndex;
  @override
  bool _saving = false;
  @override
  bool _finished = false;
  @override
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
  @override
  bool get isResting => _restEndsAt != null;
  @override
  bool get isRestComplete => isResting && restRemainingSeconds == 0;
  bool get canUndoSet => _history.isNotEmpty;
  bool get canUndoCurrentSet => _currentSetSnapshotIndex != -1;
  bool get hasCompletedSets => _history.isNotEmpty;
  @override
  bool get canPreviewPreviousSet => _exerciseIndex > 0 || _setIndex > 1;
  @override
  bool get canPreviewNextSet {
    if (_actions.isEmpty || _finished) {
      return false;
    }
    return _exerciseIndex < _actions.length - 1 || _setIndex < currentTargetSets;
  }

  Duration get elapsed => _elapsedOffset + _stopwatch.elapsed;
  bool get hasActions => _actions.isNotEmpty;

  @override
  LocalTrainingActionModel get currentAction => _actions[_exerciseIndex];
  @override
  String get currentExercise => currentAction.name;
  @override
  bool get isCurrentFreeRecord => currentAction.recordMode == localRecordModeFree;
  @override
  int get currentTargetSets =>
      normalizeTargetSetsForRecordMode(currentAction.recordMode, currentAction.targetSets);
  int get currentTargetReps => currentAction.targetReps;
  int get currentFreeRecordTargetDurationSeconds {
    final explicitTarget = currentAction.targetDurationSeconds;
    if (explicitTarget != null) {
      return explicitTarget.clamp(0, 24 * 60 * 60);
    }
    return 0;
  }

  double? get currentTargetWeight => currentAction.targetWeight;
  int? get currentTargetRestSeconds => currentAction.targetRestSeconds;
  String get currentNote => currentAction.note;
  @override
  String get currentSetNote => _setNoteDrafts[_currentSetKey] ?? currentNote;
  Duration get currentActionElapsed {
    final value = DateTime.now().difference(_actionStartedAtFor(_exerciseIndex));
    return value.isNegative ? Duration.zero : value;
  }

  int get completedStandardSetCount =>
      _history.where((item) => item.recordMode != localRecordModeFree).length;
  int get completedFreeRecordCount =>
      _history.where((item) => item.recordMode == localRecordModeFree).length;

  @override
  String get _currentSetKey => '$_exerciseIndex:$_setIndex';

  LocalWorkoutInputDraft? get currentInputDraft => _inputDrafts[_currentSetKey];
}

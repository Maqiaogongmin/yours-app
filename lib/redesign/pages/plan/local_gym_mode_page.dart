import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/pages/plan/exercise_picker_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';
import 'package:yours/redesign/shareability/yours_workout_share_poster_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

part 'local_gym_mode_page/replacement_action_sheet.dart';
part 'local_gym_mode_page/session_cards.dart';
part 'local_gym_mode_page/session_fields.dart';

class LocalGymModePage extends StatefulWidget {
  final LocalTrainingPlanModel plan;
  final LocalTrainingDayModel? day;

  const LocalGymModePage({super.key, required this.plan, this.day});

  @override
  State<LocalGymModePage> createState() => _LocalGymModePageState();
}

class _LocalGymModePageState extends State<LocalGymModePage> {
  final LocalGymSessionController _session = LocalGymSessionController.instance;

  final _weightCtrl = TextEditingController(text: '0');
  final _repsCtrl = TextEditingController(text: '10');
  final _restCtrl = TextEditingController(text: '90');
  final _freeWeightCtrl = TextEditingController(text: '0');
  final _freeDurationCtrl = TextEditingController(text: '0');
  final _freeRestCtrl = TextEditingController(text: '0');
  final _actionNoteCtrl = TextEditingController();
  final _sessionNoteCtrl = TextEditingController();
  int? _lastExerciseIndex;
  int? _lastSetIndex;
  String? _startError;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSession();
      }
    });
  }

  Future<void> _startSession() async {
    try {
      await _session.startOrResume(widget.plan, widget.day);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _startError = localizedErrorDetail(context, error));
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      _syncTargetRepsIfPositionChanged();
      setState(() {});
    }
  }

  void _syncTargetRepsIfPositionChanged() {
    if (!_session.hasActions) {
      return;
    }
    final positionChanged =
        _lastExerciseIndex != _session.exerciseIndex || _lastSetIndex != _session.setIndex;
    if (!positionChanged) {
      return;
    }
    _lastExerciseIndex = _session.exerciseIndex;
    _lastSetIndex = _session.setIndex;

    // 优先使用已保存的实际数据；无保存记录时才用计划目标值。
    final saved = _session.getSavedDataForCurrentSet();
    if (saved != null) {
      _weightCtrl.text = saved.weight.toStringAsFixed(
        saved.weight.truncateToDouble() == saved.weight ? 0 : 1,
      );
      _repsCtrl.text = saved.reps.toString();
      _restCtrl.text = saved.restSeconds.toString();
      _freeWeightCtrl.text = saved.weight.toStringAsFixed(
        saved.weight.truncateToDouble() == saved.weight ? 0 : 1,
      );
      _freeDurationCtrl.text = saved.durationSeconds.toString();
      _freeRestCtrl.text = saved.restSeconds.toString();
    } else {
      _repsCtrl.text = _session.currentTargetReps.toString();
      final targetWeight = _session.currentTargetWeight;
      _weightCtrl.text = targetWeight == null
          ? '0'
          : targetWeight.toStringAsFixed(targetWeight.truncateToDouble() == targetWeight ? 0 : 1);
      final restSeconds =
          _session.currentTargetRestSeconds ?? _restSecondsFromNote(_session.currentNote);
      _restCtrl.text = (restSeconds ?? 90).toString();
      _freeWeightCtrl.text = targetWeight == null
          ? '0'
          : targetWeight.toStringAsFixed(targetWeight.truncateToDouble() == targetWeight ? 0 : 1);
      _freeDurationCtrl.text = _session.currentActionElapsed.inSeconds.toString();
      _freeRestCtrl.text = (restSeconds ?? 0).toString();
    }
    if (saved == null && _session.currentAction.targetDurationSeconds != null) {
      _freeDurationCtrl.text = _session.currentAction.targetDurationSeconds.toString();
    }
    _actionNoteCtrl.text = _session.currentSetNote;
  }

  Future<void> _saveSet() async {
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final restSeconds = int.tryParse(_restCtrl.text.trim()) ?? 90;
    await _session.saveSet(
      weight: weight,
      reps: reps,
      restSeconds: restSeconds,
    );
  }

  Future<void> _saveFreeRecord() async {
    final weight = double.tryParse(_freeWeightCtrl.text.trim()) ?? 0;
    final durationSeconds =
        int.tryParse(_freeDurationCtrl.text.trim()) ?? _session.currentActionElapsed.inSeconds;
    final restSeconds = int.tryParse(_freeRestCtrl.text.trim()) ?? 0;
    await _session.completeFreeRecord(
      weight: weight,
      durationSeconds: durationSeconds,
      restSeconds: restSeconds,
    );
  }

  Future<void> _replaceCurrentExercise() async {
    if (!_session.hasActions || _session.isSaving || _session.isFinished) {
      return;
    }
    final selected = await Navigator.of(context).push<CustomExerciseModel>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExercisePickerPage.single(title: context.l10n.workoutReplaceExercise),
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    final previous = _session.currentExercise;
    final replacement = await showModalBottomSheet<LocalTrainingActionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplacementActionSheet(
        title: context.l10n.workoutReplaceExercise,
        initialAction: _session.currentAction.copyWith(name: selected.exerciseReference),
      ),
    );
    if (!mounted || replacement == null) {
      return;
    }
    _session.replaceCurrentAction(replacement);
    _syncTargetRepsIfPositionChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.workoutExerciseReplaced(
            localizedExerciseName(context, previous),
            localizedExerciseName(context, selected.exerciseReference),
          ),
        ),
      ),
    );
  }

  Future<void> _finishSession({bool openPoster = false}) async {
    final shareDate = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    await _session.finishSessionLocal(note: _sessionNoteCtrl.text.trim());
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.workoutSavedLocal), behavior: SnackBarBehavior.floating),
    );
    unawaited(_showFinishBackupMessageWhenReady(messenger));
    if (openPoster) {
      final repository = LocalTrainingRepository(locator<LocalTrainingDatabase>());
      await openWorkoutSharePoster(
        context: context,
        repository: repository,
        date: shareDate,
      );
      if (!mounted) {
        return;
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmEarlyFinishSession() async {
    final hasCompletedSets = _session.hasCompletedSets;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.workoutEndTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasCompletedSets ? context.l10n.workoutEndIncomplete : context.l10n.workoutEndEmpty,
            ),
            if (hasCompletedSets) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _sessionNoteCtrl,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: context.l10n.workoutPostNote,
                  hintText: context.l10n.workoutPostNoteHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.workoutEnd,
              style: context
                  .yoursText(YoursTextRole.body)
                  .copyWith(color: kRed, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await _session.finishSessionLocal(
      note: _sessionNoteCtrl.text.trim(),
      markIncomplete: true,
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.workoutSavedLocal), behavior: SnackBarBehavior.floating),
    );
    unawaited(_showFinishBackupMessageWhenReady(messenger));
    Navigator.pop(context);
  }

  Future<void> _showFinishBackupMessageWhenReady(ScaffoldMessengerState messenger) async {
    final l10n = context.l10n;
    final result = await _session.createFinishBackup();
    final message = result.backupCreated
        ? l10n.workoutSavedBackup(result.backupFileName ?? '')
        : l10n.workoutSavedBackupFailed(
            result.backupError == null ? l10n.commonUnknownError : '${result.backupError}',
          );
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _undoCurrentSet() async {
    final undo = await _session.undoCurrentSet();
    if (undo == null || !mounted) {
      return false;
    }
    _restoreInputs(undo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.workoutSetUndone)),
    );
    return true;
  }

  void _previewPreviousSet() {
    final moved = _session.previewPreviousSet();
    if (!moved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workoutFirstSet)),
      );
    }
  }

  Future<void> _exitWorkoutPage() async {
    if (!mounted) {
      return;
    }
    await Navigator.maybePop(context);
  }

  void _goToNextSetPreview() {
    final moved = _session.previewNextSet();
    if (!moved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workoutLastSet)),
      );
    }
  }

  void _restoreInputs(CompletedSetUndo undo) {
    _weightCtrl.text = undo.weight.toStringAsFixed(
      undo.weight.truncateToDouble() == undo.weight ? 0 : 1,
    );
    _repsCtrl.text = undo.reps.toString();
    _restCtrl.text = undo.restSeconds.toString();
    _freeWeightCtrl.text = undo.weight.toStringAsFixed(
      undo.weight.truncateToDouble() == undo.weight ? 0 : 1,
    );
    _freeDurationCtrl.text = undo.durationSeconds.toString();
    _freeRestCtrl.text = undo.restSeconds.toString();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
    _freeWeightCtrl.dispose();
    _freeDurationCtrl.dispose();
    _freeRestCtrl.dispose();
    _actionNoteCtrl.dispose();
    _sessionNoteCtrl.dispose();
    super.dispose();
  }

  String get _elapsedText => _durationText(_session.elapsed);

  String _durationText(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    if (_startError != null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: _appBar(context.l10n.workoutTimer),
        body: _LocalGymEmptyState(
          message: context.l10n.workoutTimerStartFailed(
            _startError ?? context.l10n.commonUnknownError,
          ),
        ),
      );
    }
    if (!_session.hasActions) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: _appBar(context.l10n.workoutTimer),
        body: Padding(
          padding: const EdgeInsets.all(kGutter),
          child: _LocalGymEmptyState(message: context.l10n.workoutNoActions),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: _appBar(
        _session.isFinished ? context.l10n.workoutSummary : context.l10n.workoutTimer,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 450) {
            _previewPreviousSet();
          } else if (velocity < -450) {
            _goToNextSetPreview();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kGutter, 16, kGutter, 28),
          children: [
            _LocalGymHeaderCard(
              session: _session,
              fallbackPlanName: widget.plan.name,
              elapsedText: _elapsedText,
            ),
            const SizedBox(height: 14),
            if (_session.isFinished)
              _LocalGymSummaryCard(
                session: _session,
                sessionNoteCtrl: _sessionNoteCtrl,
                onUndoCurrentSet: _undoCurrentSet,
                onFinishSession: _finishSession,
              )
            else if (_session.isResting)
              _LocalGymRestCard(session: _session, onUndoCurrentSet: _undoCurrentSet)
            else
              _LocalGymLogCard(
                session: _session,
                weightCtrl: _weightCtrl,
                repsCtrl: _repsCtrl,
                restCtrl: _restCtrl,
                freeWeightCtrl: _freeWeightCtrl,
                freeDurationCtrl: _freeDurationCtrl,
                freeRestCtrl: _freeRestCtrl,
                actionNoteCtrl: _actionNoteCtrl,
                onReplaceCurrentExercise: _replaceCurrentExercise,
                onSaveSet: _saveSet,
                onSaveFreeRecord: _saveFreeRecord,
                onUndoCurrentSet: _undoCurrentSet,
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(String title) {
    final palette = context.yoursPalette;
    return AppBar(
      backgroundColor: palette.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: palette.border)),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.fg),
        onPressed: _exitWorkoutPage,
      ),
      title: Text(
        title,
        style: context
            .yoursText(YoursTextRole.body)
            .copyWith(color: palette.fg, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (_session.hasActions && !_session.isFinished)
          IconButton(
            tooltip: context.l10n.workoutEnd,
            icon: Icon(Icons.close, color: palette.fg, size: 28),
            onPressed: _session.isSaving ? null : _confirmEarlyFinishSession,
          ),
      ],
    );
  }

  int? _restSecondsFromNote(String note) {
    final match = RegExp(r'休息[：:\s]*(\d+)\s*(?:s|秒)?').firstMatch(note);
    if (match == null) {
      return null;
    }
    final seconds = int.tryParse(match.group(1) ?? '');
    return seconds?.clamp(0, 3600);
  }
}

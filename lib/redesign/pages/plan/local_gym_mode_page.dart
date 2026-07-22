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
part 'local_gym_mode_page/session_header_cards.dart';
part 'local_gym_mode_page/session_log_card.dart';
part 'local_gym_mode_page/session_completion_cards.dart';
part 'local_gym_mode_page/session_fields.dart';
part 'local_gym_mode_page/input_bindings.dart';
part 'local_gym_mode_page/page_chrome.dart';

class LocalGymModePage extends StatefulWidget {
  final LocalTrainingPlanModel plan;
  final LocalTrainingDayModel? day;

  const LocalGymModePage({super.key, required this.plan, this.day});

  @override
  State<LocalGymModePage> createState() => _LocalGymModePageState();
}

class _LocalGymModePageState extends State<LocalGymModePage> with WidgetsBindingObserver {
  final LocalGymSessionController _session = LocalGymSessionController.instance;

  final _inputs = _LocalGymInputBindings();
  final _sessionNoteCtrl = TextEditingController();
  String? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      if (mounted) {
        _syncInputsForPosition(force: true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _startError = localizedErrorDetail(context, error));
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      _syncInputsForPosition();
      setState(() {});
    }
  }

  void _syncInputsForPosition({bool force = false}) {
    _inputs.syncForPosition(_session, force: force);
  }

  Future<void> _saveSet() async {
    await _inputs.persist(_session);
    await _session.saveSet(
      weight: _inputs.standardWeight,
      reps: _inputs.standardReps,
      restSeconds: _inputs.standardRestSeconds,
    );
  }

  Future<void> _saveFreeRecord() async {
    await _inputs.persist(_session);
    await _session.completeFreeRecord(
      weight: _inputs.freeWeight,
      durationSeconds: _inputs.freeDurationSeconds,
      restSeconds: _inputs.freeRestSeconds,
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
    _syncInputsForPosition(force: true);
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
    _inputs.restore(undo);
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

  Future<void> _dismissKeyboardAndPersist() async {
    await _inputs.persist(_session);
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_inputs.persist(_session));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    _inputs.dispose();
    _sessionNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    if (_startError != null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: _localGymAppBar(
          context,
          context.l10n.workoutTimer,
          session: _session,
          onBack: _exitWorkoutPage,
          onEnd: _confirmEarlyFinishSession,
        ),
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
        appBar: _localGymAppBar(
          context,
          context.l10n.workoutTimer,
          session: _session,
          onBack: _exitWorkoutPage,
          onEnd: _confirmEarlyFinishSession,
        ),
        body: Padding(
          padding: const EdgeInsets.all(kGutter),
          child: _LocalGymEmptyState(message: context.l10n.workoutNoActions),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: _localGymAppBar(
        context,
        _session.isFinished ? context.l10n.workoutSummary : context.l10n.workoutTimer,
        session: _session,
        onBack: _exitWorkoutPage,
        onEnd: _confirmEarlyFinishSession,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => unawaited(_dismissKeyboardAndPersist()),
        onHorizontalDragEnd: (details) async {
          await _dismissKeyboardAndPersist();
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 450) {
            _previewPreviousSet();
          } else if (velocity < -450) {
            _goToNextSetPreview();
          }
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(kGutter, 16, kGutter, 28),
          children: [
            _LocalGymHeaderCard(
              session: _session,
              fallbackPlanName: widget.plan.name,
              elapsedText: _formatLocalGymDuration(_session.elapsed),
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
                weightCtrl: _inputs.weightCtrl,
                repsCtrl: _inputs.repsCtrl,
                restCtrl: _inputs.restCtrl,
                freeWeightCtrl: _inputs.freeWeightCtrl,
                freeDurationCtrl: _inputs.freeDurationCtrl,
                freeRestCtrl: _inputs.freeRestCtrl,
                actionNoteCtrl: _inputs.actionNoteCtrl,
                onReplaceCurrentExercise: _replaceCurrentExercise,
                onSaveSet: _saveSet,
                onSaveFreeRecord: _saveFreeRecord,
                onUndoCurrentSet: _undoCurrentSet,
                onInputChanged: () => unawaited(_inputs.persist(_session)),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

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
    } else {
      _repsCtrl.text = _session.currentTargetReps.toString();
      final targetWeight = _session.currentTargetWeight;
      _weightCtrl.text = targetWeight == null
          ? '0'
          : targetWeight.toStringAsFixed(targetWeight.truncateToDouble() == targetWeight ? 0 : 1);
      final restSeconds =
          _session.currentTargetRestSeconds ?? _restSecondsFromNote(_session.currentNote);
      _restCtrl.text = (restSeconds ?? 90).toString();
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

  Future<void> _finishSession() async {
    final result = await _session.finishSession(note: _sessionNoteCtrl.text.trim());
    if (!mounted) {
      return;
    }
    _showFinishBackupMessage(result);
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
              style: const TextStyle(color: kRed, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final result = await _session.finishSession(
      note: _sessionNoteCtrl.text.trim(),
      markIncomplete: true,
    );
    if (!mounted) {
      return;
    }
    _showFinishBackupMessage(result);
    Navigator.pop(context);
  }

  void _showFinishBackupMessage(LocalGymFinishResult result) {
    final message = result.backupCreated
        ? context.l10n.workoutSavedBackup(result.backupFileName ?? '')
        : context.l10n.workoutSavedBackupFailed(
            result.backupError == null ? context.l10n.commonUnknownError : '${result.backupError}',
          );
    ScaffoldMessenger.of(context).showSnackBar(
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
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
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
        body: _emptyState(
          context.l10n.workoutTimerStartFailed(_startError ?? context.l10n.commonUnknownError),
        ),
      );
    }
    if (!_session.hasActions) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: _appBar(context.l10n.workoutTimer),
        body: Padding(
          padding: const EdgeInsets.all(kGutter),
          child: _emptyState(),
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
            _headerCard(),
            const SizedBox(height: 14),
            if (_session.isFinished)
              _summaryCard()
            else if (_session.isResting)
              _restCard()
            else
              _logCard(),
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
        style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
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

  Widget _emptyState([
    String? message,
  ]) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Text(
        message ?? context.l10n.workoutNoActions,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 14),
      ),
    );
  }

  Widget _headerCard() {
    final palette = context.yoursPalette;
    final day = _session.day;
    final dayName = day == null
        ? context.l10n.workoutDefaultDay
        : '${context.l10n.planDayTitle(day.week, day.day)} · ${day.name}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _session.plan?.name ?? widget.plan.name,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 4),
          Text(dayName, style: TextStyle(fontSize: 14, color: palette.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(context.l10n.workoutElapsed, _elapsedText),
              const SizedBox(width: 8),
              _metric(
                context.l10n.workoutExercise,
                '${_session.exerciseIndex + 1}/${_session.actions.length}',
              ),
              const SizedBox(width: 8),
              _metric(
                _session.isCurrentFreeRecord
                    ? context.l10n.workoutRecordMode
                    : context.l10n.homeSets,
                _session.isCurrentFreeRecord
                    ? context.l10n.planRecordModeFree
                    : '${_session.setIndex}/${_session.currentTargetSets}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logCard() {
    final palette = context.yoursPalette;
    final exercise = _session.currentExercise;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.workoutCurrentExercise,
            style: TextStyle(fontSize: 13, color: palette.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            localizedExerciseName(context, exercise),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 18),
          if (_session.isCurrentFreeRecord) ...[
            _actionNoteField(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _session.isSaving ? null : _session.completeFreeRecord,
                style: TextButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  _session.isSaving
                      ? context.l10n.homeSaving
                      : context.l10n.workoutCompleteFreeRecord,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _input(context.l10n.homeWeightKg, _weightCtrl, decimal: true)),
                const SizedBox(width: 10),
                Expanded(child: _input(context.l10n.homeReps, _repsCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _input(context.l10n.workoutRestSeconds, _restCtrl)),
              ],
            ),
            const SizedBox(height: 12),
            _actionNoteField(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _session.isSaving ? null : _saveSet,
                style: TextButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  _session.isSaving ? context.l10n.homeSaving : context.l10n.workoutSaveSet,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          if (_session.canUndoCurrentSet) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _undoCurrentSet,
                style: TextButton.styleFrom(
                  foregroundColor: kRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: palette.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _session.isCurrentFreeRecord
                      ? context.l10n.workoutUndoFreeRecord
                      : context.l10n.workoutUndoSet,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _restCard() {
    final palette = context.yoursPalette;
    final seconds = _session.restRemainingSeconds;
    final restComplete = _session.isRestComplete;
    final isLastSet = _session.setIndex >= _session.currentTargetSets;
    final hasNextExercise = _session.exerciseIndex < _session.actions.length - 1;
    final nextSet = isLastSet && hasNextExercise ? 1 : _session.setIndex + 1;
    final nextExercise = isLastSet && hasNextExercise
        ? _session.actions[_session.exerciseIndex + 1]
        : _session.currentExercise;
    final nextLabel = isLastSet && !hasNextExercise
        ? context.l10n.workoutNextSummary
        : context.l10n.workoutNextSetLabel(
            localizedExerciseName(context, '$nextExercise'),
            nextSet,
          );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.workoutRestBetween,
            style: TextStyle(fontSize: 16, color: palette.muted, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            width: 156,
            height: 156,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(color: palette.accent.withValues(alpha: 0.18), width: 8),
            ),
            child: Text(
              restComplete ? context.l10n.commonDone : '${seconds}s',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: palette.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nextLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: palette.fg, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _session.advanceAfterRest,
              style: TextButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                restComplete ? context.l10n.workoutNextSet : context.l10n.workoutSkipRest,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _undoCurrentSet,
              style: TextButton.styleFrom(
                foregroundColor: kRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: palette.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.workoutUndoReturnLog,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.workoutRestHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final palette = context.yoursPalette;
    final totalSets = _session.completedStandardSetCount;
    final freeRecords = _session.completedFreeRecordCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.workoutComplete,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.workoutCompletedMixedSummary(
              _session.actions.length,
              totalSets,
              freeRecords,
            ),
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
          const SizedBox(height: 16),
          _sessionNoteField(),
          const SizedBox(height: 18),
          if (_session.canUndoCurrentSet) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _undoCurrentSet,
                style: TextButton.styleFrom(
                  foregroundColor: kRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: palette.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  context.l10n.workoutUndoLastReturnLog,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _finishSession,
              style: TextButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                context.l10n.workoutFinishSave,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    final palette = context.yoursPalette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: palette.fg),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: palette.muted)),
          ],
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool decimal = false,
    bool optional = false,
  }) {
    final palette = context.yoursPalette;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      cursorColor: palette.accent,
      style: TextStyle(color: palette.fg),
      decoration: InputDecoration(
        labelText: label,
        hintText: optional ? context.l10n.workoutOptional : null,
        labelStyle: TextStyle(color: palette.muted),
        hintStyle: TextStyle(color: palette.subtle),
        filled: true,
        fillColor: palette.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
    );
  }

  Widget _actionNoteField() {
    final palette = context.yoursPalette;
    return TextField(
      controller: _actionNoteCtrl,
      minLines: 2,
      maxLines: 4,
      onChanged: _session.updateCurrentSetNote,
      cursorColor: palette.accent,
      style: TextStyle(color: palette.fg),
      decoration: InputDecoration(
        labelText: context.l10n.workoutNote,
        hintText: context.l10n.workoutNoteHint,
        labelStyle: TextStyle(color: palette.muted),
        hintStyle: TextStyle(color: palette.subtle),
        filled: true,
        fillColor: palette.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
    );
  }

  Widget _sessionNoteField() {
    final palette = context.yoursPalette;
    return TextField(
      controller: _sessionNoteCtrl,
      minLines: 3,
      maxLines: 5,
      cursorColor: palette.accent,
      style: TextStyle(color: palette.fg),
      decoration: InputDecoration(
        labelText: context.l10n.workoutTrainingNote,
        labelStyle: TextStyle(color: palette.muted),
        filled: true,
        fillColor: palette.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
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

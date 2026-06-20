part of '../local_gym_mode_page.dart';

class _LocalGymEmptyState extends StatelessWidget {
  const _LocalGymEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
        message,
        textAlign: TextAlign.center,
        style: context.yoursText(YoursTextRole.body).copyWith(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

class _LocalGymHeaderCard extends StatelessWidget {
  const _LocalGymHeaderCard({
    required this.session,
    required this.fallbackPlanName,
    required this.elapsedText,
  });

  final LocalGymSessionController session;
  final String fallbackPlanName;
  final String elapsedText;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final day = session.day;
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
            session.plan?.name ?? fallbackPlanName,
            style: context
                .yoursText(YoursTextRole.pageTitle)
                .copyWith(fontSize: 22, color: palette.fg),
          ),
          const SizedBox(height: 4),
          Text(
            dayName,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 14, color: palette.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LocalGymMetric(label: context.l10n.workoutElapsed, value: elapsedText),
              const SizedBox(width: 8),
              _LocalGymMetric(
                label: context.l10n.workoutExercise,
                value: '${session.exerciseIndex + 1}/${session.actions.length}',
              ),
              const SizedBox(width: 8),
              _LocalGymMetric(
                label: context.l10n.homeSets,
                value: '${session.setIndex}/${session.currentTargetSets}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalGymLogCard extends StatelessWidget {
  const _LocalGymLogCard({
    required this.session,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.restCtrl,
    required this.freeWeightCtrl,
    required this.freeDurationCtrl,
    required this.freeRestCtrl,
    required this.actionNoteCtrl,
    required this.onReplaceCurrentExercise,
    required this.onSaveSet,
    required this.onSaveFreeRecord,
    required this.onUndoCurrentSet,
  });

  final LocalGymSessionController session;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController restCtrl;
  final TextEditingController freeWeightCtrl;
  final TextEditingController freeDurationCtrl;
  final TextEditingController freeRestCtrl;
  final TextEditingController actionNoteCtrl;
  final VoidCallback onReplaceCurrentExercise;
  final VoidCallback onSaveSet;
  final VoidCallback onSaveFreeRecord;
  final VoidCallback onUndoCurrentSet;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
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
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 13, color: palette.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          _exerciseNameButton(context),
          const SizedBox(height: 18),
          if (session.isCurrentFreeRecord)
            _freeRecordFields(context)
          else
            _standardSetFields(context),
          if (session.canUndoCurrentSet) ...[
            const SizedBox(height: 10),
            _undoButton(context),
          ],
        ],
      ),
    );
  }

  Widget _exerciseNameButton(BuildContext context) {
    final palette = context.yoursPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
        onTap: onReplaceCurrentExercise,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(
            localizedExerciseName(context, session.currentExercise),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 26, fontWeight: FontWeight.w800, color: palette.fg),
          ),
        ),
      ),
    );
  }

  Widget _freeRecordFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.homeWeightKg,
                controller: freeWeightCtrl,
                decimal: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.workoutDurationSeconds,
                controller: freeDurationCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LocalGymInput(label: context.l10n.workoutRestSeconds, controller: freeRestCtrl),
        const SizedBox(height: 12),
        _LocalGymActionNoteField(
          controller: actionNoteCtrl,
          onChanged: session.updateCurrentSetNote,
        ),
        const SizedBox(height: 18),
        _saveButton(context, onSaveFreeRecord),
      ],
    );
  }

  Widget _standardSetFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.homeWeightKg,
                controller: weightCtrl,
                decimal: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(label: context.l10n.homeReps, controller: repsCtrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(label: context.l10n.workoutRestSeconds, controller: restCtrl),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LocalGymActionNoteField(
          controller: actionNoteCtrl,
          onChanged: session.updateCurrentSetNote,
        ),
        const SizedBox(height: 18),
        _saveButton(context, onSaveSet),
      ],
    );
  }

  Widget _saveButton(BuildContext context, VoidCallback onPressed) {
    final palette = context.yoursPalette;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: session.isSaving ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          session.isSaving ? context.l10n.homeSaving : context.l10n.workoutSaveSet,
          style: context
              .yoursText(YoursTextRole.body)
              .copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _undoButton(BuildContext context) {
    final palette = context.yoursPalette;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onUndoCurrentSet,
        style: TextButton.styleFrom(
          foregroundColor: kRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: palette.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          session.isCurrentFreeRecord
              ? context.l10n.workoutUndoFreeRecord
              : context.l10n.workoutUndoSet,
          style: context
              .yoursText(YoursTextRole.body)
              .copyWith(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _LocalGymRestCard extends StatelessWidget {
  const _LocalGymRestCard({
    required this.session,
    required this.onUndoCurrentSet,
  });

  final LocalGymSessionController session;
  final VoidCallback onUndoCurrentSet;

  @override
  Widget build(BuildContext context) {
    final seconds = session.restRemainingSeconds;
    final restComplete = session.isRestComplete;
    final isLastSet = session.setIndex >= session.currentTargetSets;
    final hasNextExercise = session.exerciseIndex < session.actions.length - 1;
    final nextSet = isLastSet && hasNextExercise ? 1 : session.setIndex + 1;
    final nextExercise = isLastSet && hasNextExercise
        ? session.actions[session.exerciseIndex + 1]
        : session.currentExercise;
    final nextLabel = isLastSet && !hasNextExercise
        ? context.l10n.workoutNextSummary
        : context.l10n.workoutNextSetLabel(
            localizedExerciseName(context, '$nextExercise'),
            nextSet,
          );

    return YoursWorkoutRestPanel(
      label: context.l10n.workoutRestBetween,
      value: restComplete ? context.l10n.commonDone : '${seconds}s',
      nextLabel: nextLabel,
      primaryLabel: restComplete ? context.l10n.workoutNextSet : context.l10n.workoutSkipRest,
      onPrimary: session.advanceAfterRest,
      undoLabel: context.l10n.workoutUndoReturnLog,
      onUndo: onUndoCurrentSet,
      hint: context.l10n.workoutRestHint,
    );
  }
}

class _LocalGymSummaryCard extends StatelessWidget {
  const _LocalGymSummaryCard({
    required this.session,
    required this.sessionNoteCtrl,
    required this.onUndoCurrentSet,
    required this.onFinishSession,
  });

  final LocalGymSessionController session;
  final TextEditingController sessionNoteCtrl;
  final VoidCallback onUndoCurrentSet;
  final Future<void> Function({bool openPoster}) onFinishSession;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.workoutComplete,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 26, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.workoutCompletedMixedSummary(
              session.actions.length,
              session.completedStandardSetCount,
              session.completedFreeRecordCount,
            ),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 14, color: palette.muted),
          ),
          const SizedBox(height: 16),
          _LocalGymSessionNoteField(controller: sessionNoteCtrl),
          const SizedBox(height: 18),
          if (session.canUndoCurrentSet) ...[
            YoursDangerAction(
              label: context.l10n.workoutUndoLastReturnLog,
              onPressed: onUndoCurrentSet,
            ),
            const SizedBox(height: 10),
          ],
          YoursPrimaryAction(label: context.l10n.workoutFinishSave, onPressed: onFinishSession),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: session.isSaving ? null : () => onFinishSession(openPoster: true),
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(context.l10n.sharePosterCreate),
          ),
        ],
      ),
    );
  }
}

class _LocalGymMetric extends StatelessWidget {
  const _LocalGymMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: YoursMetricTile(label: label, value: value, compact: true),
    );
  }
}

part of '../local_gym_mode_page.dart';

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

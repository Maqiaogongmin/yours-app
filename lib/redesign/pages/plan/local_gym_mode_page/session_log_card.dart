part of '../local_gym_mode_page.dart';

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
    required this.onInputChanged,
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
  final VoidCallback onInputChanged;

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
                onChanged: (_) => onInputChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.workoutDurationSeconds,
                controller: freeDurationCtrl,
                onChanged: (_) => onInputChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LocalGymInput(
          label: context.l10n.workoutRestSeconds,
          controller: freeRestCtrl,
          onChanged: (_) => onInputChanged(),
        ),
        const SizedBox(height: 12),
        _LocalGymActionNoteField(
          controller: actionNoteCtrl,
          onChanged: (_) => onInputChanged(),
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
                onChanged: (_) => onInputChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.homeReps,
                controller: repsCtrl,
                onChanged: (_) => onInputChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocalGymInput(
                label: context.l10n.workoutRestSeconds,
                controller: restCtrl,
                onChanged: (_) => onInputChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LocalGymActionNoteField(
          controller: actionNoteCtrl,
          onChanged: (_) => onInputChanged(),
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

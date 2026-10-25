part of '../local_gym_mode_page.dart';

extension _LocalGymReplacementFlow on _LocalGymModePageState {
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
    try {
      await _session.replaceCurrentAction(replacement);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeSaveFailed(localizedErrorDetail(context, error)))),
      );
      return;
    }
    if (!mounted) {
      return;
    }
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
}

part of '../local_gym_mode_page.dart';

class _LocalGymInputBindings {
  final weightCtrl = TextEditingController();
  final repsCtrl = TextEditingController();
  final restCtrl = TextEditingController();
  final freeWeightCtrl = TextEditingController();
  final freeDurationCtrl = TextEditingController();
  final freeRestCtrl = TextEditingController();
  final actionNoteCtrl = TextEditingController();

  int? _lastExerciseIndex;
  int? _lastSetIndex;

  double? get standardWeight => _parseDouble(weightCtrl.text);
  int? get standardReps => _parseInt(repsCtrl.text);
  int? get standardRestSeconds => _parseInt(restCtrl.text);
  double? get freeWeight => _parseDouble(freeWeightCtrl.text);
  int? get freeDurationSeconds => _parseInt(freeDurationCtrl.text);
  int? get freeRestSeconds => _parseInt(freeRestCtrl.text);

  void syncForPosition(LocalGymSessionController session, {bool force = false}) {
    if (!session.hasActions) {
      return;
    }
    final positionChanged =
        _lastExerciseIndex != session.exerciseIndex || _lastSetIndex != session.setIndex;
    if (!force && !positionChanged) {
      return;
    }
    _lastExerciseIndex = session.exerciseIndex;
    _lastSetIndex = session.setIndex;

    final draft = session.currentInputDraft;
    final saved = session.getSavedDataForCurrentSet();
    if (draft != null) {
      weightCtrl.text = draft.weightText;
      repsCtrl.text = draft.repsText;
      restCtrl.text = draft.restText;
      freeWeightCtrl.text = draft.weightText;
      freeDurationCtrl.text = draft.durationText;
      freeRestCtrl.text = draft.restText;
      actionNoteCtrl.text = draft.noteText;
    } else if (saved != null) {
      weightCtrl.text = _formatNullableDouble(saved.weight);
      repsCtrl.text = _formatNullableInt(saved.reps);
      restCtrl.text = _formatNullableInt(saved.restSeconds);
      freeWeightCtrl.text = _formatNullableDouble(saved.weight);
      freeDurationCtrl.text = _formatNullableInt(saved.durationSeconds);
      freeRestCtrl.text = _formatNullableInt(saved.restSeconds);
      actionNoteCtrl.text = session.currentSetNote;
    } else {
      weightCtrl.text = _formatNullableDouble(session.currentTargetWeight);
      repsCtrl.text = _formatNullableInt(session.currentTargetReps);
      restCtrl.text = _formatNullableInt(session.currentTargetRestSeconds);
      freeWeightCtrl.text = _formatNullableDouble(session.currentTargetWeight);
      freeDurationCtrl.text = _formatNullableInt(session.currentAction.targetDurationSeconds);
      freeRestCtrl.text = _formatNullableInt(session.currentTargetRestSeconds);
      actionNoteCtrl.text = session.currentSetNote;
    }
  }

  Future<void> persist(LocalGymSessionController session) {
    return session.updateCurrentInputDraft(
      weightText: session.isCurrentFreeRecord ? freeWeightCtrl.text : weightCtrl.text,
      repsText: session.isCurrentFreeRecord ? '' : repsCtrl.text,
      durationText: session.isCurrentFreeRecord ? freeDurationCtrl.text : '',
      restText: session.isCurrentFreeRecord ? freeRestCtrl.text : restCtrl.text,
      noteText: actionNoteCtrl.text,
    );
  }

  void restore(CompletedSetUndo undo) {
    weightCtrl.text = _formatNullableDouble(undo.weight);
    repsCtrl.text = _formatNullableInt(undo.reps);
    restCtrl.text = _formatNullableInt(undo.restSeconds);
    freeWeightCtrl.text = _formatNullableDouble(undo.weight);
    freeDurationCtrl.text = _formatNullableInt(undo.durationSeconds);
    freeRestCtrl.text = _formatNullableInt(undo.restSeconds);
  }

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
    restCtrl.dispose();
    freeWeightCtrl.dispose();
    freeDurationCtrl.dispose();
    freeRestCtrl.dispose();
    actionNoteCtrl.dispose();
  }

  double? _parseDouble(String value) => double.tryParse(value.trim());
  int? _parseInt(String value) => int.tryParse(value.trim());
  String _formatNullableDouble(double? value) =>
      value == null ? '' : value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  String _formatNullableInt(int? value) => value?.toString() ?? '';
}

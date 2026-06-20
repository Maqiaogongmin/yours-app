part of '../local_gym_mode_page.dart';

class _ReplacementActionSheet extends StatefulWidget {
  const _ReplacementActionSheet({
    required this.title,
    required this.initialAction,
  });

  final String title;
  final LocalTrainingActionModel initialAction;

  @override
  State<_ReplacementActionSheet> createState() => _ReplacementActionSheetState();
}

class _ReplacementActionSheetState extends State<_ReplacementActionSheet> {
  late String _recordMode;
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final action = widget.initialAction;
    _recordMode = normalizeLocalRecordMode(action.recordMode);
    _setsCtrl = TextEditingController(text: action.targetSets.toString());
    _repsCtrl = TextEditingController(text: action.targetReps.toString());
    _weightCtrl = TextEditingController(text: _formatWeight(action.targetWeight));
    _durationCtrl = TextEditingController(text: action.targetDurationSeconds?.toString() ?? '');
    _restCtrl = TextEditingController(text: action.targetRestSeconds?.toString() ?? '');
    _noteCtrl = TextEditingController(text: action.note);
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    _restCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatWeight(double? value) {
    if (value == null) {
      return '';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  int _intValue(TextEditingController controller, int fallback, {int min = 0, int max = 3600}) {
    return (int.tryParse(controller.text.trim()) ?? fallback).clamp(min, max);
  }

  double? _weightValue() {
    final trimmed = _weightCtrl.text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed)?.clamp(0, 9999).toDouble();
  }

  void _confirm() {
    final action = widget.initialAction.copyWith(
      targetSets: _intValue(_setsCtrl, widget.initialAction.targetSets, min: 1, max: 20),
      targetReps: _intValue(_repsCtrl, widget.initialAction.targetReps, min: 1, max: 50),
      targetWeight: _weightValue(),
      clearTargetWeight: _weightCtrl.text.trim().isEmpty,
      targetRestSeconds: _restCtrl.text.trim().isEmpty
          ? null
          : _intValue(_restCtrl, widget.initialAction.targetRestSeconds ?? 0),
      clearTargetRestSeconds: _restCtrl.text.trim().isEmpty,
      targetDurationSeconds: _durationCtrl.text.trim().isEmpty
          ? null
          : _intValue(
              _durationCtrl,
              widget.initialAction.targetDurationSeconds ?? 0,
              max: 24 * 60 * 60,
            ),
      clearTargetDurationSeconds: _durationCtrl.text.trim().isEmpty,
      recordMode: _recordMode,
      note: _noteCtrl.text,
    );
    Navigator.pop(context, action);
  }

  @override
  Widget build(BuildContext context) {
    final isFree = _recordMode == localRecordModeFree;
    return YoursSheetShell(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedExerciseName(context, widget.initialAction.name),
            style: context.yoursText(YoursTextRole.cardTitle),
          ),
          const SizedBox(height: 12),
          YoursSegmentedFilter<String>(
            segments: [
              (localRecordModeStandard, context.l10n.planRecordModeStandard),
              (localRecordModeFree, context.l10n.planRecordModeFree),
            ],
            selected: _recordMode,
            onChanged: (mode) => setState(() => _recordMode = mode),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: YoursFormField(label: context.l10n.homeSets, controller: _setsCtrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: YoursFormField(
                  label: context.l10n.homeWeightKg,
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: YoursFormField(
                  label: isFree ? context.l10n.planDuration : context.l10n.homeReps,
                  controller: isFree ? _durationCtrl : _repsCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: YoursFormField(
                  label: context.l10n.workoutRestSeconds,
                  controller: _restCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          YoursFormField(
            label: context.l10n.workoutNote,
            controller: _noteCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          YoursPrimaryAction(label: context.l10n.commonDone, onPressed: _confirm),
        ],
      ),
    );
  }
}

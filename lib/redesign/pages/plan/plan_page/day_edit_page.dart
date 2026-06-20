part of '../plan_page.dart';

class DayEditPage extends StatefulWidget {
  final TrainingDay editDay;
  final int week, day;

  const DayEditPage({super.key, required this.editDay, required this.week, required this.day});

  @override
  State<DayEditPage> createState() => _DayEditPageState();
}

class _DayEditPageState extends State<DayEditPage> {
  late TextEditingController _nameCtrl;
  late TrainingDay _day;

  @override
  void initState() {
    super.initState();
    _day = widget.editDay.copyWith();
    _nameCtrl = TextEditingController(text: _day.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addAction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExercisePickerPage.multi(selectedActions: _day.actions),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _removeAction(int index) {
    setState(() => _day.actions.removeAt(index));
  }

  void _updateActionTarget(
    int index, {
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    int? durationSeconds,
    String? recordMode,
    String? note,
  }) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(
        targetSets: sets?.clamp(1, 10),
        targetReps: reps?.clamp(1, 50),
        targetWeight: weight,
        targetRestSeconds: restSeconds?.clamp(0, 3600),
        targetDurationSeconds: durationSeconds?.clamp(0, 24 * 60 * 60),
        recordMode: recordMode,
        note: note,
      );
    });
  }

  void _clearActionWeight(int index) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(clearTargetWeight: true);
    });
  }

  void _clearActionRestSeconds(int index) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(clearTargetRestSeconds: true);
    });
  }

  void _clearActionDurationSeconds(int index) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(clearTargetDurationSeconds: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return YoursPageScaffold(
      title: context.l10n.planDayTitle(widget.week, widget.day),
      primaryActionLabel: context.l10n.commonSave,
      onPrimaryAction: () {
        _day.name = _nameCtrl.text;
        Navigator.pop(context, _day);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursFormField(label: context.l10n.planDayName, controller: _nameCtrl),
          YoursPrimaryAction(label: context.l10n.planAddExercise, onPressed: _addAction),
          const SizedBox(height: 14),
          YoursSectionHeader(context.l10n.planActionList(_day.actions.length)),
          const SizedBox(height: 8),

          if (_day.actions.isEmpty)
            _hint(context.l10n.planNoExerciseHint)
          else
            ...List.generate(_day.actions.length, (i) {
              final action = _day.actions[i];
              return YoursSurfaceCard(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        YoursIconBadge(label: '${i + 1}', size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizedExerciseName(context, action.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context
                                .yoursText(YoursTextRole.body)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _removeAction(i),
                          child: Text(
                            context.l10n.planRemove,
                            style: context.yoursText(YoursTextRole.button, tone: YoursTone.danger),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _recordModeSwitch(
                        action.recordMode,
                        (mode) => _updateActionTarget(i, recordMode: mode),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (action.recordMode == localRecordModeFree)
                      _freeTargetInputs(
                        action: action,
                        onSetsChanged: (sets) => _updateActionTarget(i, sets: sets),
                        onWeightChanged: (weight) => _updateActionTarget(i, weight: weight),
                        onWeightCleared: () => _clearActionWeight(i),
                        onDurationChanged: (seconds) =>
                            _updateActionTarget(i, durationSeconds: seconds),
                        onDurationCleared: () => _clearActionDurationSeconds(i),
                        onRestChanged: (seconds) => _updateActionTarget(i, restSeconds: seconds),
                        onRestCleared: () => _clearActionRestSeconds(i),
                      )
                    else
                      _targetInputs(
                        action: action,
                        onSetsChanged: (sets) => _updateActionTarget(i, sets: sets),
                        onRepsChanged: (reps) => _updateActionTarget(i, reps: reps),
                        onWeightChanged: (weight) => _updateActionTarget(i, weight: weight),
                        onWeightCleared: () => _clearActionWeight(i),
                        onRestChanged: (seconds) => _updateActionTarget(i, restSeconds: seconds),
                        onRestCleared: () => _clearActionRestSeconds(i),
                      ),
                    const SizedBox(height: 10),
                    _actionNoteField(
                      initialValue: action.note,
                      onChanged: (note) => _updateActionTarget(i, note: note),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _hint(String text) {
    return YoursEmptyState(message: text, icon: Icons.event_note_outlined);
  }

  Widget _recordModeSwitch(String mode, ValueChanged<String> onChanged) {
    final normalized = normalizeLocalRecordMode(mode);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: YoursSegmentedFilter<String>(
        segments: [
          (localRecordModeStandard, context.l10n.planRecordModeStandard),
          (localRecordModeFree, context.l10n.planRecordModeFree),
        ],
        selected: normalized,
        onChanged: onChanged,
      ),
    );
  }

  Widget _targetInputs({
    required LocalTrainingActionModel action,
    required ValueChanged<int> onSetsChanged,
    required ValueChanged<int> onRepsChanged,
    required ValueChanged<double> onWeightChanged,
    required VoidCallback onWeightCleared,
    required ValueChanged<int> onRestChanged,
    required VoidCallback onRestCleared,
  }) {
    return YoursNotePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _targetNumberField(
            initialValue: action.targetSets,
            suffix: context.l10n.planSetSuffix,
            onChanged: onSetsChanged,
          ),
          Text('×', style: context.yoursText(YoursTextRole.label)),
          _targetNumberField(
            initialValue: action.targetReps,
            suffix: context.l10n.planRepSuffix,
            onChanged: onRepsChanged,
          ),
          _targetWeightField(
            initialValue: action.targetWeight,
            onChanged: onWeightChanged,
            onCleared: onWeightCleared,
          ),
          _targetOptionalIntField(
            initialValue: action.targetRestSeconds,
            hint: context.l10n.planRest,
            suffix: 's',
            width: 58,
            onChanged: onRestChanged,
            onCleared: onRestCleared,
          ),
        ],
      ),
    );
  }

  Widget _freeTargetInputs({
    required LocalTrainingActionModel action,
    required ValueChanged<int> onSetsChanged,
    required ValueChanged<double> onWeightChanged,
    required VoidCallback onWeightCleared,
    required ValueChanged<int> onDurationChanged,
    required VoidCallback onDurationCleared,
    required ValueChanged<int> onRestChanged,
    required VoidCallback onRestCleared,
  }) {
    return YoursNotePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _targetNumberField(
            initialValue: action.targetSets,
            suffix: context.l10n.planSetSuffix,
            onChanged: onSetsChanged,
          ),
          _targetWeightField(
            initialValue: action.targetWeight,
            onChanged: onWeightChanged,
            onCleared: onWeightCleared,
          ),
          _targetOptionalIntField(
            initialValue: action.targetDurationSeconds,
            hint: context.l10n.planDuration,
            suffix: 's',
            width: 72,
            maxValue: 24 * 60 * 60,
            onChanged: onDurationChanged,
            onCleared: onDurationCleared,
          ),
          _targetOptionalIntField(
            initialValue: action.targetRestSeconds,
            hint: context.l10n.planRest,
            suffix: 's',
            width: 58,
            onChanged: onRestChanged,
            onCleared: onRestCleared,
          ),
        ],
      ),
    );
  }

  Widget _targetNumberField({
    required int initialValue,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        initialValue: initialValue.toString(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          isDense: true,
          suffixText: suffix,
          suffixStyle: context.yoursText(YoursTextRole.label),
          hintStyle: context.yoursText(YoursTextRole.bodyMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.trim().isEmpty) {
            return;
          }
          final parsed = int.tryParse(value.trim());
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }

  Widget _targetOptionalIntField({
    required int? initialValue,
    required String hint,
    required String suffix,
    required double width,
    int maxValue = 3600,
    required ValueChanged<int> onChanged,
    required VoidCallback onCleared,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: initialValue?.toString() ?? '',
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          isDense: true,
          suffixText: suffix,
          suffixStyle: context.yoursText(YoursTextRole.label),
          hintText: hint,
          hintStyle: context.yoursText(YoursTextRole.label),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            onCleared();
            return;
          }
          final parsed = int.tryParse(trimmed);
          if (parsed != null) {
            onChanged(parsed.clamp(0, maxValue));
          }
        },
      ),
    );
  }

  Widget _targetWeightField({
    required double? initialValue,
    required ValueChanged<double> onChanged,
    required VoidCallback onCleared,
  }) {
    final text = initialValue == null
        ? ''
        : initialValue.toStringAsFixed(initialValue.truncateToDouble() == initialValue ? 0 : 1);
    return SizedBox(
      width: 62,
      child: TextFormField(
        initialValue: text,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          isDense: true,
          suffixText: 'kg',
          suffixStyle: context.yoursText(YoursTextRole.label),
          hintText: context.l10n.planWeight,
          hintStyle: context.yoursText(YoursTextRole.label),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            onCleared();
            return;
          }
          final parsed = double.tryParse(trimmed);
          if (parsed != null) {
            onChanged(parsed.clamp(0, 9999).toDouble());
          }
        },
      ),
    );
  }

  Widget _actionNoteField({
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: 3,
      style: context.yoursText(YoursTextRole.body),
      decoration: InputDecoration(
        isDense: true,
        hintText: context.l10n.planNoteHint,
        hintStyle: context.yoursText(YoursTextRole.bodyMuted),
        filled: true,
        fillColor: context.yoursSurface(YoursSurfaceRole.panel),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
          borderSide: context.yoursHairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
          borderSide: context.yoursHairline,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

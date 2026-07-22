part of 'exercise_library_page.dart';

class _ExerciseEditorSheet extends StatefulWidget {
  final CustomExerciseModel? exercise;
  final _ExerciseEditorInitialValues initialValues;

  const _ExerciseEditorSheet({this.exercise, required this.initialValues});

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryOneCtrl;
  late final TextEditingController _categoryTwoCtrl;
  late final TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    final values = widget.initialValues;
    _nameCtrl = TextEditingController(text: values.name);
    _categoryOneCtrl = TextEditingController(text: values.categoryOne);
    _categoryTwoCtrl = TextEditingController(text: values.categoryTwo);
    _descriptionCtrl = TextEditingController(text: values.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryOneCtrl.dispose();
    _categoryTwoCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      return;
    }
    final source = widget.exercise;
    Navigator.pop(
      context,
      CustomExerciseModel(
        id: source?.id,
        syncId: source?.syncId,
        remoteId: source?.remoteId,
        chineseName: name,
        englishName: source?.englishName ?? '',
        bodyPart: _categoryOneCtrl.text.trim(),
        equipment: _categoryTwoCtrl.text.trim(),
        primaryMuscles: source?.primaryMuscles ?? '',
        description: _descriptionCtrl.text.trim(),
        imagePaths: source?.imagePaths ?? [],
        isCustom: true,
        syncStatus: source?.syncStatus ?? 'pending',
        deleted: false,
        createdAt: source?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoursSheetShell(
      title: widget.exercise == null ? context.l10n.exerciseAdd : context.l10n.exerciseEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursFormField(
            label: context.l10n.exerciseName,
            controller: _nameCtrl,
            hintText: context.l10n.exerciseExampleName,
          ),
          YoursFieldGroup(
            children: [
              YoursFormField(
                label: context.l10n.exerciseCategoryOne,
                controller: _categoryOneCtrl,
                hintText: context.l10n.exerciseExampleCategory,
              ),
              YoursFormField(
                label: context.l10n.exerciseCategoryTwo,
                controller: _categoryTwoCtrl,
                hintText: context.l10n.exerciseExampleEquipment,
              ),
            ],
          ),
          YoursFormField(
            label: context.l10n.exerciseDescription,
            controller: _descriptionCtrl,
            hintText: context.l10n.exerciseDescription,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          YoursPrimaryAction(
            label: context.l10n.exerciseSaveLocal,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.isEmpty ? context.l10n.exerciseNotFilled : text,
        style: context
            .yoursText(YoursTextRole.body)
            .copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Exercise library page — local-first custom exercise library.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

List<String> _exerciseCategories(CustomExerciseModel exercise) {
  return [
    exercise.bodyPart.trim(),
    exercise.equipment.trim(),
  ].where((category) => category.isNotEmpty).toSet().toList();
}

String _exerciseCategoryText(BuildContext context, CustomExerciseModel exercise) {
  final builtIn = localizedBuiltInExercise(context, exercise);
  if (builtIn != null) {
    return '${builtIn.bodyPart} · ${builtIn.equipment}';
  }
  final categories = _exerciseCategories(exercise);
  return categories.isEmpty
      ? context.l10n.notCategorized
      : categories.map((category) => localizedExerciseCategory(context, category)).join(' · ');
}

String _exerciseSummaryText(BuildContext context, CustomExerciseModel exercise) {
  final builtIn = localizedBuiltInExercise(context, exercise);
  if (builtIn != null) {
    return builtIn.description;
  }
  final description = exercise.description.trim();
  if (description.isNotEmpty) {
    return description;
  }
  final muscles = exercise.primaryMuscles.trim();
  if (muscles.isNotEmpty) {
    return muscles;
  }
  return context.l10n.noDescription;
}

class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key});

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  late final CustomExerciseRepository _repository;
  late Future<void> _initFuture;
  final _searchController = TextEditingController();
  var _activeFilter = '全部';
  var _exercises = <CustomExerciseModel>[];

  List<CustomExerciseModel> _filteredExercises(BuildContext context) {
    final q = _searchController.text.trim().toLowerCase();
    return _exercises.where((exercise) {
      final passFilter =
          _activeFilter == '全部' || _exerciseCategories(exercise).contains(_activeFilter);
      final builtIn = localizedBuiltInExercise(context, exercise);
      final searchableText = [
        exercise.searchableText,
        if (builtIn != null) ...[
          builtIn.name,
          builtIn.bodyPart,
          builtIn.equipment,
          builtIn.primaryMuscles,
          builtIn.description,
        ],
      ].join(' ').toLowerCase();
      final passSearch = q.isEmpty || searchableText.contains(q);
      return passFilter && passSearch;
    }).toList();
  }

  List<String> get _chips {
    final categories = <String>{};
    for (final exercise in _exercises) {
      categories.addAll(_exerciseCategories(exercise));
    }
    return ['全部', ...categories.toList()..sort()];
  }

  @override
  void initState() {
    super.initState();
    _repository = CustomExerciseRepository(locator<CustomExerciseDatabase>());
    _initFuture = _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    await _repository.ensureSeedData();
    _exercises = await _repository.listExercises();
    if (!_chips.contains(_activeFilter)) {
      _activeFilter = '全部';
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _initFuture = _loadExercises();
    });
    await _initFuture;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showEditor({CustomExerciseModel? exercise}) async {
    final result = await showModalBottomSheet<CustomExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseEditorSheet(exercise: exercise),
    );
    if (result == null || !mounted) {
      return;
    }
    await _repository.saveExercise(result);
    await _refresh();
  }

  Future<void> _showDetails(CustomExerciseModel exercise) async {
    final action = await showModalBottomSheet<_ExerciseAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDetailSheet(exercise: exercise),
    );
    if (action == null || !mounted) {
      return;
    }
    if (action == _ExerciseAction.edit) {
      await _showEditor(exercise: exercise);
    }
    if (action == _ExerciseAction.delete) {
      await _repository.deleteExercise(exercise);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        final filteredExercises = _filteredExercises(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kGutter, kGutter, kGutter, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: context.l10n.exerciseLibrary,
                subtitle: context.l10n.exerciseLocalSubtitle,
                onAdd: () => _showEditor(),
              ),
              const SizedBox(height: 4),
              _SearchBar(
                controller: _searchController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              _FilterChips(
                chips: _chips,
                activeFilter: _activeFilter,
                onChanged: (chip) => setState(() => _activeFilter = chip),
              ),
              const SizedBox(height: 14),
              if (filteredExercises.isEmpty)
                _EmptyState(
                  message: _exercises.isEmpty
                      ? context.l10n.exerciseEmpty
                      : context.l10n.exerciseNoMatch,
                )
              else
                ...filteredExercises.map(
                  (exercise) => Padding(
                    key: ValueKey(
                      'exercise-${exercise.id}-${exercise.updatedAt.toIso8601String()}',
                    ),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExerciseCard(
                      exercise: exercise,
                      onTap: () => _showDetails(exercise),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: palette.fg,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: TextStyle(fontSize: 14, color: palette.muted)),
            ],
          ),
          GestureDetector(
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                context.l10n.commonAdd,
                style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: palette.muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              cursorColor: palette.accent,
              style: TextStyle(color: palette.fg, fontSize: 16),
              decoration: InputDecoration(
                hintText: context.l10n.exerciseSearchHint,
                hintStyle: TextStyle(color: palette.muted.withValues(alpha: 0.72)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: palette.muted, shape: BoxShape.circle),
                child: const Center(
                  child: Text('×', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> chips;
  final String activeFilter;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.chips,
    required this.activeFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isActive = chip == activeFilter;
          return GestureDetector(
            onTap: () => onChanged(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? palette.accentSoft : palette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isActive ? palette.accent : palette.border),
              ),
              child: Text(
                chip == '全部' ? context.l10n.all : localizedExerciseCategory(context, chip),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? palette.accent : palette.fg,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
        color: palette.panel,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final CustomExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final categories = _exerciseCategories(exercise);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseThumb(exercise: exercise),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizedBuiltInExercise(context, exercise)?.name ?? exercise.displayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.fg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _exerciseSummaryText(context, exercise),
              style: TextStyle(fontSize: 14, color: palette.muted, height: 1.35),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              _ExerciseTag(label: context.l10n.notCategorized)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    _ExerciseTag(label: localizedExerciseCategory(context, category)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTag extends StatelessWidget {
  final String label;

  const _ExerciseTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.accent),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  final CustomExerciseModel exercise;

  const _ExerciseThumb({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final path = exercise.imagePaths.firstOrNull;
    return Container(
      width: 54,
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: path == null
          ? Center(
              child: Text(
                localizedExerciseAbbr(context, exercise),
                style: TextStyle(color: palette.accent, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            )
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  localizedExerciseAbbr(context, exercise),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
    );
  }
}

enum _ExerciseAction { edit, delete }

class _ExerciseDetailSheet extends StatelessWidget {
  final CustomExerciseModel exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ExerciseThumb(exercise: exercise),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedBuiltInExercise(context, exercise)?.name ?? exercise.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.fg,
                      ),
                    ),
                    if (localizedBuiltInExercise(context, exercise) == null &&
                        exercise.englishName.isNotEmpty)
                      Text(exercise.englishName, style: TextStyle(color: palette.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoPill(text: _exerciseCategoryText(context, exercise)),
          const SizedBox(height: 18),
          Text(
            _exerciseSummaryText(context, exercise),
            style: TextStyle(fontSize: 15, height: 1.55, color: palette.fg),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, _ExerciseAction.edit),
                  style: TextButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    context.l10n.commonEdit,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, _ExerciseAction.delete),
                child: Text(
                  context.l10n.commonDelete,
                  style: TextStyle(color: palette.danger, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseEditorSheet extends StatefulWidget {
  final CustomExerciseModel? exercise;

  const _ExerciseEditorSheet({this.exercise});

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
    final exercise = widget.exercise;
    _nameCtrl = TextEditingController(text: exercise?.chineseName ?? '');
    _categoryOneCtrl = TextEditingController(text: exercise?.bodyPart ?? '');
    _categoryTwoCtrl = TextEditingController(text: exercise?.equipment ?? '');
    _descriptionCtrl = TextEditingController(text: exercise?.description ?? '');
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
    final palette = context.yoursPalette;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise == null ? context.l10n.exerciseAdd : context.l10n.exerciseEdit,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 14),
          _EditorField(
            label: context.l10n.exerciseName,
            controller: _nameCtrl,
            hintText: context.l10n.exerciseExampleName,
          ),
          Row(
            children: [
              Expanded(
                child: _EditorField(
                  label: context.l10n.exerciseCategoryOne,
                  controller: _categoryOneCtrl,
                  hintText: context.l10n.exerciseExampleCategory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditorField(
                  label: context.l10n.exerciseCategoryTwo,
                  controller: _categoryTwoCtrl,
                  hintText: context.l10n.exerciseExampleEquipment,
                ),
              ),
            ],
          ),
          _EditorField(
            label: context.l10n.exerciseDescription,
            controller: _descriptionCtrl,
            hintText: context.l10n.exerciseDescription,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                context.l10n.exerciseSaveLocal,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const _EditorField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: palette.panel,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              cursorColor: palette.accent,
              style: TextStyle(color: palette.fg),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: palette.muted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              ),
            ),
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
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.accent),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final Widget child;

  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

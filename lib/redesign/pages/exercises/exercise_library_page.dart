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
import 'package:yours/redesign/design_system/yours_design_system.dart';
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
  const ExerciseLibraryPage({super.key, this.repository});

  final CustomExerciseRepository? repository;

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
    _repository = widget.repository ?? CustomExerciseRepository(locator<CustomExerciseDatabase>());
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
          padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoursPageHeader(
                title: context.l10n.exerciseLibrary,
                subtitle: context.l10n.exerciseLocalSubtitle,
                trailing: TextButton(
                  key: const ValueKey('exercise-add'),
                  onPressed: () => _showEditor(),
                  child: Text(
                    context.l10n.commonAdd,
                    style: context.yoursText(YoursTextRole.button, tone: YoursTone.accent),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              YoursSearchField(
                key: const ValueKey('exercise-search'),
                controller: _searchController,
                hintText: context.l10n.exerciseSearchHint,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              YoursFilterChipBar<String>(
                key: const ValueKey('exercise-filter'),
                items: _chips,
                selected: _activeFilter,
                labelBuilder: (chip) =>
                    chip == '全部' ? context.l10n.all : localizedExerciseCategory(context, chip),
                onChanged: (chip) => setState(() => _activeFilter = chip),
              ),
              const SizedBox(height: 14),
              if (filteredExercises.isEmpty)
                YoursEmptyState(
                  key: const ValueKey('exercise-empty-state'),
                  message: _exercises.isEmpty
                      ? context.l10n.exerciseEmpty
                      : context.l10n.exerciseNoMatch,
                  icon: Icons.format_list_bulleted_outlined,
                  actionLabel: _exercises.isEmpty ? context.l10n.commonAdd : null,
                  onAction: _exercises.isEmpty ? () => _showEditor() : null,
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

class _ExerciseCard extends StatelessWidget {
  final CustomExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categories = _exerciseCategories(exercise);

    return YoursListActionCard(
      key: ValueKey('exercise-card-${exercise.id ?? exercise.syncId}'),
      onTap: onTap,
      leading: _ExerciseThumb(exercise: exercise),
      title: localizedBuiltInExercise(context, exercise)?.name ?? exercise.displayName,
      subtitle: _exerciseSummaryText(context, exercise),
      status: categories.isEmpty
          ? YoursStatusPill(label: context.l10n.notCategorized)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  YoursStatusPill(label: localizedExerciseCategory(context, category)),
              ],
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
                style: context
                    .yoursText(YoursTextRole.body)
                    .copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
              ),
            )
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  localizedExerciseAbbr(context, exercise),
                  style: context
                      .yoursText(YoursTextRole.body)
                      .copyWith(
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
    final title = localizedBuiltInExercise(context, exercise)?.name ?? exercise.displayName;
    return YoursSheetShell(
      title: title,
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.cardTitle),
                    ),
                    if (localizedBuiltInExercise(context, exercise) == null &&
                        exercise.englishName.isNotEmpty)
                      Text(exercise.englishName, style: context.yoursText(YoursTextRole.bodyMuted)),
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
            style: context.yoursText(YoursTextRole.body).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 22),
          YoursFieldGroup(
            children: [
              YoursPrimaryAction(
                label: context.l10n.commonEdit,
                onPressed: () => Navigator.pop(context, _ExerciseAction.edit),
              ),
              YoursDangerAction(
                label: context.l10n.commonDelete,
                onPressed: () => Navigator.pop(context, _ExerciseAction.delete),
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
          YoursPrimaryAction(label: context.l10n.exerciseSaveLocal, onPressed: _save),
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

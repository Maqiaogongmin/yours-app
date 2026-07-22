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

part 'exercise_library_cards.dart';
part 'exercise_library_detail.dart';
part 'exercise_library_editor.dart';

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

_ExerciseEditorInitialValues _exerciseEditorInitialValues(
  BuildContext context,
  CustomExerciseModel? exercise,
) {
  if (exercise == null) {
    return const _ExerciseEditorInitialValues();
  }
  final builtIn = localizedBuiltInExercise(context, exercise);
  return _ExerciseEditorInitialValues(
    name: builtIn?.name ?? exercise.chineseName,
    categoryOne: builtIn?.bodyPart ?? exercise.bodyPart,
    categoryTwo: builtIn?.equipment ?? exercise.equipment,
    description: builtIn?.description ?? exercise.description,
  );
}

class _ExerciseEditorInitialValues {
  final String name;
  final String categoryOne;
  final String categoryTwo;
  final String description;

  const _ExerciseEditorInitialValues({
    this.name = '',
    this.categoryOne = '',
    this.categoryTwo = '',
    this.description = '',
  });
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
    final initialValues = _exerciseEditorInitialValues(context, exercise);
    final result = await showModalBottomSheet<CustomExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseEditorSheet(
        exercise: exercise,
        initialValues: initialValues,
      ),
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

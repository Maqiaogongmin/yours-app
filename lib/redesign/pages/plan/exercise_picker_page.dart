import 'package:flutter/material.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

class ExercisePickerPage extends StatefulWidget {
  final List<LocalTrainingActionModel>? selectedActions;
  final bool allowMultiple;

  const ExercisePickerPage.multi({
    super.key,
    required this.selectedActions,
  }) : allowMultiple = true;

  const ExercisePickerPage.single({super.key}) : selectedActions = null, allowMultiple = false;

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  late final TextEditingController _ctrl;
  late final CustomExerciseRepository _repository;
  late Future<List<CustomExerciseModel>> _exercisesFuture;
  String _query = '';

  List<LocalTrainingActionModel> get _selectedActions => widget.selectedActions ?? [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _repository = CustomExerciseRepository(locator<CustomExerciseDatabase>());
    _exercisesFuture = _loadExercises();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<List<CustomExerciseModel>> _loadExercises() async {
    await _repository.ensureSeedData();
    return _repository.listExercises();
  }

  void _handleExerciseTap(CustomExerciseModel exercise) {
    if (!widget.allowMultiple) {
      Navigator.pop(context, exercise);
      return;
    }
    final reference = exercise.exerciseReference;
    setState(() {
      if (_selectedActions.any((action) => action.name == reference)) {
        _selectedActions.removeWhere((action) => action.name == reference);
      } else {
        _selectedActions.add(LocalTrainingActionModel(name: reference));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.planAddFromLibrary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.allowMultiple)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  context.l10n.planSelectedCount(_selectedActions.length),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<CustomExerciseModel>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kAccent));
          }

          final q = _query.trim().toLowerCase();
          final exercises = snapshot.data ?? [];
          final filtered = exercises.where((exercise) {
            if (q.isEmpty) {
              return true;
            }
            final builtIn = localizedBuiltInExercise(context, exercise);
            final localizedSearchText = [
              exercise.searchableText,
              if (builtIn != null) ...[
                builtIn.name,
                builtIn.bodyPart,
                builtIn.equipment,
                builtIn.primaryMuscles,
                builtIn.description,
              ],
            ].join(' ').toLowerCase();
            return localizedSearchText.contains(q);
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kGutter, kGutter, kGutter, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(kPillRadius),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: palette.muted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onChanged: (v) => setState(() => _query = v),
                          cursorColor: palette.accent,
                          style: TextStyle(color: palette.fg, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: context.l10n.planSearchLibrary,
                            hintStyle: TextStyle(color: palette.muted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_ctrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(color: palette.muted, shape: BoxShape.circle),
                            child: const Center(
                              child: Text(
                                'x',
                                style: TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.planNoMatchingExercise,
                          style: TextStyle(color: palette.muted),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 28),
                        children: filtered.map((exercise) {
                          final builtIn = localizedBuiltInExercise(context, exercise);
                          final added = _selectedActions.any(
                            (action) => action.name == exercise.exerciseReference,
                          );
                          final summary = [
                            (builtIn?.bodyPart ??
                                    localizedExerciseCategory(context, exercise.bodyPart))
                                .trim(),
                            (builtIn?.equipment ??
                                    localizedExerciseCategory(context, exercise.equipment))
                                .trim(),
                            if ((builtIn?.description ?? exercise.description).trim().isNotEmpty)
                              (builtIn?.description ?? exercise.description).trim()
                            else
                              (builtIn?.primaryMuscles ?? exercise.primaryMuscles).trim(),
                          ].where((value) => value.isNotEmpty).join(' · ');
                          return GestureDetector(
                            onTap: () => _handleExerciseTap(exercise),
                            child: Container(
                              key: ValueKey(exercise.id ?? exercise.displayName),
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                border: Border.all(color: palette.border),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: palette.accentSoft,
                                    child: Text(
                                      localizedExerciseAbbr(context, exercise),
                                      style: TextStyle(
                                        color: palette.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          builtIn?.name ?? exercise.displayName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: palette.fg,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          summary.isEmpty ? context.l10n.notCategorized : summary,
                                          style: TextStyle(fontSize: 12, color: palette.muted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: added
                                          ? palette.success.withValues(alpha: 0.1)
                                          : palette.accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (added) ...[
                                          Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: palette.success,
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          added ? context.l10n.planAdded : context.l10n.commonAdd,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: added ? palette.success : palette.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

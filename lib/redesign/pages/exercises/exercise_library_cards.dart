part of 'exercise_library_page.dart';

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

part of 'exercise_library_page.dart';

enum _ExerciseAction { edit, delete }

class _ExerciseDetailSheet extends StatelessWidget {
  final CustomExerciseModel exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final builtIn = localizedBuiltInExercise(context, exercise);
    final title = builtIn?.name ?? exercise.displayName;
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

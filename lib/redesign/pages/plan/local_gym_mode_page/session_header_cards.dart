part of '../local_gym_mode_page.dart';

class _LocalGymEmptyState extends StatelessWidget {
  const _LocalGymEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.yoursText(YoursTextRole.body).copyWith(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

class _LocalGymHeaderCard extends StatelessWidget {
  const _LocalGymHeaderCard({
    required this.session,
    required this.fallbackPlanName,
    required this.elapsedText,
  });

  final LocalGymSessionController session;
  final String fallbackPlanName;
  final String elapsedText;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final day = session.day;
    final dayName = day == null
        ? context.l10n.workoutDefaultDay
        : '${context.l10n.planDayTitle(day.week, day.day)} · ${day.name}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.plan?.name ?? fallbackPlanName,
            style: context
                .yoursText(YoursTextRole.pageTitle)
                .copyWith(fontSize: 22, color: palette.fg),
          ),
          const SizedBox(height: 4),
          Text(
            dayName,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 14, color: palette.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LocalGymMetric(label: context.l10n.workoutElapsed, value: elapsedText),
              const SizedBox(width: 8),
              _LocalGymMetric(
                label: context.l10n.workoutExercise,
                value: '${session.exerciseIndex + 1}/${session.actions.length}',
              ),
              const SizedBox(width: 8),
              _LocalGymMetric(
                label: context.l10n.homeSets,
                value: '${session.setIndex}/${session.currentTargetSets}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

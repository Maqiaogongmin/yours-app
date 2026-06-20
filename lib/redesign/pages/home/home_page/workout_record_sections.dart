part of '../home_page.dart';

class _WorkoutSessionLogSection extends StatelessWidget {
  final _EditableSessionDraft draft;
  final _EditableLogDraft Function(LocalWorkoutLogEditModel log) draftFor;
  final VoidCallback onEndTimeChanged;
  final ValueChanged<_EditableLogDraft> onDurationChanged;
  final VoidCallback onEmptyDurationChanged;
  final VoidCallback onModeChanged;
  final VoidCallback onSelectExercise;
  final VoidCallback? onDelete;

  const _WorkoutSessionLogSection({
    required this.draft,
    required this.draftFor,
    required this.onEndTimeChanged,
    required this.onDurationChanged,
    required this.onEmptyDurationChanged,
    required this.onModeChanged,
    required this.onSelectExercise,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final session = draft.session;
    final groupedLogs = _groupLogs(session.logs);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inlineSplitTimeFields(
                    context,
                    keyPrefix: 'session-${draft.session.id}-start',
                    hourController: draft.startHourController,
                    minuteController: draft.startMinuteController,
                    onChanged: onEndTimeChanged,
                  ),
                  Text(
                    ' - ',
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: palette.fg,
                        ),
                  ),
                  _inlineSplitTimeFields(
                    context,
                    keyPrefix: 'session-${draft.session.id}-end',
                    hourController: draft.endHourController,
                    minuteController: draft.endMinuteController,
                    onChanged: onEndTimeChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.noteController,
            minLines: 1,
            maxLines: 3,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(color: palette.muted, height: 1.45),
            decoration: InputDecoration(
              hintText: context.l10n.workoutTrainingNote,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 14),
          if (session.logs.isEmpty)
            _EmptySessionEditor(
              draft: draft,
              onDurationChanged: onEmptyDurationChanged,
              onModeChanged: onModeChanged,
              onSelectExercise: onSelectExercise,
            )
          else
            ...groupedLogs.entries.map(
              (entry) => _ExerciseLogSection(
                exerciseName: entry.key,
                logs: entry.value,
                draftFor: draftFor,
                onDurationChanged: onDurationChanged,
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.homeDeleteSessionTitle.replaceAll('？', '')),
              style: OutlinedButton.styleFrom(
                foregroundColor: kRed,
                side: BorderSide(color: kRed.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineSplitTimeFields(
    BuildContext context, {
    required String keyPrefix,
    required TextEditingController hourController,
    required TextEditingController minuteController,
    required VoidCallback onChanged,
  }) {
    return YoursTimeValue(
      keyPrefix: keyPrefix,
      hourController: hourController,
      minuteController: minuteController,
      onChanged: onChanged,
    );
  }

  Map<String, List<LocalWorkoutLogEditModel>> _groupLogs(List<LocalWorkoutLogEditModel> logs) {
    final grouped = <String, List<LocalWorkoutLogEditModel>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.exerciseName, () => []).add(log);
    }
    for (final logs in grouped.values) {
      logs.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    }
    return grouped;
  }
}

class _ExerciseLogSection extends StatelessWidget {
  final String exerciseName;
  final List<LocalWorkoutLogEditModel> logs;
  final _EditableLogDraft Function(LocalWorkoutLogEditModel log) draftFor;
  final ValueChanged<_EditableLogDraft> onDurationChanged;

  const _ExerciseLogSection({
    required this.exerciseName,
    required this.logs,
    required this.draftFor,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedExerciseName(context, exerciseName),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 4),
          Text(
            logs.every((log) => log.recordMode == localRecordModeFree)
                ? context.l10n.homeActivityRecordCount(logs.length)
                : context.l10n.homeRecordCount(logs.length),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 12),
          ...logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogEditCard(
                draft: draftFor(log),
                onDurationChanged: onDurationChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sessionTimeText(BuildContext context, LocalWorkoutSessionEditModel session) {
  final started = _shortTime(session.startedAt);
  final endedAt = session.endedAt;
  if (endedAt == null) {
    return context.l10n.homeStartedAt(started);
  }
  return '$started - ${_shortTime(endedAt)}';
}

String _shortTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

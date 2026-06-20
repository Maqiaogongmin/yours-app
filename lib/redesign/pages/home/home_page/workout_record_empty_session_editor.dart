part of '../home_page.dart';

class _EmptySessionEditor extends StatelessWidget {
  final _EditableSessionDraft draft;
  final VoidCallback onDurationChanged;
  final VoidCallback onModeChanged;
  final VoidCallback onSelectExercise;

  const _EmptySessionEditor({
    required this.draft,
    required this.onDurationChanged,
    required this.onModeChanged,
    required this.onSelectExercise,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursSurfaceCard(
      role: YoursSurfaceRole.card,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onSelectExercise,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      draft.exerciseName.trim().isEmpty
                          ? context.l10n.planAddExercise
                          : localizedExerciseName(context, draft.exerciseName),
                      style: context
                          .yoursText(YoursTextRole.body)
                          .copyWith(
                            fontSize: draft.exerciseName.trim().isEmpty ? 16 : 20,
                            fontWeight: FontWeight.w800,
                            color: draft.exerciseName.trim().isEmpty ? palette.accent : palette.fg,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: palette.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: draft.recordModeOrNull,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n.workoutRecordMode,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: localRecordModeStandard,
                child: Text(context.l10n.planRecordModeStandard),
              ),
              DropdownMenuItem(
                value: localRecordModeFree,
                child: Text(context.l10n.planRecordModeFree),
              ),
            ],
            onChanged: (value) {
              draft.recordModeOrNull = value;
              onModeChanged();
            },
          ),
          if (draft.recordModeOrNull == localRecordModeStandard) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallNumberField(context, context.l10n.homeSets, draft.setController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallNumberField(context, context.l10n.homeReps, draft.repsController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallNumberField(
                    context,
                    context.l10n.homeWeightKg,
                    draft.weightController,
                    decimal: true,
                  ),
                ),
              ],
            ),
          ],
          if (draft.recordModeOrNull == localRecordModeFree) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.workoutActivityElapsed,
                  style: context
                      .yoursText(YoursTextRole.body)
                      .copyWith(
                        fontSize: 12,
                        color: palette.muted,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                _SplitDurationFields(
                  keyPrefix: 'session-duration-${draft.session.id}',
                  hourController: draft.durationHourController,
                  minuteController: draft.durationMinuteController,
                  secondController: draft.durationSecondController,
                  onChanged: onDurationChanged,
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          YoursNotePanel(
            surfaceRole: YoursSurfaceRole.card,
            child: TextField(
              controller: draft.actionNoteController,
              minLines: 1,
              maxLines: 3,
              style: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.fg),
              decoration: InputDecoration(
                hintText: context.l10n.workoutNote,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

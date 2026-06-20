part of '../home_page.dart';

class _LogEditCard extends StatelessWidget {
  final _EditableLogDraft draft;
  final ValueChanged<_EditableLogDraft> onDurationChanged;

  const _LogEditCard({
    required this.draft,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursSurfaceCard(
      role: YoursSurfaceRole.panel,
      padding: const EdgeInsets.all(12),
      child: draft.log.recordMode == localRecordModeFree
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      keyPrefix: 'log-duration-${draft.log.id}',
                      hourController: draft._durationHourCtrl,
                      minuteController: draft._durationMinuteCtrl,
                      secondController: draft._durationSecondCtrl,
                      onChanged: () => onDurationChanged(draft),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _noteField(context),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _miniField(context, context.l10n.homeSets, draft._setCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _miniField(context, context.l10n.homeReps, draft._repsCtrl)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniField(
                        context,
                        context.l10n.homeWeightKg,
                        draft._weightCtrl,
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _noteField(context),
              ],
            ),
    );
  }

  Widget _noteField(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursNotePanel(
      surfaceRole: YoursSurfaceRole.card,
      child: TextField(
        controller: draft._noteCtrl,
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
    );
  }

  Widget _miniField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool decimal = false,
  }) {
    final palette = context.yoursPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            label,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 12, color: palette.muted, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(color: palette.fg, fontWeight: FontWeight.w700),
            cursorColor: palette.accent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

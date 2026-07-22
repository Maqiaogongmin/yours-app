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
    return YoursSurfaceCard(
      role: YoursSurfaceRole.panel,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _formField(context.l10n.homeSets, draft._setCtrl),
          if (draft.log.recordMode != localRecordModeFree) ...[
            _formField(context.l10n.homeReps, draft._repsCtrl),
          ],
          _formField(
            context.l10n.workoutWeight,
            draft._weightCtrl,
            decimal: true,
            hintText: context.l10n.workoutUnitKg,
          ),
          if (draft.log.recordMode == localRecordModeFree) ...[
            Padding(
              padding: EdgeInsets.zero,
              child: YoursInlineFormRow(
                label: context.l10n.workoutActivityElapsed,
                fieldWidthFactor: 0.5,
                field: YoursInlineFormValueSlot(
                  alignment: Alignment.center,
                  minimumWidth: YoursTimeValue.compactThreePartMinimumWidth,
                  child: _SplitDurationFields(
                    keyPrefix: 'log-duration-${draft.log.id}',
                    hourController: draft._durationHourCtrl,
                    minuteController: draft._durationMinuteCtrl,
                    secondController: draft._durationSecondCtrl,
                    onChanged: () => onDurationChanged(draft),
                  ),
                ),
              ),
            ),
          ],
          _formField(
            context.l10n.workoutRest,
            draft._restCtrl,
            hintText: context.l10n.workoutUnitSeconds,
          ),
          _noteField(context),
        ],
      ),
    );
  }

  Widget _formField(
    String label,
    TextEditingController controller, {
    bool decimal = false,
    String? hintText,
  }) {
    return YoursInlineFormField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      hintText: hintText,
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
          hintStyle: context.yoursText(YoursTextRole.bodyMuted),
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
}

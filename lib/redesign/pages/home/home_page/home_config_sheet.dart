part of '../home_page.dart';

class _ConfigSheet extends StatefulWidget {
  final bool showCalendar;
  final void Function(String, bool) onChanged;
  const _ConfigSheet({
    required this.showCalendar,
    required this.onChanged,
  });

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  late bool _calendar;

  @override
  void initState() {
    super.initState();
    _calendar = widget.showCalendar;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.homeDashboardSettings,
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: palette.fg),
                  ),
                  _closeBtn(context, () => Navigator.pop(context)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              child: Column(
                children: [
                  _ToggleRow(
                    label: context.l10n.homeCalendar,
                    value: _calendar,
                    onChanged: (v) => setState(() => _calendar = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _outlinedBtn(
                          context,
                          context.l10n.commonClose,
                          () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _filledBtn(context, context.l10n.commonDone, () {
                          widget.onChanged('calendar', _calendar);
                          Navigator.pop(context);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
          color: palette.panel,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context
                  .yoursText(YoursTextRole.body)
                  .copyWith(fontSize: 14, color: palette.fg),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: context.yoursCardShadow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared mini-widgets
// ═══════════════════════════════════════════════════════════════════════════════

Widget _closeBtn(BuildContext context, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: palette.panel, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '×',
          style: context.yoursText(YoursTextRole.body).copyWith(fontSize: 20, color: palette.fg),
        ),
      ),
    ),
  );
}

Widget _outlinedBtn(BuildContext context, String label, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: palette.panel,
      foregroundColor: palette.fg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Text(
      label,
      style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

Widget _filledBtn(BuildContext context, String label, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: palette.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Text(
      label,
      style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

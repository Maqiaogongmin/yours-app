part of '../local_gym_mode_page.dart';

class _LocalGymInput extends StatelessWidget {
  const _LocalGymInput({
    required this.label,
    required this.controller,
    this.decimal = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: onChanged,
      cursorColor: palette.accent,
      style: context.yoursText(YoursTextRole.body).copyWith(color: palette.fg),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.muted),
        hintStyle: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.subtle),
        filled: true,
        fillColor: palette.panel,
        border: _border(palette.border),
        enabledBorder: _border(palette.border),
        focusedBorder: _border(palette.accent),
      ),
    );
  }
}

class _LocalGymActionNoteField extends StatelessWidget {
  const _LocalGymActionNoteField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      onChanged: onChanged,
      cursorColor: palette.accent,
      style: context.yoursText(YoursTextRole.body).copyWith(color: palette.fg),
      decoration: InputDecoration(
        labelText: context.l10n.workoutNote,
        hintText: context.l10n.workoutNoteHint,
        labelStyle: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.muted),
        hintStyle: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.subtle),
        filled: true,
        fillColor: palette.panel,
        border: _border(palette.border),
        enabledBorder: _border(palette.border),
        focusedBorder: _border(palette.accent),
      ),
    );
  }
}

class _LocalGymSessionNoteField extends StatelessWidget {
  const _LocalGymSessionNoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      cursorColor: palette.accent,
      style: context.yoursText(YoursTextRole.body).copyWith(color: palette.fg),
      decoration: InputDecoration(
        labelText: context.l10n.workoutTrainingNote,
        labelStyle: context.yoursText(YoursTextRole.bodyMuted).copyWith(color: palette.muted),
        filled: true,
        fillColor: palette.panel,
        border: _border(palette.border),
        enabledBorder: _border(palette.border),
        focusedBorder: _border(palette.accent),
      ),
    );
  }
}

OutlineInputBorder _border(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color),
  );
}

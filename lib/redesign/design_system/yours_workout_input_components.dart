part of 'yours_components.dart';

class _YoursTimePartField extends StatelessWidget {
  const _YoursTimePartField({
    required this.fieldKey,
    required this.controller,
    required this.maxValue,
    required this.onChanged,
    required this.compact,
    required this.textRole,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final int maxValue;
  final VoidCallback onChanged;
  final bool compact;
  final YoursTextRole textRole;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      width: compact ? 32 : 38,
      height: compact ? 34 : 38,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: context.yoursSurface(YoursSurfaceRole.panel),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.compactInput)),
      ),
      alignment: Alignment.center,
      child: TextField(
        key: fieldKey,
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          _YoursBoundedTwoDigitInputFormatter(maxValue),
        ],
        maxLength: 2,
        textAlign: TextAlign.center,
        style: context.yoursText(textRole),
        decoration: InputDecoration(
          hintText: '00',
          hintStyle: context
              .yoursText(textRole)
              .copyWith(color: palette.muted.withValues(alpha: 0.45)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _YoursTimeSeparator extends StatelessWidget {
  const _YoursTimeSeparator({required this.textRole});

  final YoursTextRole textRole;

  @override
  Widget build(BuildContext context) {
    return Text(':', style: context.yoursText(textRole, tone: YoursTone.muted));
  }
}

class YoursWorkoutInputGroup extends StatelessWidget {
  const YoursWorkoutInputGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class YoursPrimaryAction extends StatelessWidget {
  const YoursPrimaryAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: context.yoursPalette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.button)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: context.yoursText(YoursTextRole.button).copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class YoursTonalAction extends StatelessWidget {
  const YoursTonalAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.yoursTone(YoursTone.accent);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: context.yoursSurface(YoursSurfaceRole.controlOverlay),
          foregroundColor: accent,
          disabledForegroundColor: context.yoursSurfaceMuted(YoursSurfaceRole.controlOverlay),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.button)),
            side: BorderSide(color: context.yoursSurfaceBorder(YoursSurfaceRole.controlOverlay)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class YoursDangerAction extends StatelessWidget {
  const YoursDangerAction({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.yoursPalette.danger,
            side: BorderSide(color: context.yoursPalette.danger.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: context.yoursPalette.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.button)),
            side: BorderSide(color: context.yoursPalette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: context.yoursText(YoursTextRole.button, tone: YoursTone.danger),
          ),
        ),
      ),
    );
  }
}

class _YoursBoundedTwoDigitInputFormatter extends TextInputFormatter {
  const _YoursBoundedTwoDigitInputFormatter(this.maxValue);

  final int maxValue;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }
    return newValue;
  }
}

part of 'yours_components.dart';

class YoursFormField extends StatelessWidget {
  const YoursFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.suffixText,
    this.inputFormatters,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursSectionHeader(label),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            maxLines: maxLines,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            cursorColor: palette.accent,
            style: context.yoursText(YoursTextRole.body),
            decoration: InputDecoration(
              hintText: hintText,
              suffixText: suffixText,
              hintStyle: context.yoursText(YoursTextRole.bodyMuted),
              suffixStyle: context.yoursText(YoursTextRole.label),
              filled: true,
              fillColor: context.yoursSurface(YoursSurfaceRole.panel),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
                borderSide: BorderSide(color: palette.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class YoursInlineFormRow extends StatelessWidget {
  const YoursInlineFormRow({
    super.key,
    required this.label,
    required this.field,
    this.fieldWidthFactor = 0.42,
  });

  final String label;
  final Widget field;
  final double fieldWidthFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [YoursSectionHeader(label), field],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(label, style: context.yoursText(YoursTextRole.label)),
              ),
              SizedBox(width: constraints.maxWidth * fieldWidthFactor, child: field),
            ],
          );
        },
      ),
    );
  }
}

class YoursInlineFormField extends StatelessWidget {
  const YoursInlineFormField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onChanged,
    this.hintText,
    this.fieldWidthFactor = 0.5,
    this.inputWidthFactor = 0.74,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final double fieldWidthFactor;
  final double inputWidthFactor;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursInlineFormRow(
      label: label,
      fieldWidthFactor: fieldWidthFactor,
      field: YoursInlineFormValueSlot(
        widthFactor: inputWidthFactor,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          cursorColor: palette.accent,
          textAlign: TextAlign.center,
          style: context.yoursText(YoursTextRole.body),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.yoursText(YoursTextRole.bodyMuted),
            filled: true,
            fillColor: context.yoursSurface(YoursSurfaceRole.panel),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
              borderSide: BorderSide(color: palette.accent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          ),
        ),
      ),
    );
  }
}

class YoursInlineFormValueSlot extends StatelessWidget {
  const YoursInlineFormValueSlot({
    super.key,
    required this.child,
    this.widthFactor = 0.74,
    this.alignment = Alignment.centerRight,
    this.minimumWidth,
  });

  final Widget child;
  final double widthFactor;
  final AlignmentGeometry alignment;
  final double? minimumWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final preferredWidth = constraints.maxWidth * widthFactor;
        final minimum = minimumWidth;
        final laneWidth = minimum == null || preferredWidth >= minimum ? preferredWidth : minimum;
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: laneWidth,
            child: Align(alignment: alignment, child: child),
          ),
        );
      },
    );
  }
}

class YoursFieldGroup extends StatelessWidget {
  const YoursFieldGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked = constraints.maxWidth < 360 || textScale >= 1.3;
        if (stacked) {
          return Column(children: children);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class YoursInfoRow extends StatelessWidget {
  const YoursInfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.onTap,
    this.tone = YoursTone.accent,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final YoursTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursIconBadge(icon: icon, size: 38, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.yoursText(YoursTextRole.cardTitle).copyWith(fontSize: 16),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(detail!, style: context.yoursText(YoursTextRole.bodyMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return InkWell(onTap: onTap, child: content);
  }
}

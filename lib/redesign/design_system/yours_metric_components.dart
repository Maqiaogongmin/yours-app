part of 'yours_components.dart';

class YoursStatBlock extends StatelessWidget {
  const YoursStatBlock({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.tone,
  });

  final String label;
  final String value;
  final String? detail;
  final YoursTone? tone;

  @override
  Widget build(BuildContext context) {
    return YoursNotePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.label),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.cardTitle, tone: tone),
          ),
          if (detail != null) ...[
            const SizedBox(height: 3),
            Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.yoursText(YoursTextRole.bodyMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class YoursSummaryCard extends StatelessWidget {
  const YoursSummaryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.note,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<YoursStatBlock> metrics;
  final String? note;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.cardTitle),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!, style: context.yoursText(YoursTextRole.bodyMuted)),
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            YoursActionGroup(children: metrics),
          ],
          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            YoursNotePanel(child: Text(note!, style: context.yoursText(YoursTextRole.body))),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            YoursActionGroup(children: actions),
          ],
        ],
      ),
    );
  }
}

class YoursMetricTile extends StatelessWidget {
  const YoursMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.tone,
    this.compact = false,
  });

  final String label;
  final String value;
  final YoursTone? tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: context.yoursSurface(YoursSurfaceRole.panel),
        border: Border.all(color: context.yoursPalette.border),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.yoursText(YoursTextRole.metric, tone: tone)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.label),
          ),
        ],
      ),
    );
  }
}

class YoursStatusPill extends StatelessWidget {
  const YoursStatusPill({super.key, required this.label, this.tone = YoursTone.accent});

  final String label;
  final YoursTone tone;

  @override
  Widget build(BuildContext context) {
    final color = context.yoursTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.status)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.yoursText(YoursTextRole.label, tone: tone),
      ),
    );
  }
}

class YoursNotePanel extends StatelessWidget {
  const YoursNotePanel({
    super.key,
    required this.child,
    this.surfaceRole = YoursSurfaceRole.panel,
    this.padding,
  });

  final Widget child;
  final YoursSurfaceRole surfaceRole;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.yoursSurface(surfaceRole),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
        border: surfaceRole == YoursSurfaceRole.panel
            ? null
            : Border.all(color: context.yoursPalette.border),
      ),
      child: child,
    );
  }
}

class YoursTimeValue extends StatelessWidget {
  static const compactThreePartMinimumWidth = 136.0;

  const YoursTimeValue({
    super.key,
    required this.keyPrefix,
    required this.hourController,
    required this.minuteController,
    this.secondController,
    required this.onChanged,
    this.hourMax = 23,
    this.compact = true,
    this.textRole = YoursTextRole.time,
  });

  final String keyPrefix;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController? secondController;
  final VoidCallback onChanged;
  final int hourMax;
  final bool compact;
  final YoursTextRole textRole;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _YoursTimePartField(
        fieldKey: ValueKey('$keyPrefix-hours'),
        controller: hourController,
        maxValue: hourMax,
        onChanged: onChanged,
        compact: compact,
        textRole: textRole,
      ),
      _YoursTimeSeparator(textRole: textRole),
      _YoursTimePartField(
        fieldKey: ValueKey('$keyPrefix-minutes'),
        controller: minuteController,
        maxValue: 59,
        onChanged: onChanged,
        compact: compact,
        textRole: textRole,
      ),
    ];
    final seconds = secondController;
    if (seconds != null) {
      children.add(_YoursTimeSeparator(textRole: textRole));
      children.add(
        _YoursTimePartField(
          fieldKey: ValueKey('$keyPrefix-seconds'),
          controller: seconds,
          maxValue: 59,
          onChanged: onChanged,
          compact: compact,
          textRole: textRole,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class YoursIconBadge extends StatelessWidget {
  const YoursIconBadge({
    super.key,
    this.icon,
    this.label,
    this.size = 44,
    this.tone = YoursTone.accent,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final double size;
  final YoursTone tone;

  @override
  Widget build(BuildContext context) {
    final color = context.yoursTone(tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
      ),
      child: icon == null
          ? Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context
                  .yoursText(YoursTextRole.cardTitle, tone: tone)
                  .copyWith(fontSize: size <= 44 ? 16 : 20),
            )
          : Icon(icon, color: color, size: size <= 44 ? 22 : 26),
    );
  }
}

part of 'yours_components.dart';

enum YoursStatusPanelLayout { auto, compactGrid }

enum YoursComponentDensity { regular, compact }

class YoursAsyncStatusPanel extends StatelessWidget {
  const YoursAsyncStatusPanel({
    super.key,
    required this.title,
    required this.items,
    this.busy = false,
    this.layout = YoursStatusPanelLayout.auto,
  });

  final String title;
  final List<(String, String, YoursTone)> items;
  final bool busy;
  final YoursStatusPanelLayout layout;

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              YoursIconBadge(
                icon: busy ? Icons.hourglass_top_rounded : Icons.shield_outlined,
                tone: busy ? YoursTone.warning : YoursTone.accent,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: context.yoursText(YoursTextRole.cardTitle))),
            ],
          ),
          const SizedBox(height: 14),
          _StatusPanelItems(items: items, layout: layout),
        ],
      ),
    );
  }
}

class _StatusPanelItems extends StatelessWidget {
  const _StatusPanelItems({required this.items, required this.layout});

  final List<(String, String, YoursTone)> items;
  final YoursStatusPanelLayout layout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactGrid =
            layout == YoursStatusPanelLayout.compactGrid &&
            constraints.maxWidth >= 260 &&
            textScale < 1.3;
        if (compactGrid) {
          const gap = 8.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _StatusPanelItem(item: item, compact: true),
                ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 126, maxWidth: 220),
                child: _StatusPanelItem(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _StatusPanelItem extends StatelessWidget {
  const _StatusPanelItem({required this.item, this.compact = false});

  final (String, String, YoursTone) item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return YoursNotePanel(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 9 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.label),
          ),
          const SizedBox(height: 4),
          Text(
            item.$2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.yoursText(YoursTextRole.body, tone: item.$3),
          ),
        ],
      ),
    );
  }
}

class YoursActionGroup extends StatelessWidget {
  const YoursActionGroup({super.key, required this.children, this.gap = 10});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final minReadableWidth = textScale >= 1.2 ? 168.0 : 152.0;
        final maxColumns = ((constraints.maxWidth + gap) / (minReadableWidth + gap)).floor().clamp(
          1,
          children.length,
        );
        if (maxColumns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: gap),
              ],
            ],
          );
        }
        if (textScale >= 1.2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: gap),
              ],
            ],
          );
        }
        if (children.length <= 2 && constraints.maxWidth / children.length >= minReadableWidth) {
          return Row(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index != children.length - 1) SizedBox(width: gap),
              ],
            ],
          );
        }
        final childWidth = (constraints.maxWidth - gap * (maxColumns - 1)) / maxColumns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: childWidth, child: child),
          ],
        );
      },
    );
  }
}

class YoursManagementAction extends StatelessWidget {
  const YoursManagementAction({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.tone = YoursTone.accent,
    this.busy = false,
    this.enabled = true,
    this.density = YoursComponentDensity.regular,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final YoursTone tone;
  final bool busy;
  final bool enabled;
  final YoursComponentDensity density;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !busy && onTap != null;
    final color = context.yoursTone(tone);
    final compact = density == YoursComponentDensity.compact;
    return Semantics(
      button: true,
      enabled: canTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
            onTap: canTap ? onTap : null,
            child: Container(
              constraints: BoxConstraints(minHeight: compact ? 46 : 52),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 11 : 12,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  if (busy)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  else
                    Icon(icon, color: color, size: compact ? 19 : 21),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.yoursText(YoursTextRole.button, tone: tone),
                          ),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

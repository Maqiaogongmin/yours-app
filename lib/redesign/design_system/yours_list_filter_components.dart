part of 'yours_components.dart';

class YoursListActionCard extends StatelessWidget {
  const YoursListActionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    this.leading,
    this.trailing,
    this.onTap,
    this.status,
    this.shadow = false,
    this.minHeight,
    this.enabled = true,
    this.busy = false,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final String? detail;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? status;
  final bool shadow;
  final double? minHeight;
  final bool enabled;
  final bool busy;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !busy && onTap != null;
    final effectiveTrailing = busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : trailing;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.cardTitle),
                    ),
                  ),
                  if (effectiveTrailing != null) ...[
                    const SizedBox(width: 8),
                    effectiveTrailing,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.yoursText(YoursTextRole.bodyMuted),
                ),
              ],
              if (status != null || detail != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ?status,
                    if (detail != null)
                      Text(
                        detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.yoursText(YoursTextRole.label),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (effectiveTrailing == null && canTap && showChevron) ...[
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: context.yoursPalette.muted),
        ],
      ],
    );

    return Semantics(
      button: onTap != null,
      enabled: enabled && !busy,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.5,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight ?? 76),
          child: YoursSurfaceCard(
            onTap: canTap ? onTap : null,
            shadow: shadow,
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ),
      ),
    );
  }
}

class YoursSearchField extends StatelessWidget {
  const YoursSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.yoursSurface(YoursSurfaceRole.card),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: palette.muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              cursorColor: palette.accent,
              style: context.yoursText(YoursTextRole.body).copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: context
                    .yoursText(YoursTextRole.bodyMuted)
                    .copyWith(color: palette.muted.withValues(alpha: 0.72)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
              onPressed: () {
                controller.clear();
                onChanged();
              },
              visualDensity: VisualDensity.compact,
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: palette.muted, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class YoursFilterChipBar<T> extends StatelessWidget {
  const YoursFilterChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> items;
  final T selected;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isActive = item == selected;
          return Builder(
            builder: (chipContext) {
              return Semantics(
                button: true,
                selected: isActive,
                child: GestureDetector(
                  onTap: () {
                    Scrollable.ensureVisible(
                      chipContext,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 180),
                    );
                    onChanged(item);
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? palette.accentSoft : palette.surface,
                      borderRadius: BorderRadius.circular(
                        context.yoursRadius(YoursRadiusRole.status),
                      ),
                      border: Border.all(color: isActive ? palette.accent : palette.border),
                    ),
                    child: Text(
                      labelBuilder(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context
                          .yoursText(YoursTextRole.body, tone: isActive ? YoursTone.accent : null)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class YoursEmptyState extends StatelessWidget {
  const YoursEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : assert(actionLabel == null || onAction != null);

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      role: YoursSurfaceRole.panel,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            YoursIconBadge(icon: icon, tone: YoursTone.muted),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.yoursText(YoursTextRole.bodyMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: context.yoursText(YoursTextRole.button, tone: YoursTone.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class YoursSegmentedFilter<T> extends StatelessWidget {
  const YoursSegmentedFilter({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SegmentedButton<T>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accentSoft;
          }
          return palette.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent;
          }
          return palette.fg;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent;
          }
          return palette.muted;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? palette.accent : palette.border;
          return BorderSide(color: color, width: 1.2);
        }),
      ),
      segments: [
        for (final segment in segments) ButtonSegment(value: segment.$1, label: Text(segment.$2)),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

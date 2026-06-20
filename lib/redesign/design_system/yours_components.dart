library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/design_system/yours_design_tokens.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

class YoursPageHeader extends StatelessWidget {
  const YoursPageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.yoursText(YoursTextRole.pageTitle)),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: context.yoursText(YoursTextRole.bodyMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class YoursSurfaceCard extends StatelessWidget {
  const YoursSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.role = YoursSurfaceRole.card,
    this.padding,
    this.margin,
    this.shadow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final YoursSurfaceRole role;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(context.yoursRadius(YoursRadiusRole.card));
    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? context.yoursPadding(YoursSpacingRole.cardPadding),
      decoration: BoxDecoration(
        color: context.yoursSurface(role),
        borderRadius: borderRadius,
        border: Border.all(color: context.yoursSurfaceBorder(role)),
        boxShadow: shadow ? context.yoursCardShadow : null,
      ),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
    );
  }
}

class YoursPageScaffold extends StatelessWidget {
  const YoursPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.padding,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: context.yoursSurface(YoursSurfaceRole.page),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: onClose ?? () => Navigator.maybePop(context),
                    icon: Icon(Icons.close_rounded, color: palette.fg),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.cardTitle),
                    ),
                  ),
                  if (primaryActionLabel == null)
                    const SizedBox(width: 48)
                  else
                    TextButton(
                      onPressed: onPrimaryAction,
                      child: Text(
                        primaryActionLabel!,
                        style: context.yoursText(YoursTextRole.button, tone: YoursTone.accent),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            Expanded(
              child: ListView(
                padding: padding ?? context.yoursPadding(YoursSpacingRole.pageInset),
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YoursSheetShell extends StatelessWidget {
  const YoursSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: context.yoursSurface(YoursSurfaceRole.elevated),
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.sheet)),
        border: Border.all(color: palette.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.pageTitle).copyWith(fontSize: 22),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class YoursSectionHeader extends StatelessWidget {
  const YoursSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.yoursText(YoursTextRole.label),
      ),
    );
  }
}

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
  const YoursTimeValue({
    super.key,
    required this.keyPrefix,
    required this.hourController,
    required this.minuteController,
    this.secondController,
    required this.onChanged,
    this.hourMax = 23,
    this.compact = true,
  });

  final String keyPrefix;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController? secondController;
  final VoidCallback onChanged;
  final int hourMax;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _YoursTimePartField(
        fieldKey: ValueKey('$keyPrefix-hours'),
        controller: hourController,
        maxValue: hourMax,
        onChanged: onChanged,
        compact: compact,
      ),
      const _YoursTimeSeparator(),
      _YoursTimePartField(
        fieldKey: ValueKey('$keyPrefix-minutes'),
        controller: minuteController,
        maxValue: 59,
        onChanged: onChanged,
        compact: compact,
      ),
    ];
    final seconds = secondController;
    if (seconds != null) {
      children.add(const _YoursTimeSeparator());
      children.add(
        _YoursTimePartField(
          fieldKey: ValueKey('$keyPrefix-seconds'),
          controller: seconds,
          maxValue: 59,
          onChanged: onChanged,
          compact: compact,
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

class _YoursTimePartField extends StatelessWidget {
  const _YoursTimePartField({
    required this.fieldKey,
    required this.controller,
    required this.maxValue,
    required this.onChanged,
    required this.compact,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final int maxValue;
  final VoidCallback onChanged;
  final bool compact;

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
        style: context.yoursText(YoursTextRole.time),
        decoration: InputDecoration(
          hintText: '00',
          hintStyle: context
              .yoursText(YoursTextRole.time)
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
  const _YoursTimeSeparator();

  @override
  Widget build(BuildContext context) {
    return Text(':', style: context.yoursText(YoursTextRole.time, tone: YoursTone.muted));
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
          child: Text(label, style: context.yoursText(YoursTextRole.button, tone: YoursTone.danger)),
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

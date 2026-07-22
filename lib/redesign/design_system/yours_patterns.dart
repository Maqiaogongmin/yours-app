library;

import 'package:flutter/material.dart';
import 'package:yours/redesign/design_system/yours_components.dart';
import 'package:yours/redesign/design_system/yours_design_tokens.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

class YoursMetricRow extends StatelessWidget {
  const YoursMetricRow({super.key, required this.items});

  final List<YoursMetricTile> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: items[index]),
          if (index != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class YoursWorkoutRestPanel extends StatelessWidget {
  const YoursWorkoutRestPanel({
    super.key,
    required this.label,
    required this.value,
    required this.nextLabel,
    required this.primaryLabel,
    required this.onPrimary,
    required this.undoLabel,
    required this.onUndo,
    this.hint,
  });

  final String label;
  final String value;
  final String nextLabel;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String undoLabel;
  final VoidCallback onUndo;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Text(label, style: context.yoursText(YoursTextRole.label)),
          const SizedBox(height: 14),
          Container(
            width: 156,
            height: 156,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(color: palette.accent.withValues(alpha: 0.18), width: 8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: context
                    .yoursText(YoursTextRole.metric, tone: YoursTone.accent)
                    .copyWith(fontSize: 38),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nextLabel,
            textAlign: TextAlign.center,
            style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          YoursPrimaryAction(label: primaryLabel, onPressed: onPrimary),
          const SizedBox(height: 10),
          YoursDangerAction(label: undoLabel, onPressed: onUndo),
          if (hint != null && hint!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: context.yoursText(YoursTextRole.bodyMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class YoursRecordCardPattern extends StatelessWidget {
  const YoursRecordCardPattern({
    super.key,
    required this.title,
    this.subtitle,
    required this.metrics,
    this.note,
    this.status,
    this.trailingAction,
    this.preferInlineMetrics = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final List<YoursStatBlock> metrics;
  final String? note;
  final Widget? status;
  final Widget? trailingAction;
  final bool preferInlineMetrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      onTap: onTap,
      shadow: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                          const SizedBox(height: 4),
                          Text(subtitle!, style: context.yoursText(YoursTextRole.bodyMuted)),
                        ],
                      ],
                    ),
                  ),
                  if (status != null) ...[const SizedBox(width: 10), status!],
                  if (trailingAction != null) const SizedBox(width: 34),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (preferInlineMetrics)
                  _YoursRecordMetricGroup(children: metrics)
                else
                  YoursActionGroup(children: metrics),
              ],
              if (note != null && note!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                YoursNotePanel(child: Text(note!, style: context.yoursText(YoursTextRole.body))),
              ],
            ],
          ),
          if (trailingAction != null)
            PositionedDirectional(
              top: -8,
              end: -8,
              child: trailingAction!,
            ),
        ],
      ),
    );
  }
}

class _YoursRecordMetricGroup extends StatelessWidget {
  const _YoursRecordMetricGroup({required this.children});

  final List<YoursStatBlock> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked = constraints.maxWidth < 300 || textScale >= 1.45;
        if (stacked) {
          return YoursActionGroup(children: children);
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

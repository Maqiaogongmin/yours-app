import 'package:flutter/material.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

class YoursResponsiveActionButton extends StatelessWidget {
  const YoursResponsiveActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final enabled = onTap != null;
    final foreground = danger ? palette.danger : palette.accent;
    final effectiveForeground = enabled ? foreground : palette.muted;

    return Material(
      color: enabled ? foreground.withValues(alpha: 0.09) : palette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enabled ? foreground.withValues(alpha: 0.25) : palette.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: effectiveForeground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      color: effectiveForeground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

library;

import 'package:flutter/material.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

enum YoursTone { accent, danger, success, warning, muted }

enum YoursSurfaceRole { page, card, panel, elevated, danger, controlOverlay }

enum YoursTextRole {
  pageTitle,
  cardTitle,
  body,
  bodyMuted,
  label,
  metric,
  time,
  button,
}

enum YoursRadiusRole { card, input, compactInput, button, status, sheet }

enum YoursSpacingRole { pageInset, cardPadding, componentGap, compactGap, formGap }

extension YoursDesignTokenContext on BuildContext {
  Color yoursTone(YoursTone tone) {
    final palette = yoursPalette;
    return switch (tone) {
      YoursTone.accent => palette.accent,
      YoursTone.danger => palette.danger,
      YoursTone.success => palette.success,
      YoursTone.warning => palette.warn,
      YoursTone.muted => palette.muted,
    };
  }

  Color yoursSurface(YoursSurfaceRole role) {
    final palette = yoursPalette;
    return switch (role) {
      YoursSurfaceRole.page => palette.bg,
      YoursSurfaceRole.card => palette.surface,
      YoursSurfaceRole.panel => palette.panel,
      YoursSurfaceRole.elevated => palette.elevated,
      YoursSurfaceRole.danger => palette.danger.withValues(alpha: 0.08),
      YoursSurfaceRole.controlOverlay =>
        palette.brightness == Brightness.light ? const Color(0xFFF1E8DD) : palette.surface,
    };
  }

  Color yoursSurfaceForeground(YoursSurfaceRole role) {
    final palette = yoursPalette;
    return switch (role) {
      YoursSurfaceRole.controlOverlay =>
        palette.brightness == Brightness.light ? const Color(0xFF3D342D) : palette.fg,
      _ => palette.fg,
    };
  }

  Color yoursSurfaceMuted(YoursSurfaceRole role) {
    final palette = yoursPalette;
    return switch (role) {
      YoursSurfaceRole.controlOverlay =>
        palette.brightness == Brightness.light ? const Color(0xFF84786D) : palette.muted,
      _ => palette.muted,
    };
  }

  Color yoursSurfaceBorder(YoursSurfaceRole role) {
    final palette = yoursPalette;
    return switch (role) {
      YoursSurfaceRole.controlOverlay =>
        palette.brightness == Brightness.light ? const Color(0xFFE1D4C6) : palette.border,
      _ => palette.border,
    };
  }

  Color get yoursSharePreviewMatte {
    final palette = yoursPalette;
    return palette.brightness == Brightness.light
        ? const Color(0xFFEDE4D8)
        : const Color(0xFF101015);
  }

  double yoursBrandMarkRadius(double size) => size * 0.2237;

  TextStyle yoursText(YoursTextRole role, {YoursTone? tone}) {
    final palette = yoursPalette;
    final color = tone == null
        ? switch (role) {
            YoursTextRole.bodyMuted || YoursTextRole.label => palette.muted,
            _ => palette.fg,
          }
        : yoursTone(tone);
    return switch (role) {
      YoursTextRole.pageTitle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.08,
      ),
      YoursTextRole.cardTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.18,
      ),
      YoursTextRole.body => TextStyle(fontSize: 14, color: color, height: 1.45),
      YoursTextRole.bodyMuted => TextStyle(fontSize: 13, color: color, height: 1.35),
      YoursTextRole.label => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      ),
      YoursTextRole.metric => TextStyle(
        fontFamily: 'RobotoCondensed',
        fontSize: 20,
        fontVariations: const [FontVariation('wght', 800)],
        color: color,
        height: 1.05,
        letterSpacing: 0,
      ),
      YoursTextRole.time => TextStyle(
        fontFamily: 'RobotoCondensed',
        fontSize: 16,
        fontVariations: const [FontVariation('wght', 700)],
        color: color,
        height: 1,
        letterSpacing: 0,
      ),
      YoursTextRole.button => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      ),
    };
  }

  TextStyle yoursTextOnSurface(YoursSurfaceRole surface, YoursTextRole role, {YoursTone? tone}) {
    final color = tone == null
        ? switch (role) {
            YoursTextRole.bodyMuted || YoursTextRole.label => yoursSurfaceMuted(surface),
            _ => yoursSurfaceForeground(surface),
          }
        : yoursTone(tone);
    return yoursText(role).copyWith(color: color);
  }

  double yoursRadius(YoursRadiusRole role) {
    final radii = yoursRadii;
    return switch (role) {
      YoursRadiusRole.card => radii.xl,
      YoursRadiusRole.input => radii.md,
      YoursRadiusRole.compactInput => radii.sm,
      YoursRadiusRole.button => radii.lg,
      YoursRadiusRole.status => radii.pill,
      YoursRadiusRole.sheet => 28,
    };
  }

  EdgeInsets yoursPadding(YoursSpacingRole role) {
    final spacing = yoursSpacing;
    return switch (role) {
      YoursSpacingRole.pageInset => EdgeInsets.fromLTRB(spacing.md, 12, spacing.md, 28),
      YoursSpacingRole.cardPadding => EdgeInsets.all(spacing.md + 2),
      YoursSpacingRole.componentGap => EdgeInsets.all(spacing.md),
      YoursSpacingRole.compactGap => EdgeInsets.all(spacing.sm),
      YoursSpacingRole.formGap => EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 10),
    };
  }

  BorderSide get yoursHairline => BorderSide(color: yoursPalette.border);

  List<BoxShadow> get yoursCardShadow => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: yoursPalette.brightness == Brightness.light ? 0.045 : 0.0,
      ),
      offset: const Offset(0, 2),
      blurRadius: 10,
    ),
  ];
}

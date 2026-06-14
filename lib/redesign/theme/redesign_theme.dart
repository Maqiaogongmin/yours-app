/// Color and style constants extracted from the Yours visual system.
///
/// Reference: app-icon-yours.md / yours-project-package.md
library;

import 'package:flutter/material.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

/// Background: oklch(15% 0.01 250)
const Color kBg = Color(0xFF17171F);

/// Card surface: oklch(22% 0.012 250)
const Color kSurface = Color(0xFF242431);

/// Panel background / nested surface
const Color kPanel = Color(0xFF1D1D28);

/// Foreground text: warm white
const Color kFg = Color(0xFFF2F0ED);

/// Muted/secondary text
const Color kMuted = Color(0xFF8B8998);

/// Border / separators
const Color kBorder = Color(0xFF383747);

/// Former primary blue slot, now the Yours ember accent for compatibility.
const Color kBlue = Color(0xFFE8793A);

/// Accent / CTA: lava ember
const Color kAccent = Color(0xFFE8793A);

/// Soft accent fill
const Color kAccentDim = Color(0x26E8793A);

/// Success / completed green
const Color kGreen = Color(0xFF5FAA73);

/// Red (calendar selected, danger, etc): #ed3b4d
const Color kRed = Color(0xFFED3B4D);

/// Cream / warm text surface
const Color kCream = Color(0xFFF2F0ED);

// ─── Theme Extensions ────────────────────────────────────────────────────────

@immutable
class YoursPalette extends ThemeExtension<YoursPalette> {
  const YoursPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.panel,
    required this.elevated,
    required this.fg,
    required this.muted,
    required this.subtle,
    required this.border,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.danger,
    required this.success,
    required this.warn,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color panel;
  final Color elevated;
  final Color fg;
  final Color muted;
  final Color subtle;
  final Color border;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color danger;
  final Color success;
  final Color warn;

  static const light = YoursPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF8F3EA),
    surface: Color(0xFFFFFDF8),
    panel: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    fg: Color(0xFF1F1A17),
    muted: Color(0xFF746A60),
    subtle: Color(0xFFA99D91),
    border: Color(0xFFE8DED2),
    accent: Color(0xFFD86F32),
    accentPressed: Color(0xFFBF5D26),
    accentSoft: Color(0x24D86F32),
    danger: Color(0xFFC94A3A),
    success: Color(0xFF3F8F5B),
    warn: Color(0xFFB88221),
  );

  static const dark = YoursPalette(
    brightness: Brightness.dark,
    bg: kBg,
    surface: kSurface,
    panel: kPanel,
    elevated: Color(0xFF2B2B39),
    fg: kFg,
    muted: Color(0xFFAAA5B6),
    subtle: kMuted,
    border: kBorder,
    accent: kAccent,
    accentPressed: Color(0xFFFF8A4D),
    accentSoft: kAccentDim,
    danger: kRed,
    success: kGreen,
    warn: Color(0xFFE2AA45),
  );

  @override
  YoursPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? panel,
    Color? elevated,
    Color? fg,
    Color? muted,
    Color? subtle,
    Color? border,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? danger,
    Color? success,
    Color? warn,
  }) {
    return YoursPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      elevated: elevated ?? this.elevated,
      fg: fg ?? this.fg,
      muted: muted ?? this.muted,
      subtle: subtle ?? this.subtle,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warn: warn ?? this.warn,
    );
  }

  @override
  YoursPalette lerp(ThemeExtension<YoursPalette>? other, double t) {
    if (other is! YoursPalette) {
      return this;
    }
    return YoursPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
    );
  }
}

@immutable
class YoursRadii extends ThemeExtension<YoursRadii> {
  const YoursRadii({
    this.sm = 10,
    this.md = 14,
    this.lg = 18,
    this.xl = kCardRadius,
    this.pill = kPillRadius,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  @override
  YoursRadii copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) {
    return YoursRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      pill: pill ?? this.pill,
    );
  }

  @override
  YoursRadii lerp(ThemeExtension<YoursRadii>? other, double t) {
    if (other is! YoursRadii) {
      return this;
    }
    return YoursRadii(
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
      pill: _lerpDouble(pill, other.pill, t),
    );
  }
}

@immutable
class YoursSpacing extends ThemeExtension<YoursSpacing> {
  const YoursSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = kGutter,
    this.lg = 24,
    this.xl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  YoursSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return YoursSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  YoursSpacing lerp(ThemeExtension<YoursSpacing>? other, double t) {
    if (other is! YoursSpacing) {
      return this;
    }
    return YoursSpacing(
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
    );
  }
}

@immutable
class YoursTextStyles extends ThemeExtension<YoursTextStyles> {
  const YoursTextStyles({
    required this.workoutNumber,
    required this.timerNumber,
    required this.compactLabel,
  });

  final TextStyle workoutNumber;
  final TextStyle timerNumber;
  final TextStyle compactLabel;

  static const defaults = YoursTextStyles(
    workoutNumber: TextStyle(
      fontFamily: 'RobotoCondensed',
      fontSize: 38,
      fontVariations: [FontVariation('wght', 800)],
      height: 1,
      letterSpacing: 0,
    ),
    timerNumber: TextStyle(
      fontFamily: 'RobotoCondensed',
      fontSize: 34,
      fontVariations: [FontVariation('wght', 800)],
      height: 1,
      letterSpacing: 0,
    ),
    compactLabel: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: 0,
    ),
  );

  @override
  YoursTextStyles copyWith({
    TextStyle? workoutNumber,
    TextStyle? timerNumber,
    TextStyle? compactLabel,
  }) {
    return YoursTextStyles(
      workoutNumber: workoutNumber ?? this.workoutNumber,
      timerNumber: timerNumber ?? this.timerNumber,
      compactLabel: compactLabel ?? this.compactLabel,
    );
  }

  @override
  YoursTextStyles lerp(ThemeExtension<YoursTextStyles>? other, double t) {
    if (other is! YoursTextStyles) {
      return this;
    }
    return YoursTextStyles(
      workoutNumber: TextStyle.lerp(workoutNumber, other.workoutNumber, t)!,
      timerNumber: TextStyle.lerp(timerNumber, other.timerNumber, t)!,
      compactLabel: TextStyle.lerp(compactLabel, other.compactLabel, t)!,
    );
  }
}

extension YoursThemeContext on BuildContext {
  YoursPalette get yoursPalette =>
      Theme.of(this).extension<YoursPalette>() ??
      (Theme.of(this).brightness == Brightness.light ? YoursPalette.light : YoursPalette.dark);

  YoursRadii get yoursRadii => Theme.of(this).extension<YoursRadii>() ?? const YoursRadii();

  YoursSpacing get yoursSpacing => Theme.of(this).extension<YoursSpacing>() ?? const YoursSpacing();

  YoursTextStyles get yoursTextStyles =>
      Theme.of(this).extension<YoursTextStyles>() ?? YoursTextStyles.defaults;
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─── Spacing ─────────────────────────────────────────────────────────────────

const double kGutter = 16.0;
const double kCardRadius = 24.0;
const double kPillRadius = 999.0;
const double kTopBarHeight = 94.0;

// ─── Text Styles ─────────────────────────────────────────────────────────────

const String kFont =
    '-apple-system, BlinkMacSystemFont, "SF Pro Display", '
    '"PingFang SC", "Microsoft YaHei", system-ui, sans-serif';
const String kMono = '"SF Mono", ui-monospace, Menlo, Consolas, monospace';

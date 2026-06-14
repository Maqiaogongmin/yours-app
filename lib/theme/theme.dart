import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

// Color scheme, please consult
// * https://pub.dev/packages/flex_color_scheme
// * https://rydmike.com/flexseedscheme/demo-v1/#/

const Color yoursPrimaryColor = Color(0xffe8793a);
const Color yoursPrimaryButtonColor = Color(0xffe8793a);
const Color yoursPrimaryColorLight = Color(0xfff0a060);
const Color yoursSecondaryColor = Color(0xffe63946);
const Color yoursSecondaryColorLight = Color(0xffF6B4BA);
const Color yoursTertiaryColor = Color(0xFF5FAA73);

const FlexSubThemesData yoursSubThemeData = FlexSubThemesData(
  fabSchemeColor: SchemeColor.secondary,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorIsFilled: true,
  useMaterial3Typography: true,
  appBarScrolledUnderElevation: 4,
  navigationBarIndicatorOpacity: 0.24,
  navigationBarHeight: 56,
);

// Make a light ColorScheme from the seeds.
final ColorScheme schemeLight = SeedColorScheme.fromSeeds(
  primary: yoursPrimaryColor,
  primaryKey: yoursPrimaryColor,
  secondaryKey: yoursSecondaryColor,
  secondary: yoursSecondaryColor,
  tertiaryKey: yoursTertiaryColor,
  brightness: Brightness.light,
  tones: FlexTones.vivid(Brightness.light),
);

// Make a dark ColorScheme from the seeds.
final ColorScheme schemeDark = SeedColorScheme.fromSeeds(
  // primary: yoursPrimaryColor,
  primaryKey: yoursPrimaryColor,
  secondaryKey: yoursSecondaryColor,
  secondary: yoursSecondaryColor,
  brightness: Brightness.dark,
  tones: FlexTones.vivid(Brightness.dark),
);

// Make a high contrast light ColorScheme from the seeds
final ColorScheme schemeLightHc = SeedColorScheme.fromSeeds(
  primaryKey: yoursPrimaryColor,
  secondaryKey: yoursSecondaryColor,
  brightness: Brightness.light,
  tones: FlexTones.ultraContrast(Brightness.light),
);

// Make a ultra contrast dark ColorScheme from the seeds.
final ColorScheme schemeDarkHc = SeedColorScheme.fromSeeds(
  primaryKey: yoursPrimaryColor,
  secondaryKey: yoursSecondaryColor,
  brightness: Brightness.dark,
  tones: FlexTones.ultraContrast(Brightness.dark),
);

const String yoursDisplayFont = 'RobotoCondensed';
const List<FontVariation> displayFontBoldWeight = [FontVariation('wght', 600)];
const List<FontVariation> displayFontHeavyWeight = [FontVariation('wght', 800)];

const yoursTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontHeavyWeight,
  ),
  displayMedium: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontHeavyWeight,
  ),
  displaySmall: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontHeavyWeight,
  ),
  headlineLarge: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
  headlineMedium: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
  headlineSmall: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
  titleLarge: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
  titleMedium: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
  titleSmall: TextStyle(
    fontFamily: yoursDisplayFont,
    fontVariations: displayFontBoldWeight,
  ),
);

final yoursLightTheme = _withYoursVisualSystem(
  FlexThemeData.light(
    colorScheme: _schemeForPalette(schemeLight, YoursPalette.light),
    useMaterial3: true,
    appBarStyle: FlexAppBarStyle.primary,
    subThemesData: yoursSubThemeData,
    textTheme: yoursTextTheme,
  ),
  YoursPalette.light,
);

final yoursDarkTheme = _withYoursVisualSystem(
  FlexThemeData.dark(
    colorScheme: _schemeForPalette(schemeDark, YoursPalette.dark),
    useMaterial3: true,
    subThemesData: yoursSubThemeData,
    textTheme: yoursTextTheme,
  ),
  YoursPalette.dark,
);

final yoursLightThemeHc = _withYoursVisualSystem(
  FlexThemeData.light(
    colorScheme: _schemeForPalette(
      schemeLightHc,
      YoursPalette.light.copyWith(
        fg: const Color(0xFF15100D),
        muted: const Color(0xFF4D433B),
        border: const Color(0xFFD0C0B0),
      ),
    ),
    useMaterial3: true,
    appBarStyle: FlexAppBarStyle.primary,
    subThemesData: yoursSubThemeData,
    textTheme: yoursTextTheme,
  ),
  YoursPalette.light.copyWith(
    fg: const Color(0xFF15100D),
    muted: const Color(0xFF4D433B),
    border: const Color(0xFFD0C0B0),
  ),
);

final yoursDarkThemeHc = _withYoursVisualSystem(
  FlexThemeData.dark(
    colorScheme: _schemeForPalette(
      schemeDarkHc,
      YoursPalette.dark.copyWith(
        bg: const Color(0xFF101017),
        surface: const Color(0xFF20202D),
        fg: Colors.white,
        muted: const Color(0xFFC7C2D0),
        border: const Color(0xFF535164),
      ),
    ),
    useMaterial3: true,
    subThemesData: yoursSubThemeData,
    textTheme: yoursTextTheme,
  ),
  YoursPalette.dark.copyWith(
    bg: const Color(0xFF101017),
    surface: const Color(0xFF20202D),
    fg: Colors.white,
    muted: const Color(0xFFC7C2D0),
    border: const Color(0xFF535164),
  ),
);

ColorScheme _schemeForPalette(ColorScheme base, YoursPalette palette) {
  final onAccent = palette.brightness == Brightness.light ? Colors.white : const Color(0xFF1C120C);

  return base.copyWith(
    brightness: palette.brightness,
    primary: palette.accent,
    onPrimary: onAccent,
    primaryContainer: palette.accentSoft,
    onPrimaryContainer: palette.accent,
    secondary: palette.danger,
    onSecondary: Colors.white,
    tertiary: palette.success,
    onTertiary: Colors.white,
    surface: palette.surface,
    onSurface: palette.fg,
    surfaceContainerLowest: palette.bg,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.panel,
    surfaceContainerHigh: palette.elevated,
    surfaceContainerHighest: palette.elevated,
    onSurfaceVariant: palette.muted,
    outline: palette.border,
    outlineVariant: palette.border,
    error: palette.danger,
    onError: Colors.white,
  );
}

ThemeData _withYoursVisualSystem(ThemeData base, YoursPalette palette) {
  final isLight = palette.brightness == Brightness.light;

  final borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: palette.border),
  );
  final focusedBorderStyle = borderStyle.copyWith(
    borderSide: BorderSide(color: palette.accent, width: 1.2),
  );
  final errorBorderStyle = borderStyle.copyWith(
    borderSide: BorderSide(color: palette.danger, width: 1.2),
  );

  return base.copyWith(
    extensions: const <ThemeExtension<dynamic>>[
      YoursRadii(),
      YoursSpacing(),
      YoursTextStyles.defaults,
    ].followedBy(<ThemeExtension<dynamic>>[palette]).toList(growable: false),
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    cardColor: palette.surface,
    dividerColor: palette.border,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: palette.bg,
      foregroundColor: palette.fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: isLight ? 1 : 0,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.panel,
      selectedColor: palette.accentSoft,
      disabledColor: palette.panel.withValues(alpha: 0.54),
      labelStyle: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(color: palette.accent, fontWeight: FontWeight.w800),
      side: BorderSide(color: palette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: palette.fg, fontSize: 20, fontWeight: FontWeight.w800),
      contentTextStyle: TextStyle(color: palette.fg, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      modalBackgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.elevated,
      contentTextStyle: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.28),
      selectionHandleColor: palette.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.panel,
      labelStyle: TextStyle(color: palette.muted),
      hintStyle: TextStyle(color: palette.subtle),
      helperStyle: TextStyle(color: palette.muted),
      prefixIconColor: palette.muted,
      suffixIconColor: palette.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: borderStyle,
      focusedBorder: focusedBorderStyle,
      errorBorder: errorBorderStyle,
      focusedErrorBorder: errorBorderStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.panel,
        disabledForegroundColor: palette.subtle,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.panel,
        disabledForegroundColor: palette.subtle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.accent,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

CalendarStyle getYoursCalendarStyle(ThemeData theme) {
  return CalendarStyle(
    outsideDaysVisible: false,
    todayDecoration: const BoxDecoration(
      color: Colors.amber,
      shape: BoxShape.circle,
    ),
    markerDecoration: BoxDecoration(
      color: theme.textTheme.headlineLarge?.color,
      shape: BoxShape.circle,
    ),
    selectedDecoration: const BoxDecoration(
      color: yoursSecondaryColor,
      shape: BoxShape.circle,
    ),
    rangeStartDecoration: const BoxDecoration(
      color: yoursSecondaryColor,
      shape: BoxShape.circle,
    ),
    rangeEndDecoration: const BoxDecoration(
      color: yoursSecondaryColor,
      shape: BoxShape.circle,
    ),
    rangeHighlightColor: yoursSecondaryColorLight,
    weekendTextStyle: const TextStyle(color: yoursSecondaryColor),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
import 'package:yours/redesign/theme/theme_mode_controller.dart';
import 'package:yours/redesign/localization/locale_controller.dart';
import 'package:yours/theme/theme.dart';

void main() {
  test('Yours themes expose visual system extensions', () {
    for (final theme in <ThemeData>[
      yoursLightTheme,
      yoursDarkTheme,
      yoursLightThemeHc,
      yoursDarkThemeHc,
    ]) {
      expect(theme.extension<YoursPalette>(), isNotNull);
      expect(theme.extension<YoursRadii>(), isNotNull);
      expect(theme.extension<YoursSpacing>(), isNotNull);
      expect(theme.extension<YoursTextStyles>(), isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    }
  });

  test('Yours light and dark palettes keep the intended visual direction', () {
    final light = yoursLightTheme.extension<YoursPalette>()!;
    final dark = yoursDarkTheme.extension<YoursPalette>()!;

    expect(light.bg, const Color(0xFFF8F3EA));
    expect(light.accent, const Color(0xFFD86F32));
    expect(dark.bg, kBg);
    expect(dark.surface, kSurface);
    expect(dark.accent, kAccent);
  });

  testWidgets('Yours semantic design tokens resolve from theme context', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.yoursSurface(YoursSurfaceRole.page), const Color(0xFFF8F3EA));
    expect(capturedContext.yoursTone(YoursTone.accent), const Color(0xFFD86F32));
    expect(capturedContext.yoursRadius(YoursRadiusRole.card), kCardRadius);
    expect(capturedContext.yoursText(YoursTextRole.pageTitle).fontSize, 28);
    expect(capturedContext.yoursText(YoursTextRole.metric).fontFamily, 'RobotoCondensed');
  });

  test('Yours theme mode controller defaults to system and persists manual choice', () async {
    final values = <String, String>{};

    final controller = YoursThemeModeController(
      readMode: () async => values[yoursThemeModePreferenceKey],
      writeMode: (value) async => values[yoursThemeModePreferenceKey] = value,
    );
    await controller.load();
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);

    final reloaded = YoursThemeModeController(
      readMode: () async => values[yoursThemeModePreferenceKey],
      writeMode: (value) async => values[yoursThemeModePreferenceKey] = value,
    );
    await reloaded.load();
    expect(reloaded.mode, ThemeMode.dark);
  });

  test('Yours locale controller defaults to system and persists manual choice', () async {
    final values = <String, String>{};
    final controller = YoursLocaleController(
      readLocale: () async => values[yoursLocalePreferenceKey],
      writeLocale: (value) async => values[yoursLocalePreferenceKey] = value,
    );

    await controller.load();
    expect(controller.locale, isNull);

    await controller.setLocale(const Locale('en'));
    expect(controller.locale, const Locale('en'));

    final reloaded = YoursLocaleController(
      readLocale: () async => values[yoursLocalePreferenceKey],
      writeLocale: (value) async => values[yoursLocalePreferenceKey] = value,
    );
    await reloaded.load();
    expect(reloaded.locale, const Locale('en'));
  });
}

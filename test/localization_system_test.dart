import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/data/yours_exception.dart';
import 'package:yours/redesign/localization/generated_language_registry.dart';
import 'package:yours/redesign/localization/locale_controller.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/pages/profile/settings_page.dart';
import 'package:yours/redesign/theme/theme_mode_controller.dart';

Widget _localizedApp({
  required Locale locale,
  required Widget home,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: yoursSupportedLocales,
    home: home,
  );
}

void main() {
  test('generated language registry contains enabled language packs', () {
    expect(
      yoursSupportedLanguages.map((language) => language.locale.languageCode),
      ['zh', 'en', 'ja'],
    );
    expect(
      yoursSupportedLanguages.map((language) => language.nativeName),
      ['简体中文', 'English', '日本語'],
    );
  });

  test('unsupported system locales fall back to English', () {
    expect(
      resolveYoursLocales(
        const [Locale('fr', 'FR')],
        yoursSupportedLocales,
      ),
      const Locale('en'),
    );
    expect(
      resolveYoursLocales(
        const [Locale('de', 'DE'), Locale('ja', 'JP')],
        yoursSupportedLocales,
      ),
      const Locale('ja'),
    );
  });

  test('locale controller accepts legacy language-code preferences', () async {
    final controller = YoursLocaleController(readLocale: () async => 'zh');
    await controller.load();
    expect(controller.locale, const Locale('zh'));
  });

  testWidgets('structured errors are localized without matching Chinese text', (tester) async {
    late String detail;
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            detail = localizedErrorDetail(
              context,
              const YoursException(YoursErrorCode.serverTimeout),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(detail, contains('timed out'));
    expect(detail, isNot(contains('网络')));
  });

  testWidgets('Japanese operation results stay separate from error localization', (tester) async {
    late String backupCreated;
    late String backupPlaintextWarning;
    late String restoreComplete;
    late String unknownError;
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('ja'),
        home: Builder(
          builder: (context) {
            backupCreated = AppLocalizations.of(context).profileBackupCreated(
              'yours-backup.zip',
            );
            backupPlaintextWarning = AppLocalizations.of(context).profileBackupPlaintextWarning;
            restoreComplete = AppLocalizations.of(context).profileRestoreComplete;
            unknownError = localizedErrorDetail(
              context,
              StateError('internal diagnostic text'),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(backupCreated, isNot('不明なエラー'));
    expect(backupPlaintextWarning, contains('トレーニングデータ'));
    expect(restoreComplete, isNot('不明なエラー'));
    expect(unknownError, '不明なエラー');
  });

  testWidgets('settings exposes appearance, language, and about entries', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('zh'),
        home: SettingsPage(onAbout: () {}),
      ),
    );

    expect(find.text('外观'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('关于有思（Yours）'), findsOneWidget);

    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
  });

  testWidgets('appearance page changes the persisted theme controller', (tester) async {
    final values = <String, String>{};
    final controller = YoursThemeModeController(
      readMode: () async => values[yoursThemeModePreferenceKey],
      writeMode: (value) async => values[yoursThemeModePreferenceKey] = value,
    );
    await controller.load();
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('zh'),
        home: SettingsPage(
          onAbout: () {},
          themeController: controller,
        ),
      ),
    );

    await tester.tap(find.text('外观'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pump();

    expect(controller.mode, ThemeMode.dark);
    expect(values[yoursThemeModePreferenceKey], 'dark');
  });
}

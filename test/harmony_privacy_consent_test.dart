import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/localization/generated_language_registry.dart';
import 'package:yours/redesign/privacy/harmony_privacy_consent.dart';
import 'package:yours/theme/theme.dart';

void main() {
  testWidgets('Harmony privacy gate blocks initialization until consent', (tester) async {
    final repository = _FakePrivacyConsentRepository();
    var initializeCount = 0;
    var declineCount = 0;

    await tester.pumpWidget(
      _testApp(
        HarmonyPrivacyConsentGate(
          repository: repository,
          initializeApp: () async => initializeCount += 1,
          onDecline: () => declineCount += 1,
          child: const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('privacy-consent-dialog')), findsOneWidget);
    expect(find.text('有思（Yours）隐私政策'), findsOneWidget);
    expect(initializeCount, 0);

    expect(find.byKey(const ValueKey('privacy-policy-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-policy-link')), findsNothing);
    expect(find.textContaining('有思不提供或运营用于接收、存储训练数据的服务器'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('privacy-consent-decline')));
    expect(declineCount, 1);
    expect(initializeCount, 0);

    await tester.tap(find.byKey(const ValueKey('privacy-consent-accept')));
    await tester.pumpAndSettle();

    expect(repository.accepted, isTrue);
    expect(initializeCount, 1);
    expect(find.text('ready'), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-consent-dialog')), findsNothing);
  });

  testWidgets('accepted Harmony privacy gate initializes once without prompting', (tester) async {
    final repository = _FakePrivacyConsentRepository(accepted: true);
    var initializeCount = 0;

    await tester.pumpWidget(
      _testApp(
        HarmonyPrivacyConsentGate(
          repository: repository,
          initializeApp: () async => initializeCount += 1,
          onDecline: () {},
          child: const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(initializeCount, 1);
    expect(find.text('ready'), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-consent-dialog')), findsNothing);
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(
    theme: yoursLightTheme.copyWith(splashFactory: NoSplash.splashFactory),
    locale: const Locale('zh'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: yoursSupportedLocales,
    home: home,
  );
}

final class _FakePrivacyConsentRepository implements HarmonyPrivacyConsentRepository {
  _FakePrivacyConsentRepository({this.accepted = false});

  bool accepted;

  @override
  Future<void> acceptCurrentVersion() async {
    accepted = true;
  }

  @override
  Future<bool> hasAcceptedCurrentVersion() async => accepted;
}

// Yours (有思) — 本地优先的个人训练记录 App
// Copyright (c) 2026 Yours

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/navigation/main_shell.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/harmony_sqlite.dart';
import 'package:yours/redesign/localization/generated_language_registry.dart';
import 'package:yours/redesign/localization/locale_controller.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/privacy/harmony_privacy_consent.dart';
import 'package:yours/theme/theme.dart';
import 'package:yours/redesign/theme/theme_mode_controller.dart';

void _setupLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time} [${record.loggerName}] ${record.message}');
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const bool _harmonySmokeMode = bool.fromEnvironment('YOURS_HARMONY_SMOKE');

bool get _isHarmonyOS => isHarmonyOS;

void main() async {
  // Needs to be called before runApp
  WidgetsFlutterBinding.ensureInitialized();
  configureHarmonySqlite();
  if (!_isHarmonyOS) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  // Logger
  _setupLogging();

  final logger = Logger('main');

  if (_harmonySmokeMode) {
    logger.info('Starting HarmonyOS Flutter smoke UI');
    runApp(const _HarmonySmokeApp());
    return;
  }

  // HarmonyOS must not initialize user data before privacy consent.
  if (!_isHarmonyOS) {
    await configureDatabases();
  }
  try {
    await yoursThemeModeController.load().timeout(const Duration(seconds: 3));
  } on TimeoutException catch (error) {
    logger.warning('Theme preference load timed out: $error');
  } catch (error, stack) {
    logger.warning('Theme preference load skipped: $error');
    logger.fine('Theme preference stack: $stack');
  }
  try {
    await yoursLocaleController.load().timeout(const Duration(seconds: 3));
  } on TimeoutException catch (error) {
    logger.warning('Locale preference load timed out: $error');
  } catch (error, stack) {
    logger.warning('Locale preference load skipped: $error');
    logger.fine('Locale preference stack: $stack');
  }

  // Redesign is local-first. Keep unexpected errors in logs instead of showing legacy dialogs.
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.severe('Flutter error: ${details.exception}');
    FlutterError.presentError(details);
  };

  // Catch errors that happen outside of the Flutter framework (e.g., in async operations)
  PlatformDispatcher.instance.onError = (error, stack) {
    // Skip the StackFrame assertion error from the stack_trace package.
    // This is a known Flutter framework issue where async gap markers in stack
    // traces cause an assertion failure in StackFrame.fromStackTraceLine.
    if (error is AssertionError && error.toString().contains('asynchronous gap')) {
      logger.warning('Suppressed StackFrame assertion error (known Flutter issue)');
      return true;
    }

    logger.severe('Uncaught async error: $error');
    logger.severe('Stack trace: $stack');

    // Return true to indicate that the error has been handled.
    return true;
  };

  // Application
  runApp(const ProviderScope(child: MainApp()));
}

class _HarmonySmokeApp extends StatelessWidget {
  const _HarmonySmokeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Color(0xFF0B6B4F),
        child: Center(
          child: Text(
            'Yours Flutter Smoke',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp();

  @override
  Widget build(BuildContext context) {
    return YoursThemeScope(
      controller: yoursThemeModeController,
      child: AnimatedBuilder(
        animation: Listenable.merge([yoursThemeModeController, yoursLocaleController]),
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: yoursLightTheme,
          darkTheme: yoursDarkTheme,
          highContrastTheme: yoursLightThemeHc,
          highContrastDarkTheme: yoursDarkThemeHc,
          themeMode: yoursThemeModeController.mode,
          home: _isHarmonyOS
              ? HarmonyPrivacyConsentGate(
                  repository: SharedPreferencesHarmonyPrivacyConsentRepository(),
                  initializeApp: configureDatabases,
                  onDecline: () => SystemNavigator.pop(),
                  child: const MainShell(),
                )
              : const MainShell(),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          locale: yoursLocaleController.locale,
          localeListResolutionCallback: resolveYoursLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: yoursSupportedLocales,
        ),
      ),
    );
  }
}

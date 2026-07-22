library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/localization/generated_language_registry.dart';

const String yoursLocalePreferenceKey = 'yours_locale';

Locale resolveYoursLocales(List<Locale>? preferredLocales, Iterable<Locale> supportedLocales) {
  final supported = supportedLocales.toList(growable: false);
  for (final preferred in preferredLocales ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == preferred.languageCode) {
        return candidate;
      }
    }
  }
  return supported.firstWhere(
    (locale) => locale.languageCode == 'en',
    orElse: () => const Locale('en'),
  );
}

typedef YoursLocaleReader = Future<String?> Function();
typedef YoursLocaleWriter = Future<void> Function(String value);

class YoursLocaleController extends ChangeNotifier {
  YoursLocaleController({
    SharedPreferencesAsync? preferences,
    YoursLocaleReader? readLocale,
    YoursLocaleWriter? writeLocale,
  }) : _preferences = preferences,
       _readLocale = readLocale,
       _writeLocale = writeLocale;

  final SharedPreferencesAsync? _preferences;
  final YoursLocaleReader? _readLocale;
  final YoursLocaleWriter? _writeLocale;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    _locale = _parse(await (_readLocale ?? _defaultReadLocale)());
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    await (_writeLocale ?? _defaultWriteLocale)(locale?.toLanguageTag() ?? 'system');
  }

  SharedPreferencesAsync get _prefs => _preferences ?? SharedPreferencesAsync();

  Future<String?> _defaultReadLocale() => _prefs.getString(yoursLocalePreferenceKey);

  Future<void> _defaultWriteLocale(String value) {
    return _prefs.setString(yoursLocalePreferenceKey, value);
  }

  static Locale? _parse(String? value) {
    if (value == null || value == 'system') {
      return null;
    }
    for (final language in yoursSupportedLanguages) {
      if (language.locale.toLanguageTag() == value || language.locale.languageCode == value) {
        return language.locale;
      }
    }
    return null;
  }
}

final yoursLocaleController = YoursLocaleController();

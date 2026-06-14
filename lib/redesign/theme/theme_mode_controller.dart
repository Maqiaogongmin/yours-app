library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String yoursThemeModePreferenceKey = 'yours_theme_mode';

typedef YoursThemeModeReader = Future<String?> Function();
typedef YoursThemeModeWriter = Future<void> Function(String value);

class YoursThemeModeController extends ChangeNotifier {
  YoursThemeModeController({
    SharedPreferencesAsync? preferences,
    YoursThemeModeReader? readMode,
    YoursThemeModeWriter? writeMode,
  }) : _preferences = preferences,
       _readMode = readMode,
       _writeMode = writeMode;

  final SharedPreferencesAsync? _preferences;
  final YoursThemeModeReader? _readMode;
  final YoursThemeModeWriter? _writeMode;
  ThemeMode _mode = ThemeMode.system;
  bool _loaded = false;

  ThemeMode get mode => _mode;
  bool get loaded => _loaded;

  Future<void> load() async {
    final raw = await (_readMode ?? _defaultReadMode)();
    _mode = _parse(raw);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode && _loaded) {
      return;
    }
    _mode = mode;
    _loaded = true;
    notifyListeners();
    await (_writeMode ?? _defaultWriteMode)(_serialize(mode));
  }

  Future<void> toggleResolvedBrightness(Brightness brightness) {
    return setMode(brightness == Brightness.light ? ThemeMode.dark : ThemeMode.light);
  }

  static ThemeMode _parse(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _serialize(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  SharedPreferencesAsync get _prefs => _preferences ?? SharedPreferencesAsync();

  Future<String?> _defaultReadMode() => _prefs.getString(yoursThemeModePreferenceKey);

  Future<void> _defaultWriteMode(String value) {
    return _prefs.setString(yoursThemeModePreferenceKey, value);
  }
}

final yoursThemeModeController = YoursThemeModeController();

class YoursThemeScope extends InheritedNotifier<YoursThemeModeController> {
  const YoursThemeScope({
    super.key,
    required YoursThemeModeController controller,
    required super.child,
  }) : super(notifier: controller);

  static YoursThemeModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YoursThemeScope>();
    assert(scope != null, 'YoursThemeScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

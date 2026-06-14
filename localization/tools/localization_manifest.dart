import 'dart:io';

import 'package:yaml/yaml.dart';

final class LanguageDefinition {
  const LanguageDefinition({
    required this.locale,
    required this.flutterLocale,
    required this.nativeName,
    required this.enabled,
  });

  final String locale;
  final String flutterLocale;
  final String nativeName;
  final bool enabled;

  String get directoryName => locale;
  String get arbFileName => 'app_$flutterLocale.arb';
}

final class LocalizationManifest {
  const LocalizationManifest({
    required this.sourceLocale,
    required this.languages,
  });

  final String sourceLocale;
  final List<LanguageDefinition> languages;

  List<LanguageDefinition> get enabledLanguages =>
      languages.where((language) => language.enabled).toList(growable: false);
}

LocalizationManifest loadLocalizationManifest(Directory root) {
  final manifestFile = File('${root.path}/localization/manifest.yaml');
  final document = loadYaml(manifestFile.readAsStringSync()) as YamlMap;
  final languages = (document['languages'] as YamlList)
      .map((entry) {
        final language = entry as YamlMap;
        return LanguageDefinition(
          locale: language['locale'] as String,
          flutterLocale: language['flutter_locale'] as String,
          nativeName: language['native_name'] as String,
          enabled: language['enabled'] as bool? ?? false,
        );
      })
      .toList(growable: false);
  return LocalizationManifest(
    sourceLocale: document['source_locale'] as String,
    languages: languages,
  );
}

Directory projectRoot() {
  var current = Directory.current.absolute;
  while (!File('${current.path}/pubspec.yaml').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find the Flutter project root.');
    }
    current = parent;
  }
  return current;
}

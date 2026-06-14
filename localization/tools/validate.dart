import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'localization_manifest.dart';

final _placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}');
final _userFacingChinesePatterns = <RegExp>[
  RegExp(r'''Text\(\s*(?:const\s+)?['"][^'"]*[\u3400-\u9fff]'''),
  RegExp(r'''(?:title|label|hintText|tooltip|message|content)\s*:\s*['"][^'"]*[\u3400-\u9fff]'''),
];
final _userFacingEnglishPatterns = <RegExp>[
  RegExp(r'''Text\(\s*(?:const\s+)?['"][A-Za-z][^'"]*['"]'''),
  RegExp(
    r'''(?:title|label|hintText|tooltip|message|content)\s*:\s*['"][A-Za-z][^'"]*['"]''',
  ),
];

void main() {
  final root = projectRoot();
  final manifest = loadLocalizationManifest(root);
  final sourceLanguage = manifest.languages.singleWhere(
    (language) => language.locale == manifest.sourceLocale,
  );
  final source = _readArb(root, sourceLanguage);
  final sourceKeys = _messageKeys(source);
  final failures = <String>[];

  for (final language in manifest.enabledLanguages) {
    final arb = _readArb(root, language);
    final keys = _messageKeys(arb);
    final missing = sourceKeys.difference(keys);
    final obsolete = keys.difference(sourceKeys);
    if (missing.isNotEmpty) {
      failures.add('${language.locale}: missing ${missing.toList()..sort()}');
    }
    if (obsolete.isNotEmpty) {
      failures.add('${language.locale}: obsolete ${obsolete.toList()..sort()}');
    }
    for (final key in sourceKeys.intersection(keys)) {
      final expected = _placeholders(source[key] as String);
      final actual = _placeholders(arb[key] as String);
      if (!_sameSet(expected, actual)) {
        failures.add(
          '${language.locale}: placeholder mismatch for $key '
          '(expected $expected, found $actual)',
        );
      }
    }
  }

  failures.addAll(_validateBuiltInExercises(root, manifest));
  failures.addAll(_scanUserFacingHardcodedChinese(root));
  failures.addAll(_validateNoRuntimeLanguageGuessing(root));

  if (failures.isNotEmpty) {
    stderr.writeln('Localization validation failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Localization validation passed for '
    '${manifest.enabledLanguages.length} enabled languages and ${sourceKeys.length} messages.',
  );
}

List<String> _validateNoRuntimeLanguageGuessing(Directory root) {
  final file = File(
    '${root.path}/lib/redesign/localization/localized_error.dart',
  );
  if (!file.existsSync()) {
    return const [];
  }
  final source = file.readAsStringSync();
  final forbiddenPatterns = <String>[
    'containsChinese',
    r'\u3400',
    r'\u9fff',
    "languageCode != 'zh'",
  ];
  return [
    for (final pattern in forbiddenPatterns)
      if (source.contains(pattern)) 'localized_error.dart must not infer language from "$pattern"',
  ];
}

List<String> _validateBuiltInExercises(
  Directory root,
  LocalizationManifest manifest,
) {
  final failures = <String>[];
  final catalogFile = File('${root.path}/localization/exercises.yaml');
  if (!catalogFile.existsSync()) {
    return ['missing localization/exercises.yaml'];
  }
  final catalog = loadYaml(catalogFile.readAsStringSync()) as YamlMap;
  final catalogExercises = catalog['exercises'] as YamlMap;
  final expected = catalogExercises.keys.cast<String>().toSet();
  final remoteIds = <int, String>{};
  final aliases = <String, String>{};
  for (final entry in catalogExercises.entries) {
    final key = entry.key as String;
    final metadata = entry.value as YamlMap;
    final remoteId = metadata['remote_id'];
    if (remoteId is! int || remoteId <= 0) {
      failures.add('exercise $key has invalid remote_id');
    } else if (remoteIds[remoteId] case final previous?) {
      failures.add('exercises $previous and $key share remote_id $remoteId');
    } else {
      remoteIds[remoteId] = key;
    }
    final legacyNames = metadata['legacy_names'];
    final Iterable<dynamic> exerciseAliases = legacyNames is YamlList
        ? legacyNames
        : const <dynamic>[];
    for (final alias in exerciseAliases.whereType<String>()) {
      _registerExerciseAlias(failures, aliases, alias, key);
    }
  }
  const fields = {
    'name',
    'body_part',
    'equipment',
    'primary_muscles',
    'description',
  };
  for (final language in manifest.enabledLanguages) {
    final file = File(
      '${root.path}/localization/${language.directoryName}/exercises.yaml',
    );
    if (!file.existsSync()) {
      failures.add('${language.locale}: missing exercises.yaml');
      continue;
    }
    final pack = loadYaml(file.readAsStringSync()) as YamlMap;
    final actual = pack.keys.cast<String>().toSet();
    final missing = expected.difference(actual);
    final obsolete = actual.difference(expected);
    if (missing.isNotEmpty) {
      failures.add('${language.locale}: missing exercises ${missing.toList()..sort()}');
    }
    if (obsolete.isNotEmpty) {
      failures.add('${language.locale}: obsolete exercises ${obsolete.toList()..sort()}');
    }
    for (final key in expected.intersection(actual)) {
      final value = pack[key];
      if (value is! YamlMap) {
        failures.add('${language.locale}: exercise $key must be a map');
        continue;
      }
      for (final field in fields) {
        final text = value[field];
        if (text is! String || text.trim().isEmpty) {
          failures.add('${language.locale}: exercise $key missing $field');
        }
      }
      final name = value['name'];
      if (name is String && name.trim().isNotEmpty) {
        _registerExerciseAlias(failures, aliases, name, key);
      }
    }
  }
  return failures;
}

void _registerExerciseAlias(
  List<String> failures,
  Map<String, String> aliases,
  String alias,
  String key,
) {
  final normalized = alias
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u2010-\u2015]'), '-')
      .replaceAll(RegExp(r'[^a-z0-9\u3040-\u30ff\u3400-\u9fff]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final previous = aliases[normalized];
  if (previous != null && previous != key) {
    failures.add('exercise alias "$alias" is shared by $previous and $key');
  } else {
    aliases[normalized] = key;
  }
}

Map<String, dynamic> _readArb(Directory root, LanguageDefinition language) {
  final file = File(
    '${root.path}/localization/${language.directoryName}/strings.arb',
  );
  if (!file.existsSync()) {
    throw StateError('Missing language pack: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

Set<String> _placeholders(String message) =>
    _placeholderPattern.allMatches(message).map((match) => match.group(1)!).toSet();

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

List<String> _scanUserFacingHardcodedChinese(Directory root) {
  final failures = <String>[];
  final uiRoots = [
    Directory('${root.path}/lib/redesign/pages'),
    Directory('${root.path}/lib/redesign/navigation'),
    Directory('${root.path}/lib/redesign/shared'),
  ];
  for (final uiRoot in uiRoots) {
    if (!uiRoot.existsSync()) {
      continue;
    }
    for (final entity in uiRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.trimLeft().startsWith('//') || line.contains('l10n-ignore-hardcoded')) {
          continue;
        }
        if (_userFacingChinesePatterns.any((pattern) => pattern.hasMatch(line)) ||
            _userFacingEnglishPatterns.any((pattern) => pattern.hasMatch(line))) {
          failures.add(
            '${entity.path.substring(root.path.length + 1)}:${index + 1}: '
            'user-facing text must use localization resources',
          );
        }
      }
    }
  }
  return failures;
}

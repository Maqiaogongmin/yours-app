import 'dart:convert';
import 'dart:io';

const String _devEcoHome = '/Applications/DevEco-Studio.app/Contents';

const Set<String> _pureDartDependencies = <String>{
  'archive',
  'collection',
  'crypto',
  'http',
  'logging',
  'path',
  'uuid',
};

const Set<String> _platformDependencies = <String>{
  'path_provider',
  'shared_preferences',
  'url_launcher',
  'file_picker',
  'share_plus',
  'package_info_plus',
};

const Set<String> _databaseRiskDependencies = <String>{
  'drift',
  'drift_flutter',
  'sqlite3',
};

Future<void> main(List<String> arguments) async {
  final bool jsonOutput = arguments.contains('--json');
  final String workingDirectory = Directory.current.path;
  final String flutterOhHome = Platform.environment['FLUTTER_OH_HOME'] ?? _defaultFlutterOhHome();
  final String hdcExecutable =
      Platform.environment['HDC_HOME'] ??
      _findFirstExecutable(<String>[
        '$_devEcoHome/sdk/default/openharmony/toolchains/hdc',
        '$_devEcoHome/sdk/default/hms/toolchains/hdc',
        '$_devEcoHome/tools/hdc',
        'hdc',
      ]) ??
      'hdc';

  final Map<String, Object?> report = <String, Object?>{
    'workingDirectory': workingDirectory,
    'flutterOhHome': flutterOhHome,
    'checks': <Map<String, Object?>>[
      await _commandCheck(
        'current-flutter',
        'flutter',
        const <String>['--version'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'flutter-oh',
        '$flutterOhHome/bin/flutter',
        const <String>['--version'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'flutter-oh-doctor',
        '$flutterOhHome/bin/flutter',
        const <String>['doctor', '-v'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'ohpm',
        '/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm',
        const <String>['-v'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'hvigor',
        '/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw',
        const <String>['--version'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'java',
        '/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home/bin/java',
        const <String>['-version'],
        workingDirectory: workingDirectory,
      ),
      await _commandCheck(
        'hdc-targets',
        hdcExecutable,
        const <String>['list', 'targets', '-v'],
        workingDirectory: workingDirectory,
      ),
    ],
    'dependencyRisk': _dependencyRiskReport(
      File('$workingDirectory/pubspec.yaml'),
    ),
  };

  if (jsonOutput) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    return;
  }

  stdout.write(_formatReport(report));
}

String _defaultFlutterOhHome() {
  final String? home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return 'flutter_oh_3_41_9';
  }
  return '$home/Developer/flutter-oh/flutter_oh_3_41_9';
}

Future<Map<String, Object?>> _commandCheck(
  String name,
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final bool exists = File(executable).existsSync() || _isPathCommand(executable);
  if (!exists) {
    return <String, Object?>{
      'name': name,
      'ok': false,
      'command': <String>[executable, ...arguments],
      'summary': 'missing executable',
    };
  }

  try {
    final ProcessResult result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    ).timeout(const Duration(minutes: 2));
    final String output = '${result.stdout}\n${result.stderr}'.trim();
    return <String, Object?>{
      'name': name,
      'ok': result.exitCode == 0,
      'exitCode': result.exitCode,
      'command': <String>[executable, ...arguments],
      'summary': _firstLines(output),
    };
  } on Object catch (error) {
    return <String, Object?>{
      'name': name,
      'ok': false,
      'command': <String>[executable, ...arguments],
      'summary': error.toString(),
    };
  }
}

String? _findFirstExecutable(List<String> candidates) {
  for (final String candidate in candidates) {
    if (candidate.contains('/')) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
      continue;
    }
    if (_isPathCommand(candidate)) {
      return candidate;
    }
  }
  return null;
}

bool _isPathCommand(String executable) {
  if (executable.contains('/')) {
    return false;
  }
  final String path = Platform.environment['PATH'] ?? '';
  return path
      .split(':')
      .where((String entry) => entry.isNotEmpty)
      .any((String entry) => File('$entry/$executable').existsSync());
}

Map<String, Object?> _dependencyRiskReport(File pubspec) {
  if (!pubspec.existsSync()) {
    return <String, Object?>{'ok': false, 'summary': 'pubspec.yaml missing'};
  }
  final String contents = pubspec.readAsStringSync();
  return <String, Object?>{
    'pureDartPresent': _presentDependencies(contents, _pureDartDependencies),
    'platformBridgeRequired': _presentDependencies(contents, _platformDependencies),
    'databaseValidationRequired': _presentDependencies(contents, _databaseRiskDependencies),
  };
}

List<String> _presentDependencies(String pubspec, Set<String> names) {
  final List<String> present = <String>[];
  for (final String name in names) {
    if (RegExp('^  $name:', multiLine: true).hasMatch(pubspec)) {
      present.add(name);
    }
  }
  present.sort();
  return present;
}

String _firstLines(String output) {
  if (output.isEmpty) {
    return '';
  }
  return output.split('\n').take(6).join('\n');
}

String _formatReport(Map<String, Object?> report) {
  final StringBuffer buffer = StringBuffer()
    ..writeln('Yours Flutter HarmonyOS readiness')
    ..writeln('Working directory: ${report['workingDirectory']}')
    ..writeln('Flutter-OH home: ${report['flutterOhHome']}')
    ..writeln()
    ..writeln('Checks:');

  final checks = report['checks']! as List<Map<String, Object?>>;
  for (final Map<String, Object?> check in checks) {
    final String status = check['ok'] == true ? 'PASS' : 'FAIL';
    buffer
      ..writeln('- [$status] ${check['name']}')
      ..writeln(_indent('${check['summary'] ?? ''}'));
  }

  buffer
    ..writeln()
    ..writeln('Dependency risk:');
  final risk = report['dependencyRisk']! as Map<String, Object?>;
  for (final MapEntry<String, Object?> entry in risk.entries) {
    buffer.writeln('- ${entry.key}: ${entry.value}');
  }
  return buffer.toString();
}

String _indent(String value) {
  if (value.isEmpty) {
    return '  (no output)';
  }
  return value.split('\n').map((String line) => '  $line').join('\n');
}

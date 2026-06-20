import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/check_release_ready.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('release_ready_check_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('parses pubspec version, commit, changelog, and clean worktree', () async {
    _writeProject(tempDir);
    await _git(tempDir, <String>['init']);
    await _git(tempDir, <String>['config', 'user.email', 'test@example.com']);
    await _git(tempDir, <String>['config', 'user.name', 'Test User']);
    await _git(tempDir, <String>['add', '.']);
    await _git(tempDir, <String>['commit', '-m', 'Initial commit']);

    final ReleaseReadyReport report = await runReleaseReadyCheck(
      ReleaseReadyOptions(
        version: '1.2.3',
        build: '45',
        tag: 'v1.2.3+45',
        workingDirectory: tempDir.path,
      ),
    );

    expect(report.ok, isTrue);
    expect(report.pubspecVersion, '1.2.3');
    expect(report.pubspecBuild, '45');
    expect(report.commit, isNotEmpty);
    expect(_check(report, 'tagAvailable').ok, isTrue);
  });

  test('detects dirty worktree', () async {
    _writeProject(tempDir);
    await _git(tempDir, <String>['init']);
    await _git(tempDir, <String>['config', 'user.email', 'test@example.com']);
    await _git(tempDir, <String>['config', 'user.name', 'Test User']);
    await _git(tempDir, <String>['add', '.']);
    await _git(tempDir, <String>['commit', '-m', 'Initial commit']);
    File('${tempDir.path}/README.md').writeAsStringSync('dirty');

    final ReleaseReadyReport report = await runReleaseReadyCheck(
      ReleaseReadyOptions(workingDirectory: tempDir.path),
    );

    expect(report.ok, isFalse);
    expect(_check(report, 'gitClean').ok, isFalse);
  });

  test('detects existing tag', () async {
    _writeProject(tempDir);
    await _git(tempDir, <String>['init']);
    await _git(tempDir, <String>['config', 'user.email', 'test@example.com']);
    await _git(tempDir, <String>['config', 'user.name', 'Test User']);
    await _git(tempDir, <String>['add', '.']);
    await _git(tempDir, <String>['commit', '-m', 'Initial commit']);
    await _git(tempDir, <String>['tag', 'v1.2.3+45']);

    final ReleaseReadyReport report = await runReleaseReadyCheck(
      ReleaseReadyOptions(tag: 'v1.2.3+45', workingDirectory: tempDir.path),
    );

    expect(report.ok, isFalse);
    expect(_check(report, 'tagAvailable').ok, isFalse);
  });

  test('calculates SHA-256 for existing artifacts', () async {
    _writeProject(tempDir);
    File('${tempDir.path}/app.apk').writeAsStringSync('apk bytes');
    await _git(tempDir, <String>['init']);
    await _git(tempDir, <String>['config', 'user.email', 'test@example.com']);
    await _git(tempDir, <String>['config', 'user.name', 'Test User']);
    await _git(tempDir, <String>['add', '.']);
    await _git(tempDir, <String>['commit', '-m', 'Initial commit']);

    final ReleaseReadyReport report = await runReleaseReadyCheck(
      ReleaseReadyOptions(androidApkPath: 'app.apk', workingDirectory: tempDir.path),
    );

    expect(report.ok, isTrue);
    expect(report.artifacts.single.platform, 'android');
    expect(
      report.artifacts.single.sha256,
      '9379cfb95416438572c33e2c2e03f1fdbdb10e4668cfbdb7bbd0e3049463ac33',
    );
  });

  test('reports missing IPA path clearly', () async {
    _writeProject(tempDir);
    await _git(tempDir, <String>['init']);
    await _git(tempDir, <String>['config', 'user.email', 'test@example.com']);
    await _git(tempDir, <String>['config', 'user.name', 'Test User']);
    await _git(tempDir, <String>['add', '.']);
    await _git(tempDir, <String>['commit', '-m', 'Initial commit']);

    final ReleaseReadyReport report = await runReleaseReadyCheck(
      ReleaseReadyOptions(iosIpaPath: 'missing.ipa', workingDirectory: tempDir.path),
    );

    expect(report.ok, isFalse);
    expect(_check(report, 'iosArtifact').message, contains('missing.ipa'));
  });

  test('formats JSON output with check and artifact fields', () async {
    final ReleaseReadyReport report = ReleaseReadyReport(
      ok: true,
      commit: 'abc123',
      pubspecVersion: '1.2.3',
      pubspecBuild: '45',
      checks: const <ReleaseCheck>[
        ReleaseCheck(name: 'gitClean', ok: true, message: 'clean'),
      ],
      artifacts: const <ReleaseArtifact>[
        ReleaseArtifact(
          platform: 'android',
          path: 'app.apk',
          exists: true,
          sha256: 'digest',
        ),
      ],
    );

    final Object? decoded = jsonDecode(const JsonEncoder().convert(report.toJson()));

    expect(decoded, isA<Map<String, Object?>>());
    final Map<String, Object?> json = decoded! as Map<String, Object?>;
    expect(json['ok'], isTrue);
    expect(json['commit'], 'abc123');
    expect(json['checks'], isA<List<Object?>>());
    expect(json['artifacts'], isA<List<Object?>>());
  });
}

ReleaseCheck _check(ReleaseReadyReport report, String name) {
  return report.checks.singleWhere((ReleaseCheck check) => check.name == name);
}

void _writeProject(Directory directory) {
  File('${directory.path}/pubspec.yaml').writeAsStringSync('''
name: fake
version: 1.2.3+45
''');
  File('${directory.path}/CHANGELOG.md').writeAsStringSync('''
# Changelog

## Unreleased

- Pending release notes.
''');
  File('${directory.path}/README.md').writeAsStringSync('fake');
}

Future<void> _git(Directory directory, List<String> arguments) async {
  final ProcessResult result = await Process.run(
    'git',
    arguments,
    workingDirectory: directory.path,
  );
  if (result.exitCode != 0) {
    fail('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

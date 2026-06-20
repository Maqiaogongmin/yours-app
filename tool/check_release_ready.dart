import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

typedef ProcessRun =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

class ReleaseReadyOptions {
  const ReleaseReadyOptions({
    this.version,
    this.build,
    this.tag,
    this.androidApkPath,
    this.iosIpaPath,
    this.jsonOutput = false,
    this.workingDirectory,
  });

  final String? version;
  final String? build;
  final String? tag;
  final String? androidApkPath;
  final String? iosIpaPath;
  final bool jsonOutput;
  final String? workingDirectory;
}

class ReleaseReadyReport {
  const ReleaseReadyReport({
    required this.ok,
    required this.commit,
    required this.pubspecVersion,
    required this.pubspecBuild,
    required this.checks,
    required this.artifacts,
  });

  final bool ok;
  final String? commit;
  final String? pubspecVersion;
  final String? pubspecBuild;
  final List<ReleaseCheck> checks;
  final List<ReleaseArtifact> artifacts;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ok': ok,
      'commit': commit,
      'pubspecVersion': pubspecVersion,
      'pubspecBuild': pubspecBuild,
      'checks': checks.map((ReleaseCheck check) => check.toJson()).toList(),
      'artifacts': artifacts.map((ReleaseArtifact artifact) => artifact.toJson()).toList(),
    };
  }
}

class ReleaseCheck {
  const ReleaseCheck({
    required this.name,
    required this.ok,
    required this.message,
  });

  final String name;
  final bool ok;
  final String message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'ok': ok,
      'message': message,
    };
  }
}

class ReleaseArtifact {
  const ReleaseArtifact({
    required this.platform,
    required this.path,
    required this.exists,
    this.sha256,
  });

  final String platform;
  final String path;
  final bool exists;
  final String? sha256;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'platform': platform,
      'path': path,
      'exists': exists,
      'sha256': sha256,
    };
  }
}

Future<void> main(List<String> arguments) async {
  final ReleaseReadyOptions options;
  try {
    options = parseReleaseReadyOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final ReleaseReadyReport report = await runReleaseReadyCheck(options);
  if (options.jsonOutput) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    stdout.write(formatReleaseReadyReport(report));
  }
  exitCode = report.ok ? 0 : 1;
}

ReleaseReadyOptions parseReleaseReadyOptions(List<String> arguments) {
  String? version;
  String? build;
  String? tag;
  String? androidApkPath;
  String? iosIpaPath;
  bool jsonOutput = false;

  var index = 0;
  while (index < arguments.length) {
    final String argument = arguments[index];
    if (argument == '--json') {
      jsonOutput = true;
      index += 1;
      continue;
    }
    if (argument == '-h' || argument == '--help') {
      throw const FormatException(_usage);
    }

    final String value = _readOptionValue(arguments, index, argument);
    if (argument == '--version') {
      version = value;
    } else if (argument == '--build') {
      build = value;
    } else if (argument == '--tag') {
      tag = value;
    } else if (argument == '--android-apk') {
      androidApkPath = value;
    } else if (argument == '--ios-ipa') {
      iosIpaPath = value;
    } else {
      throw FormatException('Unknown option: $argument');
    }
    index += 2;
  }

  return ReleaseReadyOptions(
    version: version,
    build: build,
    tag: tag,
    androidApkPath: androidApkPath,
    iosIpaPath: iosIpaPath,
    jsonOutput: jsonOutput,
  );
}

Future<ReleaseReadyReport> runReleaseReadyCheck(
  ReleaseReadyOptions options, {
  ProcessRun processRun = Process.run,
}) async {
  final String workingDirectory = options.workingDirectory ?? Directory.current.path;
  final List<ReleaseCheck> checks = <ReleaseCheck>[];
  final List<ReleaseArtifact> artifacts = <ReleaseArtifact>[];

  final ProcessResult commitResult = await processRun(
    'git',
    <String>['rev-parse', 'HEAD'],
    workingDirectory: workingDirectory,
  );
  final bool commitOk = commitResult.exitCode == 0 && _stdoutText(commitResult).isNotEmpty;
  final String? commit = commitOk ? _stdoutText(commitResult).trim() : null;
  checks.add(
    ReleaseCheck(
      name: 'gitCommit',
      ok: commitOk,
      message: commitOk ? 'Current commit: $commit' : 'Cannot resolve current git commit.',
    ),
  );

  final ProcessResult statusResult = await processRun(
    'git',
    <String>['status', '--porcelain'],
    workingDirectory: workingDirectory,
  );
  final String status = _stdoutText(statusResult).trim();
  final bool clean = statusResult.exitCode == 0 && status.isEmpty;
  checks.add(
    ReleaseCheck(
      name: 'gitClean',
      ok: clean,
      message: clean ? 'Working tree is clean.' : 'Working tree has uncommitted changes.',
    ),
  );

  String? pubspecVersion;
  String? pubspecBuild;
  final File pubspec = File('$workingDirectory/pubspec.yaml');
  if (pubspec.existsSync()) {
    try {
      final Object? yaml = loadYaml(pubspec.readAsStringSync());
      final Object? versionValue = yaml is YamlMap ? yaml['version'] : null;
      final RegExpMatch? match = _pubspecVersionPattern.firstMatch('$versionValue');
      if (match == null) {
        checks.add(
          const ReleaseCheck(
            name: 'pubspecVersion',
            ok: false,
            message: 'pubspec.yaml version must be in version+build format.',
          ),
        );
      } else {
        pubspecVersion = match.group(1);
        pubspecBuild = match.group(2);
        checks.add(
          ReleaseCheck(
            name: 'pubspecVersion',
            ok: true,
            message: 'pubspec.yaml version: $pubspecVersion+$pubspecBuild',
          ),
        );
      }
    } on Object catch (error) {
      checks.add(
        ReleaseCheck(
          name: 'pubspecVersion',
          ok: false,
          message: 'Cannot read pubspec.yaml version: $error',
        ),
      );
    }
  } else {
    checks.add(
      const ReleaseCheck(
        name: 'pubspecVersion',
        ok: false,
        message: 'pubspec.yaml is missing.',
      ),
    );
  }

  if (options.version != null && pubspecVersion != null) {
    checks.add(
      ReleaseCheck(
        name: 'versionArgument',
        ok: options.version == pubspecVersion,
        message: options.version == pubspecVersion
            ? 'Requested version matches pubspec.yaml.'
            : 'Requested version ${options.version} does not match pubspec.yaml $pubspecVersion.',
      ),
    );
  }

  if (options.build != null && pubspecBuild != null) {
    checks.add(
      ReleaseCheck(
        name: 'buildArgument',
        ok: options.build == pubspecBuild,
        message: options.build == pubspecBuild
            ? 'Requested build matches pubspec.yaml.'
            : 'Requested build ${options.build} does not match pubspec.yaml $pubspecBuild.',
      ),
    );
  }

  final String? changelogVersion = options.version ?? pubspecVersion;
  checks.add(_checkChangelog(workingDirectory, changelogVersion));

  if (options.tag != null) {
    final ProcessResult tagResult = await processRun(
      'git',
      <String>['rev-parse', '--verify', '--quiet', 'refs/tags/${options.tag}'],
      workingDirectory: workingDirectory,
    );
    final bool tagAvailable = tagResult.exitCode != 0;
    checks.add(
      ReleaseCheck(
        name: 'tagAvailable',
        ok: tagAvailable,
        message: tagAvailable
            ? 'Tag ${options.tag} does not exist yet.'
            : 'Tag ${options.tag} already exists and must not be reused.',
      ),
    );
  }

  if (options.androidApkPath != null) {
    artifacts.add(_readArtifact('android', workingDirectory, options.androidApkPath!));
  }
  if (options.iosIpaPath != null) {
    artifacts.add(_readArtifact('ios', workingDirectory, options.iosIpaPath!));
  }
  for (final ReleaseArtifact artifact in artifacts) {
    checks.add(
      ReleaseCheck(
        name: '${artifact.platform}Artifact',
        ok: artifact.exists,
        message: artifact.exists
            ? '${artifact.platform} artifact SHA-256: ${artifact.sha256}'
            : '${artifact.platform} artifact not found: ${artifact.path}',
      ),
    );
  }

  final bool ok = checks.every((ReleaseCheck check) => check.ok);
  return ReleaseReadyReport(
    ok: ok,
    commit: commit,
    pubspecVersion: pubspecVersion,
    pubspecBuild: pubspecBuild,
    checks: checks,
    artifacts: artifacts,
  );
}

String formatReleaseReadyReport(ReleaseReadyReport report) {
  final StringBuffer buffer = StringBuffer()
    ..writeln(report.ok ? 'Release readiness: PASS' : 'Release readiness: FAIL')
    ..writeln();
  for (final ReleaseCheck check in report.checks) {
    buffer.writeln('${check.ok ? '[PASS]' : '[FAIL]'} ${check.name}: ${check.message}');
  }
  if (report.artifacts.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('Artifacts:');
    for (final ReleaseArtifact artifact in report.artifacts) {
      buffer.writeln(
        '- ${artifact.platform}: ${artifact.path}'
        '${artifact.sha256 == null ? '' : ' (${artifact.sha256})'}',
      );
    }
  }
  return buffer.toString();
}

ReleaseCheck _checkChangelog(String workingDirectory, String? version) {
  final File changelog = File('$workingDirectory/CHANGELOG.md');
  if (!changelog.existsSync()) {
    return const ReleaseCheck(
      name: 'changelog',
      ok: false,
      message: 'CHANGELOG.md is missing.',
    );
  }

  final String text = changelog.readAsStringSync();
  if (version != null) {
    final String versionHeaderPattern =
        '^## +${RegExp.escape(version)}'
        r'(?:\s|$)';
    if (RegExp(versionHeaderPattern, multiLine: true).hasMatch(text)) {
      return ReleaseCheck(
        name: 'changelog',
        ok: true,
        message: 'CHANGELOG.md contains a $version section.',
      );
    }
  }
  if (RegExp(r'^## +Unreleased(?:\s|$)', multiLine: true).hasMatch(text)) {
    return const ReleaseCheck(
      name: 'changelog',
      ok: true,
      message: 'CHANGELOG.md still tracks this release under Unreleased.',
    );
  }
  return ReleaseCheck(
    name: 'changelog',
    ok: false,
    message: version == null
        ? 'CHANGELOG.md must contain Unreleased or a version section.'
        : 'CHANGELOG.md must contain a $version section or Unreleased.',
  );
}

ReleaseArtifact _readArtifact(String platform, String workingDirectory, String artifactPath) {
  final File file = File(artifactPath).isAbsolute
      ? File(artifactPath)
      : File('$workingDirectory/$artifactPath');
  if (!file.existsSync()) {
    return ReleaseArtifact(platform: platform, path: artifactPath, exists: false);
  }
  final Digest digest = sha256.convert(file.readAsBytesSync());
  return ReleaseArtifact(
    platform: platform,
    path: artifactPath,
    exists: true,
    sha256: digest.toString(),
  );
}

String _readOptionValue(List<String> arguments, int index, String option) {
  if (!option.startsWith('--')) {
    throw FormatException('Unknown option: $option');
  }
  final int valueIndex = index + 1;
  if (valueIndex >= arguments.length || arguments[valueIndex].startsWith('--')) {
    throw FormatException('Missing value for $option.');
  }
  return arguments[valueIndex];
}

String _stdoutText(ProcessResult result) {
  return result.stdout is List<int> ? utf8.decode(result.stdout as List<int>) : '${result.stdout}';
}

final RegExp _pubspecVersionPattern = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$');

const String _usage = '''
Usage: dart run tool/check_release_ready.dart [options]

Options:
  --version <x.y.z>      Expected app display version.
  --build <number>      Expected build number / versionCode.
  --tag <tag>           Expected release tag; must not already exist.
  --android-apk <path>  Optional APK path to hash with SHA-256.
  --ios-ipa <path>      Optional IPA path to hash with SHA-256.
  --json                Print structured JSON output.
''';

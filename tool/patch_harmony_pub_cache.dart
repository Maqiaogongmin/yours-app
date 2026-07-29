import 'dart:io';

Future<void> main() async {
  final String packagePath =
      Platform.environment['FLEX_COLOR_SCHEME_PATH'] ??
      '${Platform.environment['PUB_CACHE'] ?? '.dart_tool/pub-cache-ohos'}/hosted/pub.dev/flex_color_scheme-8.4.0';
  final Directory packageDirectory = Directory(packagePath);
  if (!packageDirectory.existsSync()) {
    stderr.writeln('flex_color_scheme package not found at $packagePath');
    exitCode = 1;
    return;
  }

  _patchFile(
    File('${packageDirectory.path}/lib/src/flex_adaptive.dart'),
    <String, String>{
      'case TargetPlatform.android:\n          return androidWeb;':
          'case TargetPlatform.android:\n        case TargetPlatform.ohos:\n          return androidWeb;',
      'case TargetPlatform.android:\n          return android;':
          'case TargetPlatform.android:\n        case TargetPlatform.ohos:\n          return android;',
    },
  );

  _patchFile(
    File('${packageDirectory.path}/lib/src/flex_color_scheme.dart'),
    <String, String>{
      'case TargetPlatform.android:\n      case TargetPlatform.iOS:\n      case TargetPlatform.fuchsia:':
          'case TargetPlatform.android:\n      case TargetPlatform.ohos:\n      case TargetPlatform.iOS:\n      case TargetPlatform.fuchsia:',
      'case TargetPlatform.android:\n          return 14;':
          'case TargetPlatform.android:\n        case TargetPlatform.ohos:\n          return 14;',
    },
  );

  stdout.writeln('Patched flex_color_scheme for Flutter-OH at $packagePath');
}

void _patchFile(File file, Map<String, String> replacements) {
  if (!file.existsSync()) {
    throw StateError('Missing file: ${file.path}');
  }
  var contents = file.readAsStringSync();
  for (final MapEntry<String, String> replacement in replacements.entries) {
    if (contents.contains(replacement.value)) {
      continue;
    }
    if (!contents.contains(replacement.key)) {
      throw StateError('Patch anchor not found in ${file.path}');
    }
    contents = contents.replaceFirst(replacement.key, replacement.value);
  }
  file.writeAsStringSync(contents);
}

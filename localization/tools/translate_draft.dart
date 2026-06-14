import 'dart:convert';
import 'dart:io';

import 'localization_manifest.dart';

const _concurrency = 8;
final _placeholderPattern = RegExp(r'\{[A-Za-z][A-Za-z0-9_]*\}');

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run localization/tools/translate_draft.dart '
      '<source-locale> <target-locale> <target-language-code>',
    );
    exitCode = 64;
    return;
  }

  final root = projectRoot();
  final sourcePath = '${root.path}/localization/${arguments[0]}/strings.arb';
  final targetPath = '${root.path}/localization/${arguments[1]}/strings.arb';
  final source = jsonDecode(File(sourcePath).readAsStringSync()) as Map<String, dynamic>;
  final output = <String, dynamic>{};
  final messages = source.entries
      .where((entry) => !entry.key.startsWith('@'))
      .toList(growable: false);

  var cursor = 0;
  Future<void> worker() async {
    final client = HttpClient();
    try {
      while (cursor < messages.length) {
        final index = cursor++;
        final entry = messages[index];
        output[entry.key] = await _translate(
          client,
          entry.value as String,
          targetLanguage: arguments[2],
        );
        final metadata = source['@${entry.key}'];
        if (metadata != null) {
          output['@${entry.key}'] = metadata;
        }
        stdout.writeln('${index + 1}/${messages.length} ${entry.key}');
      }
    } finally {
      client.close(force: true);
    }
  }

  await Future.wait(List.generate(_concurrency, (_) => worker()));
  output['@@locale'] = arguments[2];

  final ordered = <String, dynamic>{'@@locale': arguments[2]};
  for (final entry in source.entries) {
    if (entry.key == '@@locale') {
      continue;
    }
    ordered[entry.key] = output[entry.key];
  }
  File(targetPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(ordered)}\n',
  );
}

Future<String> _translate(
  HttpClient client,
  String message, {
  required String targetLanguage,
}) async {
  final placeholders = <String>[];
  final protected = message.replaceAllMapped(_placeholderPattern, (match) {
    placeholders.add(match.group(0)!);
    return 'ZXQPH${placeholders.length - 1}QXZ';
  });
  final uri = Uri.https(
    'translate.googleapis.com',
    '/translate_a/single',
    {
      'client': 'gtx',
      'sl': 'en',
      'tl': targetLanguage,
      'dt': 't',
      'q': protected,
    },
  );
  Object? lastError;
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw HttpException('Translation returned ${response.statusCode}');
      }
      final decoded = jsonDecode(body) as List<dynamic>;
      var translated = (decoded.first as List<dynamic>)
          .map((part) => (part as List<dynamic>).first as String)
          .join();
      for (var index = 0; index < placeholders.length; index++) {
        translated = translated.replaceAll(
          RegExp('ZXQPH\\s*$index\\s*QXZ', caseSensitive: false),
          placeholders[index],
        );
      }
      return translated;
    } on Object catch (error) {
      lastError = error;
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }
  throw StateError('Could not translate "$message": $lastError');
}

import 'dart:convert';
import 'dart:io';

const _scanRoots = [
  'lib/redesign/pages',
  'lib/redesign/navigation',
];

const _patterns = <String, String>{
  'raw color': r'Color\(0x',
  'local text style': r'TextStyle\(',
  'local shadow': r'BoxShadow\(',
};

const _allowedFiles = <String>{
  'lib/redesign/design_system/yours_design_tokens.dart',
  'lib/redesign/design_system/yours_components.dart',
  'lib/redesign/design_system/yours_patterns.dart',
  'lib/redesign/theme/redesign_theme.dart',
};

const _baselinePath = 'tool/ui_guard_baseline.json';

void main(List<String> args) {
  final strict = args.contains('--strict');
  final strictNew = args.contains('--strict-new');
  final updateBaseline = args.contains('--update-baseline');
  final root = Directory.current;
  final findings = _scanFindings(root);

  if (updateBaseline) {
    _writeBaseline(root, findings);
    stdout.writeln('Updated $_baselinePath with ${findings.length} findings.');
    return;
  }

  final displayedFindings = strictNew ? _newFindings(root, findings) : findings;

  if (displayedFindings.isEmpty) {
    stdout.writeln(
      strictNew
          ? 'Yours UI guard passed: no new local visual decisions.'
          : 'Yours UI guard passed.',
    );
    return;
  }

  stdout.writeln(
    strictNew
        ? 'Yours UI guard found new local visual decisions:'
        : 'Yours UI guard found local visual decisions:',
  );
  for (final finding in displayedFindings.take(80)) {
    stdout.writeln('- ${finding.display}');
  }
  if (displayedFindings.length > 80) {
    stdout.writeln('- ... ${displayedFindings.length - 80} more');
  }
  stdout.writeln('');
  stdout.writeln('Move new UI styling into lib/redesign/design_system/ or add ');
  stdout.writeln('// yours-ui-guard: allow with a short reason for intentional exceptions.');
  stdout.writeln('');

  if (strict || strictNew) {
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Report-only mode: existing history is not failed by default. '
    'Use --strict-new for CI.',
  );
}

List<_Finding> _scanFindings(Directory root) {
  final findings = <_Finding>[];
  for (final relativeRoot in _scanRoots) {
    final directory = Directory('${root.path}/$relativeRoot');
    if (!directory.existsSync()) {
      continue;
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final relativePath = entity.path.substring(root.path.length + 1);
      if (_allowedFiles.contains(relativePath)) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('yours-ui-guard: allow')) {
          continue;
        }
        for (final entry in _patterns.entries) {
          if (RegExp(entry.value).hasMatch(line)) {
            findings.add(
              _Finding(
                path: relativePath,
                line: index + 1,
                kind: entry.key,
                source: line.trim().replaceAll(RegExp(r'\s+'), ' '),
              ),
            );
          }
        }
      }
    }
  }
  return findings;
}

List<_Finding> _newFindings(Directory root, List<_Finding> findings) {
  final file = File('${root.path}/$_baselinePath');
  if (!file.existsSync()) {
    stderr.writeln(
      'Missing $_baselinePath. Run '
      '`dart run tool/check_ui_guard.dart --update-baseline` once.',
    );
    exitCode = 2;
    return findings;
  }
  final decoded = jsonDecode(file.readAsStringSync());
  final baseline = <String, int>{
    for (final entry in (decoded as Map<String, dynamic>).entries)
      entry.key: (entry.value as num).toInt(),
  };
  final consumed = <String, int>{};
  return findings.where((finding) {
    final used = consumed.update(finding.signature, (value) => value + 1, ifAbsent: () => 1);
    return used > (baseline[finding.signature] ?? 0);
  }).toList();
}

void _writeBaseline(Directory root, List<_Finding> findings) {
  final counts = <String, int>{};
  for (final finding in findings) {
    counts.update(finding.signature, (value) => value + 1, ifAbsent: () => 1);
  }
  final sorted = Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  const encoder = JsonEncoder.withIndent('  ');
  File('${root.path}/$_baselinePath').writeAsStringSync('${encoder.convert(sorted)}\n');
}

class _Finding {
  const _Finding({
    required this.path,
    required this.line,
    required this.kind,
    required this.source,
  });

  final String path;
  final int line;
  final String kind;
  final String source;

  String get signature => '$path|$kind|$source';
  String get display => '$path:$line: $kind: $source';
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/harmony_sqlite.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';

part 'yours_vault_exercise_import.dart';
part 'yours_vault_export.dart';
part 'yours_vault_import.dart';
part 'yours_vault_models.dart';

class YoursVaultService
    with _YoursVaultExportMixin, _YoursVaultImportMixin, _YoursVaultExerciseImportMixin {
  static const _visibleFilesChannel = MethodChannel('yours/files');

  final LocalTrainingDatabase? _trainingDbOverride;
  final CustomExerciseDatabase? _exerciseDbOverride;
  final bool? _nativeInboxBridgeOverride;

  YoursVaultService({
    LocalTrainingDatabase? trainingDb,
    CustomExerciseDatabase? exerciseDb,
    bool? nativeInboxBridgeOverride,
  }) : _trainingDbOverride = trainingDb,
       _exerciseDbOverride = exerciseDb,
       _nativeInboxBridgeOverride = nativeInboxBridgeOverride;

  @override
  LocalTrainingDatabase get _trainingDb =>
      _trainingDbOverride ??
      (locator.isRegistered<LocalTrainingDatabase>()
          ? locator<LocalTrainingDatabase>()
          : throw StateError('训练数据库尚未就绪，请稍后再试。'));

  @override
  CustomExerciseDatabase get _exerciseDb =>
      _exerciseDbOverride ??
      (locator.isRegistered<CustomExerciseDatabase>()
          ? locator<CustomExerciseDatabase>()
          : throw StateError('动作数据库尚未就绪，请稍后再试。'));

  @override
  Future<int> Function(Object?, CustomExerciseRepository) get _exerciseInboxImporter =>
      _importExerciseInboxFile;

  Future<Directory> defaultVaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'YoursVault'));
  }

  Future<YoursVaultExportResult> exportDefaultVault() async {
    final result = await exportVault(await defaultVaultDirectory());
    if (Platform.isAndroid) {
      unawaited(_syncVaultToVisibleDocuments(result.directory));
    } else {
      await _syncVaultToVisibleDocuments(result.directory);
    }
    return result;
  }

  Future<YoursVaultImportResult> importDefaultInbox() async {
    final result = await importInbox(await defaultVaultDirectory());
    return result.copyWith(scannedSources: const ['本机']);
  }

  /// Imports the inboxes exported by Yours without asking the user to select a
  /// folder. Native code stages files from platform-visible Vault locations and
  /// archives successful imports back to their original inboxes.
  Future<YoursVaultImportResult> importAutomaticInbox() async {
    final useNativeInboxBridge =
        _nativeInboxBridgeOverride ?? (Platform.isIOS || Platform.isAndroid || isHarmonyOS);
    if (!useNativeInboxBridge) {
      return importDefaultInbox();
    }

    final selection = await _prepareDefaultVaultInbox();

    var importedFiles = const <String>[];
    var completionAttempted = false;
    try {
      var result = await importInbox(
        selection.stagingDirectory,
        archiveImportedFiles: false,
      );
      if (selection.conflictFiles.isNotEmpty) {
        final conflicts = selection.conflictFiles
            .map(
              (fileName) => YoursVaultImportFileResult(
                fileName: fileName,
                type: 'unknown',
                status: 'failed',
                message: '同名文件在多个 inbox 中内容不同，未导入。',
              ),
            )
            .toList();
        result = result.copyWith(
          skippedFiles: [...result.skippedFiles, ...selection.conflictFiles],
          fileResults: [...result.fileResults, ...conflicts],
        );
      }
      importedFiles = result.importedFiles;
      completionAttempted = true;
      final archiveFailures = await _completeVaultInboxImport(
        selection.token,
        importedFiles,
      );
      return result.copyWith(
        archiveFailures: archiveFailures,
        scannedSources: selection.scannedSources,
        unavailableSources: selection.unavailableSources,
      );
    } finally {
      if (!completionAttempted) {
        await _completeVaultInboxImport(selection.token, importedFiles);
      }
    }
  }

  Future<_YoursVaultInboxSelection> _prepareDefaultVaultInbox() async {
    final raw = await _visibleFilesChannel.invokeMethod<Map<Object?, Object?>>(
      'prepareDefaultVaultInboxImport',
    );
    if (raw == null) {
      throw StateError('默认 YoursVault inbox 不可用。');
    }
    final token = raw['token'] as String?;
    final stagingPath = raw['stagingPath'] as String?;
    if (token == null || token.isEmpty || stagingPath == null || stagingPath.isEmpty) {
      throw StateError('默认 YoursVault inbox 无效。');
    }
    return _YoursVaultInboxSelection(
      token: token,
      stagingDirectory: Directory(stagingPath),
      scannedSources: _stringList(raw['scannedSources']),
      unavailableSources: _stringList(raw['unavailableSources']),
      conflictFiles: _stringList(raw['conflictFiles']),
    );
  }

  List<String> _stringList(Object? value) {
    if (value is! List<Object?>) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  Future<List<String>> _completeVaultInboxImport(
    String token,
    List<String> importedFiles,
  ) async {
    final raw = await _visibleFilesChannel.invokeMethod<List<Object?>>(
      'completeVaultInboxImport',
      {'token': token, 'importedFiles': importedFiles},
    );
    return raw?.whereType<String>().toList() ?? const [];
  }

  Future<void> _syncVaultToVisibleDocuments(Directory directory) async {
    if (!Platform.isAndroid && !Platform.isIOS && !isHarmonyOS) {
      return;
    }
    try {
      if (Platform.isIOS) {
        await _visibleFilesChannel.invokeMethod<String>(
          'exportVaultToICloudDrive',
          {'path': directory.path},
        );
      } else {
        await _visibleFilesChannel.invokeMethod<int>(
          'syncVaultToPublicDocuments',
          {'path': directory.path},
        );
      }
    } on MissingPluginException {
      if (Platform.isIOS) {
        throw StateError('当前安装包缺少 iCloud Drive 文件通道。');
      }
      return;
    } on PlatformException catch (error) {
      if (Platform.isIOS) {
        final message = error.message?.trim();
        throw StateError(
          message == null || message.isEmpty ? 'iCloud Drive 导出失败。' : message,
        );
      }
      if (isHarmonyOS) {
        final message = error.message?.trim();
        throw StateError(
          message == null || message.isEmpty ? '鸿蒙可见目录导出失败。' : message,
        );
      }
      return;
    }
  }

  @override
  Future<void> _writeJson(File file, Object? data) async {
    file.parent.createSync(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }

  @override
  Future<void> _archiveInboxFile(File file, String folderName) async {
    final destinationDir = Directory(p.join(file.parent.path, folderName))
      ..createSync(recursive: true);
    final destination = File(p.join(destinationDir.path, p.basename(file.path)));
    if (destination.existsSync()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await file.rename(p.join(destinationDir.path, '$timestamp-${p.basename(file.path)}'));
      return;
    }
    await file.rename(destination.path);
  }

  @override
  List<String> _decodeStringList(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<Set<String>> _exerciseKeys() async {
    final rows = await (_exerciseDb.select(
      _exerciseDb.customExercises,
    )..where((row) => row.deleted.equals(false))).get();
    final keys = <String>{};
    for (final row in rows) {
      keys.add(_normalizeExerciseKey(row.chineseName));
      keys.add(
        _normalizeExerciseKey(canonicalExerciseReference(row.chineseName)),
      );
      if (row.englishName.trim().isNotEmpty) {
        keys.add(_normalizeExerciseKey(row.englishName));
        keys.add(
          _normalizeExerciseKey(
            canonicalExerciseReference(row.englishName),
          ),
        );
      }
      final reference = builtInExerciseReferenceForRemoteId(row.remoteId);
      if (reference != null) {
        keys.add(_normalizeExerciseKey(reference));
      }
    }
    return keys;
  }

  @override
  List<String> _missingExercises(LocalTrainingPlanModel plan, Set<String> exerciseKeys) {
    final missing = <String>[];
    final seen = <String>{};
    for (final day in plan.days.values) {
      for (final action in day.actions) {
        final key = _normalizeExerciseKey(
          canonicalExerciseReference(action.name),
        );
        if (!exerciseKeys.contains(key) && seen.add(key)) {
          missing.add(action.name);
        }
      }
    }
    return missing;
  }

  @override
  String _normalizeExerciseKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  @override
  String _friendlyImportError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    final message = '$error'.trim();
    return message.isEmpty ? '导入失败。' : message;
  }

  @override
  String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'untitled-plan' : slug;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/yours_exception.dart';

class BackupArchiveService {
  BackupArchiveService({
    required BackupPreferencesStore preferences,
    required int serverProtocolVersion,
  }) : _preferences = preferences,
       _serverProtocolVersion = serverProtocolVersion;

  static const _backupFormatVersion = 1;
  static const _restoreSafetyFileName = 'yours-restore-safety.zip';
  static const _trainingDbName = 'local_training.sqlite';
  static const _exerciseDbName = 'custom_exercises.sqlite';

  final BackupPreferencesStore _preferences;
  final int _serverProtocolVersion;

  Future<BackupResult> writeBackupFile(File output) async {
    final docs = await getApplicationDocumentsDirectory();
    final createdAt = DateTime.now();
    final encoder = ZipFileEncoder();
    final files = <BackupManifestFile>[];

    encoder.create(output.path);
    try {
      final trainingFiles = await _databaseFiles(docs, _trainingDbName);
      final exerciseFiles = await _databaseFiles(docs, _exerciseDbName);
      for (final file in [...trainingFiles, ...exerciseFiles]) {
        final archiveName = 'databases/${p.basename(file.path)}';
        await encoder.addFile(file, archiveName);
        files.add(await _describeFile(file, archiveName));
      }

      final imageFiles = await _collectExerciseImages(docs);
      for (final file in imageFiles) {
        final archiveName = 'images/exercises/${p.basename(file.path)}';
        await encoder.addFile(file, archiveName);
        files.add(await _describeFile(file, archiveName));
      }

      final appSettings = await _preferences.readAppSettings();
      final appSettingsText = const JsonEncoder.withIndent('  ').convert(appSettings);
      encoder.addArchiveFile(ArchiveFile.string('settings/app_settings.json', appSettingsText));
      files.add(_describeText('settings/app_settings.json', appSettingsText));

      final syncSettings = await _preferences.syncSettingsForBackup(
        createdAt: createdAt,
        protocolVersion: _serverProtocolVersion,
      );
      final syncSettingsText = const JsonEncoder.withIndent('  ').convert(syncSettings);
      encoder.addArchiveFile(ArchiveFile.string('settings/sync_settings.json', syncSettingsText));
      files.add(_describeText('settings/sync_settings.json', syncSettingsText));

      final manifestText = const JsonEncoder.withIndent('  ').convert(
        _manifest(
          createdAt: createdAt,
          files: files,
          appSettings: appSettings,
          syncSettings: syncSettings,
        ),
      );
      encoder.addArchiveFile(ArchiveFile.string('manifest.json', manifestText));
      files.add(_describeText('manifest.json', manifestText));
    } finally {
      await encoder.close();
    }

    final size = output.lengthSync();
    return BackupResult(
      file: output,
      fileCount: files.length,
      byteCount: size,
      createdAt: createdAt,
    );
  }

  Future<RestoreResult> restoreBackup(File backup) async {
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }

    final safetyBackup = (await createRestoreSafetyBackup()).file;
    final docs = await getApplicationDocumentsDirectory();
    final bytes = await backup.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final manifest = archive.findFile('manifest.json');
    if (manifest == null) {
      throw const YoursException(YoursErrorCode.backupManifestMissing);
    }

    final dbFiles = archive.files
        .where((file) => file.isFile && file.name.startsWith('databases/'))
        .toList();
    if (dbFiles.where((file) => p.basename(file.name) == _trainingDbName).isEmpty ||
        dbFiles.where((file) => p.basename(file.name) == _exerciseDbName).isEmpty) {
      throw const YoursException(YoursErrorCode.backupDatabaseMissing);
    }

    await _closeOpenDatabases();
    var restored = 0;
    for (final file in dbFiles) {
      final name = p.basename(file.name);
      final output = File(p.join(docs.path, name));
      if (name == _trainingDbName || name == _exerciseDbName) {
        await _deleteDatabaseFamily(docs, name);
      }
      await output.writeAsBytes(file.readBytes() ?? const []);
      restored += 1;
    }

    final imageFiles = archive.files
        .where((file) => file.isFile && file.name.startsWith('images/exercises/'))
        .toList();
    final imageDir = Directory(p.join(docs.path, 'exercise_images'));
    if (!imageDir.existsSync()) {
      imageDir.createSync(recursive: true);
    }
    for (final file in imageFiles) {
      final output = File(p.join(imageDir.path, p.basename(file.name)));
      await output.writeAsBytes(file.readBytes() ?? const []);
      restored += 1;
    }

    final appSettings = archive.findFile('settings/app_settings.json');
    if (appSettings != null) {
      await _restoreAppSettings(appSettings);
      restored += 1;
    }

    final syncSettings = archive.findFile('settings/sync_settings.json');
    if (syncSettings != null) {
      final settingsText = utf8.decode(syncSettings.readBytes() ?? const []);
      await _preferences.saveRestoredSyncSettingsText(settingsText);
      restored += 1;
    }

    await _reopenLocalDatabases();

    return RestoreResult(
      source: backup,
      safetyBackup: safetyBackup,
      restoredFileCount: restored,
    );
  }

  Future<int?> serverCursorFromBackup(File backup) async {
    try {
      final archive = ZipDecoder().decodeBytes(await backup.readAsBytes(), verify: true);
      final settings = archive.findFile('settings/sync_settings.json');
      if (settings == null) {
        return null;
      }
      return _preferences.serverCursorFromSyncSettingsText(
        utf8.decode(settings.readBytes() ?? const []),
      );
    } on Object {
      return null;
    }
  }

  Future<void> deleteSiblingZipFiles(Directory dir, {required File keep}) async {
    if (!dir.existsSync()) {
      return;
    }
    final keepPath = p.normalize(keep.path);
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.zip')) {
        continue;
      }
      if (p.normalize(entity.path) == keepPath) {
        continue;
      }
      try {
        await entity.delete();
      } on FileSystemException {
        // Cleanup is best-effort; a failed delete must not block backup creation.
      }
    }
  }

  Future<BackupResult> createRestoreSafetyBackup() async {
    final temp = await getTemporaryDirectory();
    final safetyDir = Directory(p.join(temp.path, 'yours_restore_safety'));
    if (!safetyDir.existsSync()) {
      safetyDir.createSync(recursive: true);
    }
    final output = File(p.join(safetyDir.path, _restoreSafetyFileName));
    return writeBackupFile(output);
  }

  Future<List<File>> _databaseFiles(Directory docs, String dbName) async {
    final names = [dbName, '$dbName-wal', '$dbName-shm'];
    final files = <File>[];
    for (final name in names) {
      final file = File(p.join(docs.path, name));
      if (file.existsSync()) {
        files.add(file);
      }
    }
    return files;
  }

  Future<void> _deleteDatabaseFamily(Directory docs, String dbName) async {
    for (final name in [dbName, '$dbName-wal', '$dbName-shm']) {
      final file = File(p.join(docs.path, name));
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<Set<File>> _collectExerciseImages(Directory docs) async {
    final files = <File>{};
    final commonDir = Directory(p.join(docs.path, 'exercise_images'));
    if (commonDir.existsSync()) {
      await for (final entity in commonDir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    }

    if (!locator.isRegistered<CustomExerciseDatabase>()) {
      return files;
    }

    final rows = await locator<CustomExerciseDatabase>()
        .select(
          locator<CustomExerciseDatabase>().customExercises,
        )
        .get();
    for (final row in rows) {
      final Object? decoded;
      try {
        decoded = jsonDecode(row.imagePathsJson);
      } on FormatException {
        continue;
      }
      if (decoded is! List) {
        continue;
      }
      for (final item in decoded.whereType<String>()) {
        final file = File(item);
        if (file.existsSync()) {
          files.add(file);
        }
      }
    }
    return files;
  }

  Future<void> _restoreAppSettings(ArchiveFile appSettings) async {
    final raw = utf8.decode(appSettings.readBytes() ?? const []);
    await _preferences.restoreAppSettingsText(raw);
  }

  Future<void> _closeOpenDatabases() async {
    if (locator.isRegistered<LocalTrainingDatabase>()) {
      await locator<LocalTrainingDatabase>().close();
      await locator.unregister<LocalTrainingDatabase>();
    }
    if (locator.isRegistered<CustomExerciseDatabase>()) {
      await locator<CustomExerciseDatabase>().close();
      await locator.unregister<CustomExerciseDatabase>();
    }
  }

  Future<void> _reopenLocalDatabases() async {
    locator.registerSingleton<LocalTrainingDatabase>(LocalTrainingDatabase());
    locator.registerSingleton<CustomExerciseDatabase>(CustomExerciseDatabase());
  }

  Map<String, Object?> _manifest({
    required DateTime createdAt,
    required List<BackupManifestFile> files,
    required Map<String, Object?> appSettings,
    required Map<String, Object?> syncSettings,
  }) {
    return {
      'format': 'yours-backup',
      'formatVersion': _backupFormatVersion,
      'createdAt': createdAt.toIso8601String(),
      'databases': {
        'localTraining': _trainingDbName,
        'customExercises': _exerciseDbName,
      },
      'contains': {
        'trainingPlans': true,
        'trainingRecords': true,
        'customExercises': true,
        'exerciseImages': true,
        'appSettings': true,
        'syncSettings': true,
        'secrets': false,
      },
      'settingsSchemaVersion': appSettings['schemaVersion'],
      'syncSchemaVersion': syncSettings['schemaVersion'],
      'files': files.map((file) => file.toJson()).toList(),
    };
  }

  Future<BackupManifestFile> _describeFile(File file, String archiveName) async {
    final bytes = await file.readAsBytes();
    return BackupManifestFile(
      path: archiveName,
      bytes: bytes.length,
      sha256Hash: sha256.convert(bytes).toString(),
    );
  }

  BackupManifestFile _describeText(String archiveName, String text) {
    final bytes = utf8.encode(text);
    return BackupManifestFile(
      path: archiveName,
      bytes: bytes.length,
      sha256Hash: sha256.convert(bytes).toString(),
    );
  }
}

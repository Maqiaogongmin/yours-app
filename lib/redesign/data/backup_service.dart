import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/sync_identity.dart';
import 'package:yours/redesign/data/yours_exception.dart';

class BackupResult {
  final File file;
  final int fileCount;
  final int byteCount;
  final DateTime createdAt;

  const BackupResult({
    required this.file,
    required this.fileCount,
    required this.byteCount,
    required this.createdAt,
  });
}

class ServerBackupSettings {
  final String baseUrl;
  final String apiToken;

  const ServerBackupSettings({
    required this.baseUrl,
    required this.apiToken,
  });

  bool get isConfigured => baseUrl.trim().isNotEmpty;
}

class ServerBackupUploadResult {
  final File source;
  final Uri endpoint;
  final DateTime uploadedAt;

  const ServerBackupUploadResult({
    required this.source,
    required this.endpoint,
    required this.uploadedAt,
  });
}

class ServerBackupDownloadResult {
  final File file;
  final Uri endpoint;
  final DateTime downloadedAt;

  const ServerBackupDownloadResult({
    required this.file,
    required this.endpoint,
    required this.downloadedAt,
  });
}

class ServerIncrementalSyncResult {
  final Uri endpoint;
  final int uploadedCount;
  final Set<String> entitySyncIds;
  final DateTime syncedAt;

  const ServerIncrementalSyncResult({
    required this.endpoint,
    required this.uploadedCount,
    required this.entitySyncIds,
    required this.syncedAt,
  });
}

class ServerSnapshotSyncResult {
  final int uploadedCount;
  final int downloadedEventCount;
  final int appliedEventCount;
  final int latestCursor;
  final BackupResult backup;
  final ServerBackupUploadResult upload;
  final DateTime syncedAt;

  const ServerSnapshotSyncResult({
    required this.uploadedCount,
    required this.downloadedEventCount,
    required this.appliedEventCount,
    required this.latestCursor,
    required this.backup,
    required this.upload,
    required this.syncedAt,
  });
}

enum ServerSmartSyncState {
  synced,
  needsInitialRestore,
  canFallbackRestore,
  failed,
}

class ServerSmartSyncResult {
  final ServerSmartSyncState state;
  final ServerSnapshotSyncResult? sync;
  final ServerSyncStatus? status;
  final String? errorMessage;

  const ServerSmartSyncResult({
    required this.state,
    this.sync,
    this.status,
    this.errorMessage,
  });

  bool get hasServerSnapshot => status?.hasLatestBackup == true;
}

class ServerSyncStatus {
  final bool available;
  final String serverVersion;
  final int? protocolVersion;
  final String identityMode;
  final int eventCount;
  final int latestCursor;
  final int? latestBackupBytes;
  final DateTime? latestBackupAt;
  final String message;

  const ServerSyncStatus({
    required this.available,
    required this.serverVersion,
    required this.protocolVersion,
    required this.identityMode,
    required this.eventCount,
    required this.latestCursor,
    required this.latestBackupBytes,
    required this.latestBackupAt,
    required this.message,
  });

  bool get hasLatestBackup => latestBackupAt != null || (latestBackupBytes ?? 0) > 0;

  factory ServerSyncStatus.fromJson(Map<String, dynamic> json) {
    final latestBackup = json['latestBackup'];
    final latestBackupMap = latestBackup is Map<String, dynamic> ? latestBackup : null;
    final updatedAt = latestBackupMap?['updatedAt'] as String?;
    return ServerSyncStatus(
      available: json['ok'] == true,
      serverVersion: json['serverVersion'] as String? ?? 'unknown',
      protocolVersion: json['protocolVersion'] as int?,
      identityMode: json['identityMode'] as String? ?? 'localId',
      eventCount: json['eventCount'] as int? ?? 0,
      latestCursor: json['latestCursor'] as int? ?? 0,
      latestBackupBytes: latestBackupMap?['bytes'] as int?,
      latestBackupAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      message: json['message'] as String? ?? '服务器同步状态正常。',
    );
  }
}

class ICloudDriveStatus {
  final bool available;
  final String state;
  final String message;
  final String? path;

  const ICloudDriveStatus({
    required this.available,
    required this.state,
    required this.message,
    this.path,
  });

  factory ICloudDriveStatus.fromMap(Map<Object?, Object?> map) {
    return ICloudDriveStatus(
      available: map['available'] == true,
      state: map['state'] as String? ?? 'unknown',
      message: map['message'] as String? ?? 'iCloud Drive 状态未知。',
      path: map['path'] as String?,
    );
  }

  static const unsupported = ICloudDriveStatus(
    available: false,
    state: 'unsupported',
    message: '当前平台不支持 iCloud Drive。',
  );
}

class ICloudDriveExportResult {
  final String path;
  final DateTime exportedAt;

  const ICloudDriveExportResult({
    required this.path,
    required this.exportedAt,
  });
}

class RestoreResult {
  final File source;
  final File safetyBackup;
  final int restoredFileCount;

  const RestoreResult({
    required this.source,
    required this.safetyBackup,
    required this.restoredFileCount,
  });
}

class BackupService {
  static const _backupFormatVersion = 1;
  static const _backupFileName = 'yours-backup.zip';
  static const _restoreSafetyFileName = 'yours-restore-safety.zip';
  static const _trainingDbName = 'local_training.sqlite';
  static const _exerciseDbName = 'custom_exercises.sqlite';
  static const _visibleFilesChannel = MethodChannel('yours/files');
  static const _lastAutoBackupAtKey = 'redesign_last_auto_backup_at';
  static const _lastDailyBackupDateKey = 'redesign_last_daily_backup_date';
  static const _lastAutoBackupReasonKey = 'redesign_last_auto_backup_reason';
  static const _serverBaseUrlKey = 'yours_backup_server_base_url';
  static const _serverApiTokenKey = 'yours_backup_server_api_token';
  static const _legacyServerDeviceIdKey = 'yours_sync_device_id';
  static const _legacyServerEventCursorKey = 'yours_sync_event_cursor';
  static const _serverDeviceIdKey = 'yours_sync_device_id_v2';
  static const _serverEventCursorKey = 'yours_sync_event_cursor_v2';
  static const _serverBackupPath = '/api/yours-backups/latest';
  static const _serverEventsPath = '/api/yours-sync/events';
  static const _serverStatusPath = '/api/yours-sync/status';
  static const _supportedServerProtocolVersion = 2;

  Future<Directory> getBackupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<File?> latestBackup() async {
    final visibleBackup = await _copyVisibleBackupIntoLocalDirectory();
    if (visibleBackup != null) {
      return visibleBackup;
    }
    return _latestInternalBackup();
  }

  Future<File?> _latestInternalBackup() async {
    final dir = await getBackupDirectory();
    final backup = File(p.join(dir.path, _backupFileName));
    return backup.existsSync() ? backup : null;
  }

  Future<BackupResult> createBackup() async {
    final backupDir = await getBackupDirectory();
    final output = File(p.join(backupDir.path, _backupFileName));
    final result = await _writeBackupFile(output);
    await _deleteSiblingZipFiles(backupDir, keep: output);
    await _syncBackupToVisibleDocuments(output);
    return result;
  }

  Future<BackupResult> _createRestoreSafetyBackup() async {
    final temp = await getTemporaryDirectory();
    final safetyDir = Directory(p.join(temp.path, 'yours_restore_safety'));
    if (!safetyDir.existsSync()) {
      safetyDir.createSync(recursive: true);
    }
    final output = File(p.join(safetyDir.path, _restoreSafetyFileName));
    return _writeBackupFile(output);
  }

  Future<BackupResult> _writeBackupFile(File output) async {
    final docs = await getApplicationDocumentsDirectory();
    final createdAt = DateTime.now();
    final encoder = ZipFileEncoder();
    final files = <_BackupFile>[];

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

      final appSettings = await _readAppSettings();
      final appSettingsText = const JsonEncoder.withIndent('  ').convert(appSettings);
      encoder.addArchiveFile(ArchiveFile.string('settings/app_settings.json', appSettingsText));
      files.add(_describeText('settings/app_settings.json', appSettingsText));

      final syncSettings = await _syncSettingsForBackup(createdAt);
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

  Future<BackupResult?> createAutomaticBackupIfNeeded({
    required String reason,
    bool daily = false,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final prefs = SharedPreferencesAsync();
    final lastAutoBackupText = await prefs.getString(_lastAutoBackupAtKey);
    final lastAutoBackupAt = lastAutoBackupText == null
        ? null
        : DateTime.tryParse(lastAutoBackupText);
    final latestChangeAt = await _latestPendingChangeAt();
    final today = _dateKey(now);
    final lastDailyBackupDate = await prefs.getString(_lastDailyBackupDateKey);

    final hasNewPendingChange =
        latestChangeAt != null &&
        (lastAutoBackupAt == null || latestChangeAt.isAfter(lastAutoBackupAt));
    final needsDailyBackup = daily && lastDailyBackupDate != today;

    if (!force && !hasNewPendingChange && !needsDailyBackup) {
      return null;
    }

    final result = await createBackup();
    await _rememberAutomaticBackup(result, reason: reason, daily: daily || needsDailyBackup);
    return result;
  }

  Future<ShareResult> shareBackup(
    File backup, {
    Rect? sharePositionOrigin,
    required String title,
    required String subject,
    required String text,
  }) async {
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: subject,
        text: text,
        files: [XFile(backup.path, mimeType: 'application/zip')],
        fileNameOverrides: [_backupFileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<ICloudDriveStatus> getICloudStatus() async {
    if (!Platform.isIOS) {
      return ICloudDriveStatus.unsupported;
    }
    try {
      final raw = await _visibleFilesChannel.invokeMethod<Map<Object?, Object?>>(
        'getICloudStatus',
      );
      if (raw == null) {
        return const ICloudDriveStatus(
          available: false,
          state: 'unknown',
          message: '无法读取 iCloud Drive 状态。',
        );
      }
      return ICloudDriveStatus.fromMap(raw);
    } on MissingPluginException {
      return const ICloudDriveStatus(
        available: false,
        state: 'missingPlugin',
        message: '当前安装包缺少 iCloud Drive 文件通道。',
      );
    } on PlatformException catch (error) {
      return ICloudDriveStatus(
        available: false,
        state: error.code,
        message: _friendlyPlatformMessage(error),
      );
    }
  }

  Future<ICloudDriveExportResult> exportLatestBackupToICloudDrive() async {
    final latest = await latestBackup() ?? (await createBackup()).file;
    return exportBackupToICloudDrive(latest);
  }

  Future<ICloudDriveExportResult> exportBackupToICloudDrive(File backup) async {
    if (!Platform.isIOS) {
      throw const YoursException(YoursErrorCode.iCloudUnsupported);
    }
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>(
        'exportBackupToICloudDrive',
        {'path': backup.path},
      );
      if (path == null || path.trim().isEmpty) {
        throw StateError('iCloud Drive 未返回导出路径。');
      }
      return ICloudDriveExportResult(path: path, exportedAt: DateTime.now());
    } on PlatformException catch (error) {
      throw StateError(_friendlyPlatformMessage(error));
    }
  }

  Future<File?> pickBackupFile() async {
    if (Platform.isIOS) {
      return pickICloudBackup();
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.trim().isEmpty) {
      throw const YoursException(YoursErrorCode.invalidBackup);
    }
    final file = File(path);
    if (!file.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    return file;
  }

  Future<File?> pickICloudBackup() async {
    if (!Platform.isIOS) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('pickICloudBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      if (!file.existsSync()) {
        throw const YoursException(YoursErrorCode.backupMissing);
      }
      if (!_looksLikeZip(
        await file
            .openRead(0, 4)
            .fold<List<int>>(
              <int>[],
              (bytes, chunk) => bytes..addAll(chunk),
            ),
      )) {
        throw const YoursException(YoursErrorCode.invalidBackup);
      }
      return file;
    } on MissingPluginException {
      throw StateError('当前安装包缺少 iCloud Drive 文件选择通道。');
    } on PlatformException catch (error) {
      throw StateError(_friendlyPlatformMessage(error));
    }
  }

  Future<ServerBackupSettings> loadServerBackupSettings() async {
    final prefs = SharedPreferencesAsync();
    return ServerBackupSettings(
      baseUrl: await prefs.getString(_serverBaseUrlKey) ?? '',
      apiToken: await prefs.getString(_serverApiTokenKey) ?? '',
    );
  }

  Future<void> saveServerBackupSettings(ServerBackupSettings settings) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_serverBaseUrlKey, settings.baseUrl.trim());
    await prefs.setString(_serverApiTokenKey, settings.apiToken.trim());
  }

  Future<ServerBackupUploadResult> uploadLatestBackupToServer() async {
    final current = await createBackup();
    return uploadBackupToServer(current.file);
  }

  Future<ServerBackupUploadResult> uploadBackupToServer(File backup) async {
    return _serverOperation('服务器上传', () async {
      final settings = await loadServerBackupSettings();
      final endpoint = _serverBackupEndpoint(settings);
      final request = http.MultipartRequest('POST', endpoint);
      request.headers.addAll(_serverHeaders(settings));
      request.files.add(
        await http.MultipartFile.fromPath(
          'backup',
          backup.path,
          filename: p.basename(backup.path),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      return ServerBackupUploadResult(
        source: backup,
        endpoint: endpoint,
        uploadedAt: DateTime.now(),
      );
    });
  }

  Future<ServerBackupDownloadResult> downloadLatestBackupFromServer() async {
    return _serverOperation('服务器下载', () async {
      final settings = await loadServerBackupSettings();
      final endpoint = _serverBackupEndpoint(settings);
      final response = await http
          .get(endpoint, headers: _serverHeaders(settings))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      if (response.bodyBytes.isEmpty) {
        throw const YoursException(YoursErrorCode.backupEmpty);
      }
      if (!_looksLikeZip(response.bodyBytes)) {
        throw const YoursException(YoursErrorCode.invalidBackup);
      }

      final backupDir = await getBackupDirectory();
      final filename = _serverBackupFilename(response.headers['content-disposition']);
      final output = File(p.join(backupDir.path, filename));
      await output.writeAsBytes(response.bodyBytes);
      return ServerBackupDownloadResult(
        file: output,
        endpoint: endpoint,
        downloadedAt: DateTime.now(),
      );
    });
  }

  Future<RestoreResult> restoreLatestServerBackup() async {
    final downloaded = await downloadLatestBackupFromServer();
    final backupCursor = await _serverCursorFromBackup(downloaded.file);
    final result = await restoreBackup(downloaded.file);
    if (backupCursor != null) {
      await _setServerEventCursor(backupCursor);
    }
    return result;
  }

  Future<ServerIncrementalSyncResult> uploadPendingChangesToServer({
    int limit = 100,
  }) async {
    return _serverOperation('服务器增量同步', () async {
      final settings = await loadServerBackupSettings();
      final endpoint = _serverEndpoint(settings, _serverEventsPath);
      final deviceId = await _deviceId();
      final syncQueue = LocalSyncQueueRepository(locator<LocalTrainingDatabase>());
      final items = await syncQueue.pendingItems(limit: limit);
      if (items.isEmpty) {
        return ServerIncrementalSyncResult(
          endpoint: endpoint,
          uploadedCount: 0,
          entitySyncIds: const <String>{},
          syncedAt: DateTime.now(),
        );
      }

      final events = <Map<String, Object?>>[];
      final obsoleteIds = <int>[];
      for (final item in items) {
        final event = await _syncEventFor(item, deviceId: deviceId);
        if (event == null) {
          obsoleteIds.add(item.id);
        } else {
          events.add(event);
        }
      }
      if (obsoleteIds.isNotEmpty) {
        await syncQueue.markSynced(obsoleteIds);
      }
      if (events.isEmpty) {
        return ServerIncrementalSyncResult(
          endpoint: endpoint,
          uploadedCount: 0,
          entitySyncIds: const <String>{},
          syncedAt: DateTime.now(),
        );
      }

      final response = await http
          .post(
            endpoint,
            headers: {
              ..._serverHeaders(settings),
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json, text/plain, */*',
            },
            body: jsonEncode({
              'schemaVersion': 2,
              'client': 'yours',
              'createdAt': DateTime.now().toIso8601String(),
              'events': events,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await syncQueue.markFailed(
          items.where((item) => !obsoleteIds.contains(item.id)).map((item) => item.id).toList(),
        );
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }

      final uploadedItems = items.where((item) => !obsoleteIds.contains(item.id)).toList();
      await syncQueue.markSynced(uploadedItems.map((item) => item.id).toList());
      return ServerIncrementalSyncResult(
        endpoint: endpoint,
        uploadedCount: uploadedItems.length,
        entitySyncIds: uploadedItems.map(_entitySyncIdForQueueItem).toSet(),
        syncedAt: DateTime.now(),
      );
    });
  }

  Future<ServerSnapshotSyncResult> syncPendingChangesAndUploadSnapshot({
    int batchSize = 100,
  }) async {
    return _serverOperation('服务器同步', () async {
      var uploadedCount = 0;
      final localChangedEntitySyncIds = <String>{};
      while (true) {
        final result = await uploadPendingChangesToServer(limit: batchSize);
        uploadedCount += result.uploadedCount;
        localChangedEntitySyncIds.addAll(result.entitySyncIds);
        final remaining = await LocalSyncQueueRepository(
          locator<LocalTrainingDatabase>(),
        ).pendingCount();
        if (remaining == 0) {
          break;
        }
      }

      await _createRestoreSafetyBackup();
      final pull = await _pullAndApplyServerEvents(
        skipEntitySyncIds: localChangedEntitySyncIds,
      );
      if (pull.failedCount > 0) {
        throw YoursException(
          YoursErrorCode.unappliedServerChanges,
          count: pull.failedCount,
        );
      }
      final backup = await createBackup();
      final upload = await uploadBackupToServer(backup.file);
      return ServerSnapshotSyncResult(
        uploadedCount: uploadedCount,
        downloadedEventCount: pull.downloadedCount,
        appliedEventCount: pull.appliedCount,
        latestCursor: pull.latestCursor,
        backup: backup,
        upload: upload,
        syncedAt: DateTime.now(),
      );
    });
  }

  Future<ServerSmartSyncResult> syncNowWithServer({
    bool suggestRestore = true,
  }) async {
    ServerSyncStatus status;
    try {
      status = await checkServerSyncStatus();
    } on Object catch (error) {
      return ServerSmartSyncResult(
        state: ServerSmartSyncState.failed,
        errorMessage: '$error',
      );
    }

    if (suggestRestore) {
      final initialRestore = await _initialRestoreDecision(status);
      if (initialRestore != null) {
        return initialRestore;
      }
    }

    try {
      final sync = await syncPendingChangesAndUploadSnapshot();
      return ServerSmartSyncResult(
        state: ServerSmartSyncState.synced,
        sync: sync,
        status: status,
      );
    } on Object catch (error) {
      if (suggestRestore && status.hasLatestBackup) {
        return ServerSmartSyncResult(
          state: ServerSmartSyncState.canFallbackRestore,
          status: status,
          errorMessage: '$error',
        );
      }
      return ServerSmartSyncResult(
        state: ServerSmartSyncState.failed,
        status: status,
        errorMessage: '$error',
      );
    }
  }

  @visibleForTesting
  Future<bool> localTrainingDataIsEmptyForTest() => _localTrainingDataIsEmpty();

  @visibleForTesting
  Future<ServerSmartSyncResult?> initialRestoreDecisionForTest(ServerSyncStatus status) {
    return _initialRestoreDecision(status);
  }

  @visibleForTesting
  bool preferenceCanBeBackedUpForTest(String key) => _shouldBackupPreference(key);

  @visibleForTesting
  Future<bool> applyRemoteSyncEventForTest(Map<String, dynamic> event) {
    return _applyRemoteSyncEvent(event);
  }

  Future<ServerSmartSyncResult?> _initialRestoreDecision(ServerSyncStatus status) async {
    if (!status.hasLatestBackup || !await _localTrainingDataIsEmpty()) {
      return null;
    }
    return ServerSmartSyncResult(
      state: ServerSmartSyncState.needsInitialRestore,
      status: status,
    );
  }

  Future<bool> _localTrainingDataIsEmpty() async {
    if (!locator.isRegistered<LocalTrainingDatabase>()) {
      return true;
    }
    final db = locator<LocalTrainingDatabase>();
    final visibleRoutine =
        await (db.select(db.localRoutines)
              ..where((row) => row.deleted.equals(false))
              ..limit(1))
            .getSingleOrNull();
    if (visibleRoutine != null) {
      return false;
    }
    final session = await (db.select(db.localWorkoutSessions)..limit(1)).getSingleOrNull();
    if (session != null) {
      return false;
    }
    final log = await (db.select(db.localWorkoutLogs)..limit(1)).getSingleOrNull();
    return log == null;
  }

  Future<_ServerEventPullResult> _pullAndApplyServerEvents({
    int limit = 500,
    Set<String> skipEntitySyncIds = const <String>{},
  }) async {
    final settings = await loadServerBackupSettings();
    final deviceId = await _deviceId();
    var cursor = await _serverEventCursor();
    var downloadedCount = 0;
    var appliedCount = 0;
    var failedCount = 0;
    var latestCursor = cursor;

    while (true) {
      final pull = await _downloadServerEvents(settings, after: cursor, limit: limit);
      if (pull.legacyServer) {
        break;
      }
      if (pull.latestCursor < cursor) {
        cursor = 0;
        await _setServerEventCursor(cursor);
        continue;
      }
      downloadedCount += pull.events.length;
      latestCursor = pull.latestCursor;
      var pageFailed = false;
      for (final record in pull.events) {
        final event = _eventPayloadFromRecord(record);
        if (event == null) {
          continue;
        }
        if (event['deviceId'] == deviceId) {
          continue;
        }
        if (_shouldSkipRemoteEvent(event, skipEntitySyncIds)) {
          continue;
        }
        try {
          if (await _applyRemoteSyncEvent(event)) {
            appliedCount += 1;
          } else {
            failedCount += 1;
            pageFailed = true;
          }
        } on Object {
          // 单条旧事件不能阻断整次同步。下一次快照仍会兜底保留完整数据。
          failedCount += 1;
          pageFailed = true;
        }
      }
      if (pageFailed) {
        break;
      }
      cursor = pull.cursor;
      await _setServerEventCursor(cursor);
      if (!pull.hasMore) {
        break;
      }
    }

    if (failedCount == 0 && latestCursor > cursor) {
      await _setServerEventCursor(latestCursor);
    }
    return _ServerEventPullResult(
      downloadedCount: downloadedCount,
      appliedCount: appliedCount,
      failedCount: failedCount,
      latestCursor: latestCursor,
    );
  }

  Future<_ServerEventPage> _downloadServerEvents(
    ServerBackupSettings settings, {
    required int after,
    required int limit,
  }) async {
    final endpoint = _serverEndpoint(settings, _serverEventsPath).replace(
      queryParameters: {
        'after': '$after',
        'limit': '$limit',
      },
    );
    final response = await http
        .get(
          endpoint,
          headers: {
            ..._serverHeaders(settings),
            'Accept': 'application/json, text/plain, */*',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode == 404) {
      return _ServerEventPage(
        events: const [],
        cursor: after,
        latestCursor: after,
        hasMore: false,
        legacyServer: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const YoursException(YoursErrorCode.invalidServerResponse);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const YoursException(YoursErrorCode.invalidServerEvents);
    }
    final events = decoded['events'];
    return _ServerEventPage(
      events: events is List
          ? events.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : const [],
      cursor: _asInt(decoded['cursor']) ?? after,
      latestCursor: _asInt(decoded['latestCursor']) ?? after,
      hasMore: decoded['hasMore'] == true,
      legacyServer: false,
    );
  }

  Future<ServerSyncStatus> checkServerSyncStatus() async {
    return _serverOperation('服务器连接测试', () async {
      final settings = await loadServerBackupSettings();
      final endpoint = _serverEndpoint(settings, _serverStatusPath);
      final response = await http
          .get(
            endpoint,
            headers: {
              ..._serverHeaders(settings),
              'Accept': 'application/json, text/plain, */*',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const YoursException(YoursErrorCode.invalidServerStatus);
      }
      final status = ServerSyncStatus.fromJson(decoded);
      if (status.protocolVersion != _supportedServerProtocolVersion ||
          status.identityMode != 'syncId') {
        throw YoursException(
          YoursErrorCode.serverOutdated,
          currentVersion: status.protocolVersion,
          requiredVersion: _supportedServerProtocolVersion,
        );
      }
      return status;
    });
  }

  Future<String> serverDiagnosticsText() async {
    final settings = await loadServerBackupSettings();
    final buffer = StringBuffer()
      ..writeln('Yours server sync diagnostics')
      ..writeln('generatedAt: ${DateTime.now().toIso8601String()}')
      ..writeln('platform: ${Platform.operatingSystem}')
      ..writeln('configured: ${settings.isConfigured}')
      ..writeln('baseUrl: ${settings.baseUrl.trim().isEmpty ? '(empty)' : settings.baseUrl.trim()}')
      ..writeln('apiKeyConfigured: ${settings.apiToken.trim().isNotEmpty}');

    try {
      buffer.writeln('deviceId: ${await _deviceId()}');
    } on Object catch (error) {
      buffer.writeln('deviceIdError: $error');
    }
    try {
      buffer.writeln('localCursor: ${await _serverEventCursor()}');
    } on Object catch (error) {
      buffer.writeln('localCursorError: $error');
    }
    try {
      final pendingCount = locator.isRegistered<LocalTrainingDatabase>()
          ? await LocalSyncQueueRepository(locator<LocalTrainingDatabase>()).pendingCount()
          : 0;
      buffer.writeln('pendingEvents: $pendingCount');
    } on Object catch (error) {
      buffer.writeln('pendingEventsError: $error');
    }

    if (!settings.isConfigured) {
      return buffer.toString();
    }
    try {
      final status = await checkServerSyncStatus();
      buffer
        ..writeln('serverAvailable: ${status.available}')
        ..writeln('serverVersion: ${status.serverVersion}')
        ..writeln('protocolVersion: ${status.protocolVersion}')
        ..writeln('identityMode: ${status.identityMode}')
        ..writeln('serverLatestCursor: ${status.latestCursor}')
        ..writeln('serverEventCount: ${status.eventCount}')
        ..writeln('latestBackupAt: ${status.latestBackupAt?.toIso8601String() ?? '(none)'}')
        ..writeln('latestBackupBytes: ${status.latestBackupBytes ?? 0}')
        ..writeln('message: ${status.message}');
    } on Object catch (error) {
      buffer.writeln('serverError: $error');
    }
    return buffer.toString();
  }

  Future<RestoreResult> restoreLatestBackup() async {
    final latest =
        await _copyVisibleBackupIntoLocalDirectory() ??
        await _pickVisibleBackupIntoLocalDirectory() ??
        await _latestInternalBackup();
    if (latest == null) {
      throw const YoursException(YoursErrorCode.noServerBackup);
    }
    return restoreBackup(latest);
  }

  Future<RestoreResult> restoreBackup(File backup) async {
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }

    final safetyBackup = (await _createRestoreSafetyBackup()).file;
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
      await SharedPreferencesAsync().setString('redesign_sync_settings', settingsText);
      restored += 1;
    }

    await _reopenLocalDatabases();

    return RestoreResult(
      source: backup,
      safetyBackup: safetyBackup,
      restoredFileCount: restored,
    );
  }

  Future<DateTime?> _latestPendingChangeAt() async {
    if (!locator.isRegistered<LocalTrainingDatabase>()) {
      return null;
    }
    return LocalSyncQueueRepository(locator<LocalTrainingDatabase>()).latestPendingChangeAt();
  }

  Future<void> _rememberAutomaticBackup(
    BackupResult result, {
    required String reason,
    required bool daily,
  }) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_lastAutoBackupAtKey, result.createdAt.toIso8601String());
    await prefs.setString(_lastAutoBackupReasonKey, reason);
    if (daily) {
      await prefs.setString(_lastDailyBackupDateKey, _dateKey(result.createdAt));
    }
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

  Future<Map<String, Object?>> _readAppSettings() async {
    final prefs = SharedPreferencesAsync();
    final values = Map<String, Object?>.fromEntries(
      (await prefs.getAll()).entries.where((entry) => _shouldBackupPreference(entry.key)).toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'sharedPreferences': values,
    };
  }

  Future<void> _restoreAppSettings(ArchiveFile appSettings) async {
    final raw = utf8.decode(appSettings.readBytes() ?? const []);
    await _restoreAppSettingsText(raw);
  }

  Future<void> _restoreAppSettingsText(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final values = decoded['sharedPreferences'];
    if (values is! Map<String, dynamic>) {
      return;
    }

    final prefs = SharedPreferencesAsync();
    for (final entry in values.entries) {
      final key = entry.key;
      if (!_shouldBackupPreference(key)) {
        continue;
      }
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.whereType<String>().toList());
      }
    }
  }

  Future<Map<String, Object?>> _syncSettingsForBackup(DateTime createdAt) async {
    return {
      'schemaVersion': 2,
      'mode': 'local',
      'serverBackupEnabled': false,
      'incrementalSyncEnabled': false,
      'protocolVersion': _supportedServerProtocolVersion,
      'identityMode': 'syncId',
      'serverEventCursor': await _serverEventCursor(),
      'createdAt': createdAt.toIso8601String(),
      'secretsIncluded': false,
    };
  }

  Future<int?> _serverCursorFromBackup(File backup) async {
    try {
      final archive = ZipDecoder().decodeBytes(await backup.readAsBytes(), verify: true);
      final settings = archive.findFile('settings/sync_settings.json');
      if (settings == null) {
        return null;
      }
      final decoded = jsonDecode(utf8.decode(settings.readBytes() ?? const []));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final cursor = _asInt(decoded['serverEventCursor']);
      return cursor == null || cursor < 0 ? null : cursor;
    } on Object {
      return null;
    }
  }

  bool _isSensitivePreference(String key) {
    final lower = key.toLowerCase();
    return key == _serverApiTokenKey ||
        lower.contains('token') ||
        lower.contains('password') ||
        lower.contains('secret');
  }

  bool _shouldBackupPreference(String key) {
    if (_isSensitivePreference(key)) {
      return false;
    }
    return key != _legacyServerDeviceIdKey &&
        key != _legacyServerEventCursorKey &&
        key != _serverDeviceIdKey &&
        key != _serverEventCursorKey;
  }

  Future<void> _syncBackupToVisibleDocuments(File backup) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _visibleFilesChannel.invokeMethod<String>(
        'syncBackupToPublicDocuments',
        {'path': backup.path},
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<File?> _copyVisibleBackupIntoLocalDirectory() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('importPublicBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? file : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<File?> _pickVisibleBackupIntoLocalDirectory() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('pickPublicBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? file : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _friendlyPlatformMessage(PlatformException error) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    if (error.code.contains('icloud')) {
      return 'iCloud Drive 操作失败。请确认设备已登录 iCloud，且 iCloud Drive 已开启。';
    }
    return '文件操作失败：${error.code}';
  }

  Future<T> _serverOperation<T>(
    String _,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on YoursException {
      rethrow;
    } on StateError {
      rethrow;
    } on TimeoutException {
      throw const YoursException(YoursErrorCode.serverTimeout);
    } on HandshakeException {
      throw const YoursException(YoursErrorCode.serverTls);
    } on SocketException {
      throw const YoursException(YoursErrorCode.serverUnreachable);
    } on http.ClientException {
      throw const YoursException(YoursErrorCode.serverInterrupted);
    } on FormatException {
      throw const YoursException(YoursErrorCode.invalidServerResponse);
    }
  }

  Uri _serverBackupEndpoint(ServerBackupSettings settings) {
    return _serverEndpoint(settings, _serverBackupPath);
  }

  Future<void> _deleteSiblingZipFiles(Directory dir, {required File keep}) async {
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

  Uri _serverEndpoint(ServerBackupSettings settings, String path) {
    final raw = settings.baseUrl.trim();
    if (raw.isEmpty) {
      throw const YoursException(YoursErrorCode.serverNotConfigured);
    }
    final base = Uri.tryParse(raw);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      throw const YoursException(YoursErrorCode.invalidServerAddress);
    }
    final normalizedPath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(path: '$normalizedPath$path');
  }

  Map<String, String> _serverHeaders(ServerBackupSettings settings) {
    final headers = <String, String>{
      'Accept': 'application/zip, application/octet-stream',
      'X-Yours-Backup-Client': 'yours',
    };
    final token = settings.apiToken.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _serverBackupFilename(String? _) {
    return _backupFileName;
  }

  bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
  }

  Map<String, Object?> _manifest({
    required DateTime createdAt,
    required List<_BackupFile> files,
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

  Future<Map<String, Object?>?> _syncEventFor(
    LocalSyncQueueData item, {
    required String deviceId,
  }) async {
    Object? payload;
    try {
      payload = jsonDecode(item.payload);
    } on FormatException {
      payload = item.payload;
    }
    final entitySyncId = item.entitySyncId.trim();
    if (entitySyncId.isEmpty) {
      throw StateError('旧同步事件缺少稳定身份，已跳过上传。');
    }
    final snapshot = await _snapshotFor(item);
    if (item.action != 'delete' && snapshot == null) {
      return null;
    }
    return {
      'id': item.id,
      'eventId': item.eventId.trim().isEmpty ? '$deviceId-${item.id}' : item.eventId,
      'deviceId': item.deviceId.trim().isEmpty ? deviceId : item.deviceId,
      'entityType': item.entityType,
      'entityId': item.entityId,
      'entitySyncId': entitySyncId,
      'action': item.action,
      'payload': payload,
      'snapshot': snapshot,
      'attempts': item.attempts,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
    };
  }

  String _entitySyncIdForQueueItem(LocalSyncQueueData item) {
    return item.entitySyncId.trim().isEmpty ? '' : item.entitySyncId;
  }

  String _entitySyncIdForEvent(Map<String, dynamic> event) {
    final explicit = event['entitySyncId'];
    if (explicit is String && explicit.trim().isNotEmpty) {
      return explicit;
    }
    return '${event['entityType']}:${event['entityId']}';
  }

  bool _shouldSkipRemoteEvent(Map<String, dynamic> event, Set<String> skipEntitySyncIds) {
    if (skipEntitySyncIds.isEmpty) {
      return false;
    }
    if (skipEntitySyncIds.contains(_entitySyncIdForEvent(event))) {
      return true;
    }
    final entityType = event['entityType'] as String?;
    final snapshot = _asMap(event['snapshot']);
    final routineSyncId = _asString(snapshot?['routineSyncId']);
    if (routineSyncId.isNotEmpty && skipEntitySyncIds.contains('routine:$routineSyncId')) {
      return true;
    }
    if (entityType == 'workout_log') {
      final sessionSyncId = _asString(snapshot?['sessionSyncId']);
      if (sessionSyncId.isNotEmpty &&
          skipEntitySyncIds.contains('workout_session:$sessionSyncId')) {
        return true;
      }
    }
    return false;
  }

  Future<String> _deviceId() async {
    return SyncIdentity.deviceId();
  }

  Future<int> _serverEventCursor() async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getInt(_serverEventCursorKey) ?? 0;
  }

  Future<void> _setServerEventCursor(int cursor) async {
    await SharedPreferencesAsync().setInt(_serverEventCursorKey, cursor);
  }

  Map<String, dynamic>? _eventPayloadFromRecord(Map<String, dynamic> record) {
    final event = record['event'];
    if (event is Map<String, dynamic>) {
      return event;
    }
    if (event is Map) {
      return Map<String, dynamic>.from(event);
    }
    return record;
  }

  String? _syncIdFromEvent(
    String entityType,
    Map<String, dynamic> event,
    Map<String, dynamic>? snapshot,
  ) {
    final explicit = event['entitySyncId'];
    if (explicit is String && explicit.startsWith('$entityType:')) {
      final value = explicit.substring(entityType.length + 1).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    final snapshotSyncId = _asString(snapshot?['syncId']);
    return snapshotSyncId.isEmpty ? null : snapshotSyncId;
  }

  Future<int?> _localRoutineIdBySyncId(LocalTrainingDatabase db, String? syncId) async {
    if (syncId == null || syncId.trim().isEmpty) {
      return null;
    }
    final row = await (db.select(
      db.localRoutines,
    )..where((item) => item.syncId.equals(syncId))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localTrainingDayIdBySyncId(LocalTrainingDatabase db, String? syncId) async {
    if (syncId == null || syncId.trim().isEmpty) {
      return null;
    }
    final row = await (db.select(
      db.localTrainingDays,
    )..where((item) => item.syncId.equals(syncId))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localSessionIdBySyncId(LocalTrainingDatabase db, String? syncId) async {
    if (syncId == null || syncId.trim().isEmpty) {
      return null;
    }
    final row = await (db.select(
      db.localWorkoutSessions,
    )..where((item) => item.syncId.equals(syncId))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localLogIdBySyncId(LocalTrainingDatabase db, String? syncId) async {
    if (syncId == null || syncId.trim().isEmpty) {
      return null;
    }
    final row = await (db.select(
      db.localWorkoutLogs,
    )..where((item) => item.syncId.equals(syncId))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localCustomExerciseIdBySyncId(CustomExerciseDatabase db, String? syncId) async {
    if (syncId == null || syncId.trim().isEmpty) {
      return null;
    }
    final row = await (db.select(
      db.customExercises,
    )..where((item) => item.syncId.equals(syncId))).getSingleOrNull();
    return row?.id;
  }

  Future<bool> _localRoutineIsNewer(
    LocalTrainingDatabase db,
    int id,
    DateTime remoteUpdatedAt,
  ) async {
    final row = await (db.select(
      db.localRoutines,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row != null && row.updatedAt.isAfter(remoteUpdatedAt);
  }

  Future<bool> _localSessionIsNewer(
    LocalTrainingDatabase db,
    int id,
    DateTime remoteUpdatedAt,
  ) async {
    final row = await (db.select(
      db.localWorkoutSessions,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row != null && row.updatedAt.isAfter(remoteUpdatedAt);
  }

  Future<bool> _localCustomExerciseIsNewer(
    CustomExerciseDatabase db,
    int id,
    DateTime remoteUpdatedAt,
  ) async {
    final row = await (db.select(
      db.customExercises,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row != null && row.updatedAt.isAfter(remoteUpdatedAt);
  }

  Future<bool> _applyRemoteSyncEvent(Map<String, dynamic> event) async {
    final entityType = event['entityType'] as String?;
    final action = event['action'] as String?;
    if (entityType == null || action == null) {
      return true;
    }
    final id = _asInt(event['entityId']);
    final snapshot = _asMap(event['snapshot']);
    switch (entityType) {
      case 'routine':
        return _applyRemoteRoutineEvent(
          action,
          _syncIdFromEvent('routine', event, snapshot),
          id,
          snapshot,
        );
      case 'workout_session':
        return _applyRemoteSessionEvent(
          action,
          _syncIdFromEvent('workout_session', event, snapshot),
          id,
          snapshot,
        );
      case 'workout_log':
        return _applyRemoteWorkoutLogEvent(
          action,
          _syncIdFromEvent('workout_log', event, snapshot),
          id,
          snapshot,
        );
      case 'custom_exercise':
        return _applyRemoteCustomExerciseEvent(
          action,
          _syncIdFromEvent('custom_exercise', event, snapshot),
          id,
          snapshot,
        );
      default:
        return true;
    }
  }

  Future<bool> _applyRemoteRoutineEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    final db = locator<LocalTrainingDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final routineId = await _localRoutineIdBySyncId(db, syncId);
    if (action == 'delete' || snapshot?['deleted'] == true) {
      await _recordDeleteTombstone(
        entityType: 'routine',
        entitySyncId: 'routine:$syncId',
        entityId: routineId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (routineId == null) {
        return true;
      }
      await (db.update(db.localRoutines)..where((row) => row.id.equals(routineId))).write(
        LocalRoutinesCompanion(
          deleted: const Value(true),
          syncStatus: const Value(localSyncSynced),
          updatedAt: Value(_date(snapshot?['updatedAt']) ?? DateTime.now()),
        ),
      );
      return true;
    }
    if (snapshot == null) {
      return true;
    }

    final now = DateTime.now();
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? now;
    if (await _deleteTombstoneIsNotOlder('routine:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (routineId != null && await _localRoutineIsNewer(db, routineId, remoteUpdatedAt)) {
      return true;
    }
    await db.transaction(() async {
      final localRoutineId =
          routineId ??
          await db
              .into(db.localRoutines)
              .insert(
                LocalRoutinesCompanion.insert(
                  syncId: Value(syncId),
                  remoteId: Value(_asInt(snapshot['remoteId'])),
                  name: _asString(snapshot['name'], fallback: '同步训练计划'),
                  totalWeeks: Value(_asInt(snapshot['totalWeeks']) ?? 4),
                  daysPerWeek: Value(_asInt(snapshot['daysPerWeek']) ?? 4),
                  archived: Value(_asBool(snapshot['archived']) ?? false),
                  completedWeeksJson: Value(jsonEncode(_asList(snapshot['completedWeeks']))),
                  syncStatus: const Value(localSyncSynced),
                  deleted: Value(_asBool(snapshot['deleted']) ?? false),
                  createdAt: _date(snapshot['createdAt']) ?? now,
                  updatedAt: remoteUpdatedAt,
                ),
              );
      if (routineId != null) {
        await (db.update(db.localRoutines)..where((row) => row.id.equals(localRoutineId))).write(
          LocalRoutinesCompanion(
            syncId: Value(syncId),
            remoteId: Value(_asInt(snapshot['remoteId'])),
            name: Value(_asString(snapshot['name'], fallback: '同步训练计划')),
            totalWeeks: Value(_asInt(snapshot['totalWeeks']) ?? 4),
            daysPerWeek: Value(_asInt(snapshot['daysPerWeek']) ?? 4),
            archived: Value(_asBool(snapshot['archived']) ?? false),
            completedWeeksJson: Value(jsonEncode(_asList(snapshot['completedWeeks']))),
            syncStatus: const Value(localSyncSynced),
            deleted: Value(_asBool(snapshot['deleted']) ?? false),
            updatedAt: Value(remoteUpdatedAt),
          ),
        );
      }

      final remoteDaysValue = snapshot['days'];
      if (remoteDaysValue is! List) {
        return;
      }
      final remoteDaySyncIds = <String>{};
      for (final item in remoteDaysValue) {
        final day = _asMap(item);
        if (day == null) {
          continue;
        }
        final daySyncId = _asString(day['syncId']);
        if (daySyncId.isEmpty) {
          continue;
        }
        remoteDaySyncIds.add(daySyncId);
        final dayId =
            await _localTrainingDayIdBySyncId(db, daySyncId) ??
            await db
                .into(db.localTrainingDays)
                .insert(
                  LocalTrainingDaysCompanion.insert(
                    syncId: Value(daySyncId),
                    remoteId: Value(_asInt(day['remoteId'])),
                    routineId: localRoutineId,
                    week: _asInt(day['week']) ?? 1,
                    day: _asInt(day['day']) ?? 1,
                    name: _asString(day['name'], fallback: '训练日'),
                    actionsJson: Value('[]'),
                    syncStatus: const Value(localSyncSynced),
                    updatedAt: _date(day['updatedAt']) ?? now,
                  ),
                );
        final actions = _asList(day['actions']).map((item) {
          final action = _asMap(item);
          if (action == null) {
            return item;
          }
          return <String, Object?>{
            ...action,
            'name': canonicalExerciseReference(
              _asString(action['name'], fallback: '同步动作'),
            ),
          };
        }).toList();
        await (db.update(db.localTrainingDays)..where((row) => row.id.equals(dayId))).write(
          LocalTrainingDaysCompanion(
            syncId: Value(daySyncId),
            remoteId: Value(_asInt(day['remoteId'])),
            routineId: Value(localRoutineId),
            week: Value(_asInt(day['week']) ?? 1),
            day: Value(_asInt(day['day']) ?? 1),
            name: Value(_asString(day['name'], fallback: '训练日')),
            actionsJson: Value(jsonEncode(actions)),
            syncStatus: const Value(localSyncSynced),
            updatedAt: Value(_date(day['updatedAt']) ?? now),
          ),
        );
        await _replaceRemoteDaySlots(db, dayId: dayId, actions: actions);
      }

      final localDays = await (db.select(
        db.localTrainingDays,
      )..where((day) => day.routineId.equals(localRoutineId))).get();
      for (final day in localDays) {
        if (remoteDaySyncIds.contains(day.syncId)) {
          continue;
        }
        await _deleteDayChildren(db, day.id);
        await (db.delete(db.localTrainingDays)..where((row) => row.id.equals(day.id))).go();
      }
    });
    return true;
  }

  Future<bool> _applyRemoteSessionEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    final db = locator<LocalTrainingDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final sessionId = await _localSessionIdBySyncId(db, syncId);
    if (action == 'delete') {
      await _recordDeleteTombstone(
        entityType: 'workout_session',
        entitySyncId: 'workout_session:$syncId',
        entityId: sessionId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (sessionId == null) {
        return true;
      }
      await db.transaction(() async {
        await (db.delete(
          db.localWorkoutLogs,
        )..where((row) => row.sessionId.equals(sessionId))).go();
        await (db.delete(
          db.localWorkoutSessions,
        )..where((row) => row.id.equals(sessionId))).go();
      });
      return true;
    }
    if (snapshot == null) {
      return true;
    }
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? DateTime.now();
    final dayId = await _localTrainingDayIdBySyncId(db, _asString(snapshot['daySyncId']));
    final startedAt = _date(snapshot['startedAt']);
    if (startedAt == null) {
      return true;
    }
    if (sessionId == null && await _hasDuplicateLocalSession(db, snapshot, startedAt)) {
      return true;
    }
    final routineId = await _ensureHistoryRoutine(
      db,
      _asString(snapshot['routineSyncId']),
      remoteUpdatedAt,
    );
    if (routineId == null) {
      return true;
    }
    if (!await _localRoutineExists(db, routineId)) {
      return true;
    }
    if (await _deleteTombstoneIsNotOlder('workout_session:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (sessionId != null && await _localSessionIsNewer(db, sessionId, remoteUpdatedAt)) {
      return true;
    }
    await db.transaction(() async {
      final localSessionId =
          sessionId ??
          await db
              .into(db.localWorkoutSessions)
              .insert(
                LocalWorkoutSessionsCompanion.insert(
                  syncId: Value(syncId),
                  remoteId: Value(_asInt(snapshot['remoteId'])),
                  routineId: routineId,
                  dayId: Value(dayId),
                  startedAt: startedAt,
                  endedAt: Value(_date(snapshot['endedAt'])),
                  note: Value(_asString(snapshot['note'])),
                  syncStatus: const Value(localSyncSynced),
                  updatedAt: remoteUpdatedAt,
                ),
              );
      if (sessionId != null) {
        await (db.update(
          db.localWorkoutSessions,
        )..where((row) => row.id.equals(localSessionId))).write(
          LocalWorkoutSessionsCompanion(
            syncId: Value(syncId),
            remoteId: Value(_asInt(snapshot['remoteId'])),
            routineId: Value(routineId),
            dayId: Value(dayId),
            startedAt: Value(startedAt),
            endedAt: Value(_date(snapshot['endedAt'])),
            note: Value(_asString(snapshot['note'])),
            syncStatus: const Value(localSyncSynced),
            updatedAt: Value(remoteUpdatedAt),
          ),
        );
      }
      final logsValue = snapshot['logs'];
      if (logsValue is! List) {
        return;
      }
      final remoteLogSyncIds = <String>{};
      for (final item in logsValue) {
        final log = _asMap(item);
        final logSyncId = _asString(log?['syncId']);
        if (log == null || logSyncId.isEmpty) {
          continue;
        }
        remoteLogSyncIds.add(logSyncId);
        await _upsertRemoteWorkoutLog(db, log);
      }
      final localLogs = await (db.select(
        db.localWorkoutLogs,
      )..where((row) => row.sessionId.equals(localSessionId))).get();
      for (final log in localLogs) {
        if (!remoteLogSyncIds.contains(log.syncId)) {
          await (db.delete(db.localWorkoutLogs)..where((row) => row.id.equals(log.id))).go();
        }
      }
    });
    return true;
  }

  Future<bool> _applyRemoteWorkoutLogEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    final db = locator<LocalTrainingDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final logId = await _localLogIdBySyncId(db, syncId);
    if (action == 'delete') {
      await _recordDeleteTombstone(
        entityType: 'workout_log',
        entitySyncId: 'workout_log:$syncId',
        entityId: logId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (logId == null) {
        return true;
      }
      await (db.delete(db.localWorkoutLogs)..where((row) => row.id.equals(logId))).go();
      return true;
    }
    if (snapshot == null) {
      return true;
    }
    final remoteUpdatedAt =
        _date(snapshot['updatedAt']) ?? _date(snapshot['createdAt']) ?? DateTime.now();
    if (await _deleteTombstoneIsNotOlder('workout_log:$syncId', remoteUpdatedAt)) {
      return true;
    }
    return _upsertRemoteWorkoutLog(db, snapshot);
  }

  Future<bool> _applyRemoteCustomExerciseEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    if (!locator.isRegistered<CustomExerciseDatabase>()) {
      return false;
    }
    final db = locator<CustomExerciseDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final exerciseId = await _localCustomExerciseIdBySyncId(db, syncId);
    if (action == 'delete' || snapshot?['deleted'] == true) {
      await _recordDeleteTombstone(
        entityType: 'custom_exercise',
        entitySyncId: 'custom_exercise:$syncId',
        entityId: exerciseId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (exerciseId == null) {
        return true;
      }
      await (db.update(db.customExercises)..where((row) => row.id.equals(exerciseId))).write(
        CustomExercisesCompanion(
          deleted: const Value(true),
          syncStatus: const Value(localSyncSynced),
          updatedAt: Value(_date(snapshot?['updatedAt']) ?? DateTime.now()),
        ),
      );
      return true;
    }
    if (snapshot == null) {
      return true;
    }
    final now = DateTime.now();
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? now;
    if (await _deleteTombstoneIsNotOlder('custom_exercise:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (exerciseId != null && await _localCustomExerciseIsNewer(db, exerciseId, remoteUpdatedAt)) {
      return true;
    }
    if (exerciseId == null) {
      await db
          .into(db.customExercises)
          .insert(
            CustomExercisesCompanion.insert(
              syncId: Value(syncId),
              remoteId: Value(_asInt(snapshot['remoteId'])),
              chineseName: _asString(snapshot['chineseName'], fallback: '同步动作'),
              englishName: Value(_asString(snapshot['englishName'])),
              bodyPart: _asString(snapshot['bodyPart']),
              equipment: _asString(snapshot['equipment']),
              primaryMuscles: _asString(snapshot['primaryMuscles']),
              description: _asString(snapshot['description']),
              imagePathsJson: Value(jsonEncode(_asList(snapshot['imagePaths']))),
              isCustom: Value(_asBool(snapshot['isCustom']) ?? true),
              syncStatus: const Value(localSyncSynced),
              deleted: Value(_asBool(snapshot['deleted']) ?? false),
              createdAt: _date(snapshot['createdAt']) ?? now,
              updatedAt: remoteUpdatedAt,
            ),
          );
      return true;
    }
    await (db.update(db.customExercises)..where((row) => row.id.equals(exerciseId))).write(
      CustomExercisesCompanion(
        syncId: Value(syncId),
        remoteId: Value(_asInt(snapshot['remoteId'])),
        chineseName: Value(_asString(snapshot['chineseName'], fallback: '同步动作')),
        englishName: Value(_asString(snapshot['englishName'])),
        bodyPart: Value(_asString(snapshot['bodyPart'])),
        equipment: Value(_asString(snapshot['equipment'])),
        primaryMuscles: Value(_asString(snapshot['primaryMuscles'])),
        description: Value(_asString(snapshot['description'])),
        imagePathsJson: Value(jsonEncode(_asList(snapshot['imagePaths']))),
        isCustom: Value(_asBool(snapshot['isCustom']) ?? true),
        syncStatus: const Value(localSyncSynced),
        deleted: Value(_asBool(snapshot['deleted']) ?? false),
        updatedAt: Value(remoteUpdatedAt),
      ),
    );
    return true;
  }

  Future<bool> _upsertRemoteWorkoutLog(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
  ) async {
    final syncId = _asString(snapshot['syncId']);
    if (syncId.isEmpty) {
      return true;
    }
    final logId = await _localLogIdBySyncId(db, syncId);
    final createdAt = _date(snapshot['createdAt']);
    if (createdAt == null) {
      return true;
    }
    final remoteUpdatedAt = _date(snapshot['updatedAt']) ?? createdAt;
    if (logId == null && await _hasDuplicateLocalWorkoutLog(db, snapshot, createdAt)) {
      return true;
    }
    final routineId = await _ensureHistoryRoutine(
      db,
      _asString(snapshot['routineSyncId']),
      remoteUpdatedAt,
    );
    if (routineId == null) {
      return true;
    }
    final sessionId = await _ensureHistorySession(
      db,
      _asString(snapshot['sessionSyncId']),
      routineId: routineId,
      startedAt: createdAt,
      updatedAt: remoteUpdatedAt,
    );
    if (sessionId == null) {
      return true;
    }
    final dayId = await _localTrainingDayIdBySyncId(db, _asString(snapshot['daySyncId']));
    if (await _deleteTombstoneIsNotOlder('workout_log:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (logId == null) {
      await db
          .into(db.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              syncId: Value(syncId),
              remoteId: Value(_asInt(snapshot['remoteId'])),
              sessionId: sessionId,
              routineId: routineId,
              dayId: Value(dayId),
              exerciseName: canonicalExerciseReference(
                _asString(snapshot['exerciseName'], fallback: '同步动作'),
              ),
              setIndex: _asInt(snapshot['setIndex']) ?? 1,
              weight: Value(_asDouble(snapshot['weight']) ?? 0),
              reps: Value(_asInt(snapshot['reps']) ?? 0),
              rir: Value(_asDouble(snapshot['rir'])),
              durationSeconds: Value(_asInt(snapshot['durationSeconds']) ?? 0),
              recordMode: Value(normalizeLocalRecordMode(snapshot['recordMode'])),
              note: Value(_asString(snapshot['note'])),
              syncStatus: const Value(localSyncSynced),
              createdAt: createdAt,
            ),
          );
      return true;
    }
    await (db.update(db.localWorkoutLogs)..where((row) => row.id.equals(logId))).write(
      LocalWorkoutLogsCompanion(
        syncId: Value(syncId),
        remoteId: Value(_asInt(snapshot['remoteId'])),
        sessionId: Value(sessionId),
        routineId: Value(routineId),
        dayId: Value(dayId),
        exerciseName: Value(
          canonicalExerciseReference(
            _asString(snapshot['exerciseName'], fallback: '同步动作'),
          ),
        ),
        setIndex: Value(_asInt(snapshot['setIndex']) ?? 1),
        weight: Value(_asDouble(snapshot['weight']) ?? 0),
        reps: Value(_asInt(snapshot['reps']) ?? 0),
        rir: Value(_asDouble(snapshot['rir'])),
        durationSeconds: Value(_asInt(snapshot['durationSeconds']) ?? 0),
        recordMode: Value(normalizeLocalRecordMode(snapshot['recordMode'])),
        note: Value(_asString(snapshot['note'])),
        syncStatus: const Value(localSyncSynced),
        createdAt: Value(createdAt),
      ),
    );
    return true;
  }

  Future<bool> _hasDuplicateLocalSession(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
    DateTime startedAt,
  ) async {
    final endedAt = _date(snapshot['endedAt']);
    final note = _asString(snapshot['note']);
    final candidates =
        await (db.select(db.localWorkoutSessions)..where(
              (row) =>
                  row.startedAt.equals(startedAt) &
                  (endedAt == null ? row.endedAt.isNull() : row.endedAt.equals(endedAt)) &
                  row.note.equals(note),
            ))
            .get();
    if (candidates.isEmpty) {
      return false;
    }
    final logs = _asList(snapshot['logs']).whereType<Map>().toList();
    if (logs.isEmpty) {
      return true;
    }
    for (final candidate in candidates) {
      var allLogsAlreadyExist = true;
      for (final log in logs) {
        final createdAt = _date(log['createdAt']);
        if (createdAt == null ||
            !await _hasDuplicateLocalWorkoutLog(
              db,
              Map<String, dynamic>.from(log),
              createdAt,
              sessionId: candidate.id,
            )) {
          allLogsAlreadyExist = false;
          break;
        }
      }
      if (allLogsAlreadyExist) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _hasDuplicateLocalWorkoutLog(
    LocalTrainingDatabase db,
    Map<String, dynamic> snapshot,
    DateTime createdAt, {
    int? sessionId,
  }) async {
    final query = db.select(db.localWorkoutLogs)
      ..where(
        (row) =>
            row.createdAt.equals(createdAt) &
            row.exerciseName.equals(
              canonicalExerciseReference(
                _asString(snapshot['exerciseName'], fallback: '同步动作'),
              ),
            ) &
            row.setIndex.equals(_asInt(snapshot['setIndex']) ?? 1) &
            row.weight.equals(_asDouble(snapshot['weight']) ?? 0) &
            row.reps.equals(_asInt(snapshot['reps']) ?? 0) &
            (_asDouble(snapshot['rir']) == null
                ? row.rir.isNull()
                : row.rir.equals(_asDouble(snapshot['rir'])!)) &
            row.durationSeconds.equals(_asInt(snapshot['durationSeconds']) ?? 0) &
            row.recordMode.equals(normalizeLocalRecordMode(snapshot['recordMode'])) &
            row.note.equals(_asString(snapshot['note'])),
      );
    if (sessionId != null) {
      query.where((row) => row.sessionId.equals(sessionId));
    }
    return await query.getSingleOrNull() != null;
  }

  Future<bool> _deleteTombstoneIsNotOlder(
    String entitySyncId,
    DateTime remoteUpdatedAt,
  ) async {
    if (!locator.isRegistered<LocalTrainingDatabase>()) {
      return false;
    }
    final db = locator<LocalTrainingDatabase>();
    final tombstone =
        await (db.select(db.localSyncQueue)
              ..where(
                (row) => row.entitySyncId.equals(entitySyncId) & row.action.equals('delete'),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (tombstone == null) {
      return false;
    }
    return !tombstone.updatedAt.isBefore(remoteUpdatedAt);
  }

  Future<void> _recordDeleteTombstone({
    required String entityType,
    required String entitySyncId,
    required int? entityId,
    required DateTime? updatedAt,
  }) async {
    if (!locator.isRegistered<LocalTrainingDatabase>()) {
      return;
    }
    final db = locator<LocalTrainingDatabase>();
    final timestamp = updatedAt ?? DateTime.now();
    final existing =
        await (db.select(db.localSyncQueue)
              ..where(
                (row) => row.entitySyncId.equals(entitySyncId) & row.action.equals('delete'),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null && !existing.updatedAt.isBefore(timestamp)) {
      return;
    }
    await db
        .into(db.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: Value(SyncId.newId()),
            deviceId: Value(await _deviceId()),
            entityType: entityType,
            entityId: entityId ?? 0,
            entitySyncId: Value(entitySyncId),
            action: 'delete',
            payload: const Value('{}'),
            status: const Value(localSyncSynced),
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );
  }

  Future<void> _replaceRemoteDaySlots(
    LocalTrainingDatabase db, {
    required int dayId,
    required List<Object?> actions,
  }) async {
    await _deleteDayChildren(db, dayId);
    for (var i = 0; i < actions.length; i++) {
      final action = _asMap(actions[i]);
      if (action == null) {
        continue;
      }
      final slotId = await db
          .into(db.localSlots)
          .insert(
            LocalSlotsCompanion.insert(
              syncId: Value(_asString(action['slotSyncId'], fallback: SyncId.newId())),
              dayId: dayId,
              order: i,
              syncStatus: const Value(localSyncSynced),
            ),
          );
      await db
          .into(db.localSlotEntries)
          .insert(
            LocalSlotEntriesCompanion.insert(
              syncId: Value(_asString(action['syncId'], fallback: SyncId.newId())),
              slotId: slotId,
              exerciseName: canonicalExerciseReference(
                _asString(action['name'], fallback: '同步动作'),
              ),
              targetSets: Value(_asInt(action['targetSets']) ?? 3),
              targetReps: Value(_asInt(action['targetReps'])),
              targetWeight: Value(_asDouble(action['targetWeight'])),
              recordMode: Value(normalizeLocalRecordMode(action['recordMode'])),
              syncStatus: const Value(localSyncSynced),
            ),
          );
    }
  }

  Future<void> _deleteDayChildren(LocalTrainingDatabase db, int dayId) async {
    final slots = await (db.select(db.localSlots)..where((slot) => slot.dayId.equals(dayId))).get();
    for (final slot in slots) {
      await (db.delete(db.localSlotEntries)..where((entry) => entry.slotId.equals(slot.id))).go();
    }
    await (db.delete(db.localSlots)..where((slot) => slot.dayId.equals(dayId))).go();
  }

  Future<bool> _localRoutineExists(LocalTrainingDatabase db, int id) async {
    final row = await (db.select(
      db.localRoutines,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row != null;
  }

  Future<int?> _ensureHistoryRoutine(
    LocalTrainingDatabase db,
    String syncId,
    DateTime updatedAt,
  ) async {
    if (syncId.trim().isEmpty) {
      return null;
    }
    final existingId = await _localRoutineIdBySyncId(db, syncId);
    if (existingId != null) {
      return existingId;
    }
    return db
        .into(db.localRoutines)
        .insert(
          LocalRoutinesCompanion.insert(
            syncId: Value(syncId),
            name: '历史训练记录',
            totalWeeks: const Value(1),
            daysPerWeek: const Value(1),
            archived: const Value(true),
            completedWeeksJson: const Value('[]'),
            syncStatus: const Value(localSyncSynced),
            deleted: const Value(true),
            createdAt: updatedAt,
            updatedAt: updatedAt,
          ),
        );
  }

  Future<int?> _ensureHistorySession(
    LocalTrainingDatabase db,
    String syncId, {
    required int routineId,
    required DateTime startedAt,
    required DateTime updatedAt,
  }) async {
    if (syncId.trim().isEmpty) {
      return null;
    }
    final existingId = await _localSessionIdBySyncId(db, syncId);
    if (existingId != null) {
      return existingId;
    }
    return db
        .into(db.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            syncId: Value(syncId),
            routineId: routineId,
            startedAt: startedAt,
            note: const Value(''),
            syncStatus: const Value(localSyncSynced),
            updatedAt: updatedAt,
          ),
        );
  }

  Future<Map<String, Object?>?> _snapshotFor(LocalSyncQueueData item) async {
    if (item.action == 'delete') {
      return null;
    }
    switch (item.entityType) {
      case 'routine':
        return _routineSnapshot(item.entityId);
      case 'workout_session':
        return _sessionSnapshot(item.entityId);
      case 'workout_log':
        return _workoutLogSnapshot(item.entityId);
      case 'custom_exercise':
        return _customExerciseSnapshot(item.entityId);
      default:
        return null;
    }
  }

  Future<Map<String, Object?>?> _routineSnapshot(int id) async {
    final db = locator<LocalTrainingDatabase>();
    final routine = await (db.select(
      db.localRoutines,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (routine == null) {
      return null;
    }
    final days =
        await (db.select(db.localTrainingDays)
              ..where((row) => row.routineId.equals(id))
              ..orderBy([
                (row) => OrderingTerm.asc(row.week),
                (row) => OrderingTerm.asc(row.day),
              ]))
            .get();
    final daySnapshots = <Map<String, Object?>>[];
    for (final day in days) {
      daySnapshots.add({
        'id': day.id,
        'syncId': day.syncId,
        'remoteId': day.remoteId,
        'week': day.week,
        'day': day.day,
        'name': day.name,
        'actions': await _dayActionsSnapshot(db, day),
        'updatedAt': day.updatedAt.toIso8601String(),
      });
    }
    return {
      'id': routine.id,
      'syncId': routine.syncId,
      'remoteId': routine.remoteId,
      'name': routine.name,
      'totalWeeks': routine.totalWeeks,
      'daysPerWeek': routine.daysPerWeek,
      'archived': routine.archived,
      'completedWeeks': _asList(jsonDecode(routine.completedWeeksJson)),
      'deleted': routine.deleted,
      'createdAt': routine.createdAt.toIso8601String(),
      'updatedAt': routine.updatedAt.toIso8601String(),
      'days': daySnapshots,
    };
  }

  Future<List<Object?>> _dayActionsSnapshot(
    LocalTrainingDatabase db,
    LocalTrainingDay day,
  ) async {
    final rawActions = _asList(jsonDecode(day.actionsJson));
    final slots =
        await (db.select(db.localSlots)
              ..where((slot) => slot.dayId.equals(day.id))
              ..orderBy([(slot) => OrderingTerm.asc(slot.order)]))
            .get();
    final actions = rawActions
        .map((item) => _asMap(item) ?? {'name': '$item'})
        .map((item) => Map<String, Object?>.from(item))
        .toList();
    for (final slot in slots) {
      if (slot.order < 0 || slot.order >= actions.length) {
        continue;
      }
      final entry = await (db.select(
        db.localSlotEntries,
      )..where((row) => row.slotId.equals(slot.id))).getSingleOrNull();
      if (entry == null) {
        continue;
      }
      actions[slot.order] = {
        ...actions[slot.order],
        'slotSyncId': slot.syncId,
        'syncId': entry.syncId,
        'name': entry.exerciseName,
        'targetSets': entry.targetSets,
        'targetReps': entry.targetReps,
        if (entry.targetWeight != null) 'targetWeight': entry.targetWeight,
        if (normalizeLocalRecordMode(entry.recordMode) != localRecordModeStandard)
          'recordMode': normalizeLocalRecordMode(entry.recordMode),
      };
    }
    return actions;
  }

  Future<Map<String, Object?>?> _sessionSnapshot(int id) async {
    final db = locator<LocalTrainingDatabase>();
    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (session == null) {
      return null;
    }
    final logs =
        await (db.select(db.localWorkoutLogs)
              ..where((row) => row.sessionId.equals(id))
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return {
      'id': session.id,
      'syncId': session.syncId,
      'remoteId': session.remoteId,
      'routineId': session.routineId,
      'routineSyncId': await _routineSyncIdById(db, session.routineId),
      'dayId': session.dayId,
      'daySyncId': await _daySyncIdById(db, session.dayId),
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt?.toIso8601String(),
      'note': session.note,
      'updatedAt': session.updatedAt.toIso8601String(),
      'logs': [
        for (final log in logs) await _workoutLogToJson(log),
      ],
    };
  }

  Future<Map<String, Object?>?> _workoutLogSnapshot(int id) async {
    final db = locator<LocalTrainingDatabase>();
    final log = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return log == null ? null : _workoutLogToJson(log);
  }

  Future<Map<String, Object?>?> _customExerciseSnapshot(int id) async {
    if (!locator.isRegistered<CustomExerciseDatabase>()) {
      return null;
    }
    final db = locator<CustomExerciseDatabase>();
    final exercise = await (db.select(
      db.customExercises,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (exercise == null) {
      return null;
    }
    return {
      'id': exercise.id,
      'syncId': exercise.syncId,
      'remoteId': exercise.remoteId,
      'chineseName': exercise.chineseName,
      'englishName': exercise.englishName,
      'bodyPart': exercise.bodyPart,
      'equipment': exercise.equipment,
      'primaryMuscles': exercise.primaryMuscles,
      'description': exercise.description,
      'imagePaths': jsonDecode(exercise.imagePathsJson),
      'isCustom': exercise.isCustom,
      'deleted': exercise.deleted,
      'createdAt': exercise.createdAt.toIso8601String(),
      'updatedAt': exercise.updatedAt.toIso8601String(),
    };
  }

  Future<String?> _routineSyncIdById(LocalTrainingDatabase db, int id) async {
    final row = await (db.select(
      db.localRoutines,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> _daySyncIdById(LocalTrainingDatabase db, int? id) async {
    if (id == null) {
      return null;
    }
    final row = await (db.select(
      db.localTrainingDays,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> _sessionSyncIdById(LocalTrainingDatabase db, int id) async {
    final row = await (db.select(
      db.localWorkoutSessions,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<Map<String, Object?>> _workoutLogToJson(LocalWorkoutLog log) async {
    final db = locator<LocalTrainingDatabase>();
    return {
      'id': log.id,
      'syncId': log.syncId,
      'remoteId': log.remoteId,
      'sessionId': log.sessionId,
      'sessionSyncId': await _sessionSyncIdById(db, log.sessionId),
      'routineId': log.routineId,
      'routineSyncId': await _routineSyncIdById(db, log.routineId),
      'dayId': log.dayId,
      'daySyncId': await _daySyncIdById(db, log.dayId),
      'exerciseName': log.exerciseName,
      'setIndex': log.setIndex,
      'weight': log.weight,
      'reps': log.reps,
      'rir': log.rir,
      'durationSeconds': log.durationSeconds,
      if (normalizeLocalRecordMode(log.recordMode) != localRecordModeStandard)
        'recordMode': normalizeLocalRecordMode(log.recordMode),
      'note': log.note,
      'createdAt': log.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<Object?> _asList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return const [];
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    return null;
  }

  String _asString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  DateTime? _date(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<_BackupFile> _describeFile(File file, String archiveName) async {
    final bytes = await file.readAsBytes();
    return _BackupFile(
      path: archiveName,
      bytes: bytes.length,
      sha256Hash: sha256.convert(bytes).toString(),
    );
  }

  _BackupFile _describeText(String archiveName, String text) {
    final bytes = utf8.encode(text);
    return _BackupFile(
      path: archiveName,
      bytes: bytes.length,
      sha256Hash: sha256.convert(bytes).toString(),
    );
  }

  String _dateKey(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }
}

class _ServerEventPage {
  final List<Map<String, dynamic>> events;
  final int cursor;
  final int latestCursor;
  final bool hasMore;
  final bool legacyServer;

  const _ServerEventPage({
    required this.events,
    required this.cursor,
    required this.latestCursor,
    required this.hasMore,
    required this.legacyServer,
  });
}

class _ServerEventPullResult {
  final int downloadedCount;
  final int appliedCount;
  final int failedCount;
  final int latestCursor;

  const _ServerEventPullResult({
    required this.downloadedCount,
    required this.appliedCount,
    required this.failedCount,
    required this.latestCursor,
  });
}

class _BackupFile {
  final String path;
  final int bytes;
  final String sha256Hash;

  const _BackupFile({
    required this.path,
    required this.bytes,
    required this.sha256Hash,
  });

  Map<String, Object?> toJson() => {
    'path': path,
    'bytes': bytes,
    'sha256': sha256Hash,
  };
}

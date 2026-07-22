import 'dart:async';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show ShareResult;
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_archive_service.dart';
import 'package:yours/redesign/data/backup_diagnostics_service.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_platform_bridge.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/server_sync_client.dart';
import 'package:yours/redesign/data/server_sync_engine.dart';
import 'package:yours/redesign/data/server_sync_event_applier.dart';
import 'package:yours/redesign/data/server_sync_snapshot_builder.dart';
import 'package:yours/redesign/data/yours_exception.dart';

export 'package:yours/redesign/data/backup_models.dart';

class BackupService {
  static const _backupFileName = 'yours-backup.zip';
  static const _supportedServerProtocolVersion = 2;

  late final BackupPreferencesStore _preferences = BackupPreferencesStore();
  late final BackupPlatformBridge _platformBridge = BackupPlatformBridge();
  late final ServerSyncClient _serverClient = ServerSyncClient();
  late final BackupArchiveService _archiveService = BackupArchiveService(
    preferences: _preferences,
    serverProtocolVersion: _supportedServerProtocolVersion,
  );
  late final BackupDiagnosticsService _diagnosticsService = BackupDiagnosticsService(
    preferences: _preferences,
    serverClient: _serverClient,
    supportedServerProtocolVersion: _supportedServerProtocolVersion,
  );
  late final ServerSyncSnapshotBuilder _snapshotBuilder = const ServerSyncSnapshotBuilder();
  late final ServerSyncEventApplier _eventApplier = ServerSyncEventApplier(
    preferences: _preferences,
  );
  late final ServerSyncEngine _syncEngine = ServerSyncEngine(
    preferences: _preferences,
    serverClient: _serverClient,
    archiveService: _archiveService,
    snapshotBuilder: _snapshotBuilder,
    eventApplier: _eventApplier,
    createBackup: createBackup,
    uploadBackup: uploadBackupToServer,
  );

  Future<Directory> getBackupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<File?> latestBackup() async {
    final visibleBackup = await _platformBridge.copyVisibleBackupIntoLocalDirectory();
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

  Future<BackupResult> createBackup({bool exportVisible = false}) async {
    final backupDir = await getBackupDirectory();
    final output = File(p.join(backupDir.path, _backupFileName));
    final result = await _archiveService.writeBackupFile(output);
    await _archiveService.deleteSiblingZipFiles(backupDir, keep: output);
    if (exportVisible) {
      await _platformBridge.syncBackupToVisibleDocuments(output);
    }
    return result;
  }

  Future<BackupResult?> createAutomaticBackupIfNeeded({
    required String reason,
    bool daily = false,
    bool force = false,
  }) async {
    final now = DateTime.now();
    final lastAutoBackupAt = await _preferences.lastAutoBackupAt();
    final latestChangeAt = await _latestPendingChangeAt();
    final today = BackupPreferencesStore.dateKey(now);
    final lastDailyBackupDate = await _preferences.lastDailyBackupDate();

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
    return _platformBridge.shareBackup(
      backup,
      sharePositionOrigin: sharePositionOrigin,
      title: title,
      subject: subject,
      text: text,
    );
  }

  Future<ICloudDriveStatus> getICloudStatus() async {
    return _platformBridge.getICloudStatus();
  }

  Future<ICloudDriveExportResult> exportLatestBackupToICloudDrive() async {
    final latest = await latestBackup() ?? (await createBackup()).file;
    return exportBackupToICloudDrive(latest);
  }

  Future<ICloudDriveExportResult> exportBackupToICloudDrive(File backup) async {
    return _platformBridge.exportBackupToICloudDrive(backup);
  }

  Future<File?> pickBackupFile() async {
    return _platformBridge.pickBackupFile();
  }

  Future<File?> pickICloudBackup() async {
    return _platformBridge.pickICloudBackup();
  }

  Future<ServerBackupSettings> loadServerBackupSettings() async {
    return _preferences.loadServerBackupSettings();
  }

  Future<void> saveServerBackupSettings(ServerBackupSettings settings) async {
    await _preferences.saveServerBackupSettings(settings);
  }

  Future<ServerBackupUploadResult> uploadLatestBackupToServer() async {
    final current = await createBackup();
    return uploadBackupToServer(current.file);
  }

  Future<ServerBackupUploadResult> uploadBackupToServer(File backup) async {
    final settings = await loadServerBackupSettings();
    return _serverClient.uploadBackup(backup, settings: settings);
  }

  Future<ServerBackupDownloadResult> downloadLatestBackupFromServer() async {
    final settings = await loadServerBackupSettings();
    return _serverClient.downloadLatestBackup(
      settings: settings,
      backupDir: await getBackupDirectory(),
    );
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
    return _syncEngine.uploadPendingChangesToServer(limit: limit);
  }

  Future<ServerSnapshotSyncResult> syncPendingChangesAndUploadSnapshot({
    int batchSize = 100,
  }) async {
    return _syncEngine.syncPendingChangesAndUploadSnapshot(batchSize: batchSize);
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
    return _eventApplier.applyRemoteEvent(event);
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

  Future<ServerSyncStatus> checkServerSyncStatus() async {
    return _diagnosticsService.checkServerSyncStatus();
  }

  Future<String> serverDiagnosticsText() async {
    return _diagnosticsService.serverDiagnosticsText();
  }

  Future<RestoreResult> restoreLatestBackup() async {
    final latest =
        await _platformBridge.copyVisibleBackupIntoLocalDirectory() ??
        await _platformBridge.pickVisibleBackupIntoLocalDirectory() ??
        await _latestInternalBackup();
    if (latest == null) {
      throw const YoursException(YoursErrorCode.noServerBackup);
    }
    return restoreBackup(latest);
  }

  Future<RestoreResult> restoreBackup(File backup) async {
    return _archiveService.restoreBackup(backup);
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
    await _preferences.rememberAutomaticBackup(result, reason: reason, daily: daily);
  }

  Future<int?> _serverCursorFromBackup(File backup) async {
    return _archiveService.serverCursorFromBackup(backup);
  }

  bool _shouldBackupPreference(String key) {
    return _preferences.shouldBackupPreference(key);
  }

  Future<void> _setServerEventCursor(int cursor) async {
    await _preferences.setServerEventCursor(cursor);
  }
}

import 'dart:io';

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

class ServerEventPage {
  final List<Map<String, dynamic>> events;
  final int cursor;
  final int latestCursor;
  final bool hasMore;
  final bool legacyServer;

  const ServerEventPage({
    required this.events,
    required this.cursor,
    required this.latestCursor,
    required this.hasMore,
    required this.legacyServer,
  });
}

class ServerEventPullResult {
  final int downloadedCount;
  final int appliedCount;
  final int failedCount;
  final int latestCursor;

  const ServerEventPullResult({
    required this.downloadedCount,
    required this.appliedCount,
    required this.failedCount,
    required this.latestCursor,
  });
}

class BackupManifestFile {
  final String path;
  final int bytes;
  final String sha256Hash;

  const BackupManifestFile({
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

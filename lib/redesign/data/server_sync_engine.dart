import 'dart:io';

import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_archive_service.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/server_sync_client.dart';
import 'package:yours/redesign/data/server_sync_event_applier.dart';
import 'package:yours/redesign/data/server_sync_snapshot_builder.dart';
import 'package:yours/redesign/data/yours_exception.dart';

typedef CreateBackup = Future<BackupResult> Function();
typedef UploadBackup = Future<ServerBackupUploadResult> Function(File backup);

class ServerSyncEngine {
  const ServerSyncEngine({
    required BackupPreferencesStore preferences,
    required ServerSyncClient serverClient,
    required BackupArchiveService archiveService,
    required ServerSyncSnapshotBuilder snapshotBuilder,
    required ServerSyncEventApplier eventApplier,
    required CreateBackup createBackup,
    required UploadBackup uploadBackup,
  }) : _preferences = preferences,
       _serverClient = serverClient,
       _archiveService = archiveService,
       _snapshotBuilder = snapshotBuilder,
       _eventApplier = eventApplier,
       _createBackup = createBackup,
       _uploadBackup = uploadBackup;

  final BackupPreferencesStore _preferences;
  final ServerSyncClient _serverClient;
  final BackupArchiveService _archiveService;
  final ServerSyncSnapshotBuilder _snapshotBuilder;
  final ServerSyncEventApplier _eventApplier;
  final CreateBackup _createBackup;
  final UploadBackup _uploadBackup;

  Future<ServerIncrementalSyncResult> uploadPendingChangesToServer({
    int limit = 100,
  }) async {
    final settings = await _preferences.loadServerBackupSettings();
    final endpoint = _serverClient.eventsEndpoint(settings);
    final deviceId = await _preferences.deviceId();
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
      final event = await _snapshotBuilder.buildLocalEvent(item, deviceId: deviceId);
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

    try {
      await _serverClient.postEvents(settings: settings, events: events);
    } on Object {
      await syncQueue.markFailed(
        items.where((item) => !obsoleteIds.contains(item.id)).map((item) => item.id).toList(),
      );
      rethrow;
    }

    final uploadedItems = items.where((item) => !obsoleteIds.contains(item.id)).toList();
    await syncQueue.markSynced(uploadedItems.map((item) => item.id).toList());
    return ServerIncrementalSyncResult(
      endpoint: endpoint,
      uploadedCount: uploadedItems.length,
      entitySyncIds: uploadedItems.map(_entitySyncIdForQueueItem).toSet(),
      syncedAt: DateTime.now(),
    );
  }

  Future<ServerSnapshotSyncResult> syncPendingChangesAndUploadSnapshot({
    int batchSize = 100,
  }) async {
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

    await _archiveService.createRestoreSafetyBackup();
    final pull = await pullAndApplyServerEvents(
      skipEntitySyncIds: localChangedEntitySyncIds,
    );
    if (pull.failedCount > 0) {
      await _preferences.setServerLastFailure(
        _syncFailureText(pull.firstFailure, failedCount: pull.failedCount),
      );
      throw YoursException(
        YoursErrorCode.unappliedServerChanges,
        count: pull.failedCount,
        cause: pull.firstFailure,
      );
    }
    final backup = await _createBackup();
    final upload = await _uploadBackup(backup.file);
    await _preferences.clearServerLastFailure();
    return ServerSnapshotSyncResult(
      uploadedCount: uploadedCount,
      downloadedEventCount: pull.downloadedCount,
      appliedEventCount: pull.appliedCount,
      latestCursor: pull.latestCursor,
      backup: backup,
      upload: upload,
      syncedAt: DateTime.now(),
    );
  }

  String _syncFailureText(ServerEventFailureDetail? failure, {required int failedCount}) {
    final detail = failure?.toString().trim();
    if (detail == null || detail.isEmpty) {
      return 'failedCount=$failedCount';
    }
    return 'failedCount=$failedCount, $detail';
  }

  Future<ServerEventPullResult> pullAndApplyServerEvents({
    int limit = 500,
    Set<String> skipEntitySyncIds = const <String>{},
  }) async {
    final settings = await _preferences.loadServerBackupSettings();
    final deviceId = await _preferences.deviceId();
    var cursor = await _preferences.serverEventCursor();
    var downloadedCount = 0;
    var appliedCount = 0;
    var failedCount = 0;
    var latestCursor = cursor;
    ServerEventFailureDetail? firstFailure;

    while (true) {
      final pull = await _serverClient.downloadEvents(
        settings: settings,
        after: cursor,
        limit: limit,
      );
      if (pull.legacyServer) {
        break;
      }
      if (pull.latestCursor < cursor) {
        cursor = 0;
        await _preferences.setServerEventCursor(cursor);
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
          if (await _eventApplier.applyRemoteEvent(event)) {
            appliedCount += 1;
          } else {
            failedCount += 1;
            firstFailure ??= _failureDetail(
              record,
              event,
              reason: 'applyRemoteEvent returned false',
            );
            pageFailed = true;
          }
        } on Object catch (error) {
          // 单条旧事件不能阻断整次同步。下一次快照仍会兜底保留完整数据。
          failedCount += 1;
          firstFailure ??= _failureDetail(record, event, reason: '$error');
          pageFailed = true;
        }
      }
      if (pageFailed) {
        break;
      }
      cursor = pull.cursor;
      await _preferences.setServerEventCursor(cursor);
      if (!pull.hasMore) {
        break;
      }
    }

    if (failedCount == 0 && latestCursor > cursor) {
      await _preferences.setServerEventCursor(latestCursor);
    }
    return ServerEventPullResult(
      downloadedCount: downloadedCount,
      appliedCount: appliedCount,
      failedCount: failedCount,
      latestCursor: latestCursor,
      firstFailure: firstFailure,
    );
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

  ServerEventFailureDetail _failureDetail(
    Map<String, dynamic> record,
    Map<String, dynamic> event, {
    required String reason,
  }) {
    return ServerEventFailureDetail(
      serverSeq: _asInt(record['serverSeq']),
      entityType: _asString(event['entityType'], fallback: 'unknown'),
      action: _asString(event['action'], fallback: 'unknown'),
      entitySyncId: _entitySyncIdForEvent(event),
      reason: reason,
    );
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

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _asString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }
}

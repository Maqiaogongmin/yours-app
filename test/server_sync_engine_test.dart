import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_archive_service.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/server_sync_client.dart';
import 'package:yours/redesign/data/server_sync_engine.dart';
import 'package:yours/redesign/data/server_sync_event_applier.dart';
import 'package:yours/redesign/data/server_sync_snapshot_builder.dart';
import 'package:yours/redesign/data/yours_exception.dart';

final class _FakeBackupPreferencesStore extends BackupPreferencesStore {
  _FakeBackupPreferencesStore({this.cursor = 0});

  int cursor;
  final String device = 'local-device';
  final cursorWrites = <int>[];

  @override
  Future<ServerBackupSettings> loadServerBackupSettings() async {
    return const ServerBackupSettings(
      baseUrl: 'https://sync.example',
      apiToken: 'token',
    );
  }

  @override
  Future<String> deviceId() async => device;

  @override
  Future<int> serverEventCursor() async => cursor;

  @override
  Future<void> setServerEventCursor(int value) async {
    cursor = value;
    cursorWrites.add(value);
  }
}

final class _FakeServerSyncClient extends ServerSyncClient {
  bool failPost = false;
  final postedEvents = <List<Map<String, Object?>>>[];
  final pages = <ServerEventPage>[];

  @override
  Uri eventsEndpoint(ServerBackupSettings settings) {
    return Uri.parse('${settings.baseUrl}/api/yours-sync/events');
  }

  @override
  Future<Uri> postEvents({
    required ServerBackupSettings settings,
    required List<Map<String, Object?>> events,
  }) async {
    if (failPost) {
      throw const YoursException(YoursErrorCode.invalidServerResponse);
    }
    postedEvents.add(events);
    return eventsEndpoint(settings);
  }

  @override
  Future<ServerEventPage> downloadEvents({
    required ServerBackupSettings settings,
    required int after,
    required int limit,
  }) async {
    return pages.removeAt(0);
  }
}

final class _FakeBackupArchiveService extends BackupArchiveService {
  _FakeBackupArchiveService(BackupPreferencesStore preferences)
    : super(preferences: preferences, serverProtocolVersion: 2);

  var safetyBackupCount = 0;

  @override
  Future<BackupResult> createRestoreSafetyBackup() async {
    safetyBackupCount += 1;
    return BackupResult(
      file: File('safety.zip'),
      fileCount: 0,
      byteCount: 0,
      createdAt: DateTime.now(),
    );
  }
}

final class _FakeServerSyncSnapshotBuilder extends ServerSyncSnapshotBuilder {
  _FakeServerSyncSnapshotBuilder({this.buildLocalEventOverride});

  final Future<Map<String, Object?>?> Function(
    LocalSyncQueueData item, {
    required String deviceId,
  })?
  buildLocalEventOverride;

  @override
  Future<Map<String, Object?>?> buildLocalEvent(
    LocalSyncQueueData item, {
    required String deviceId,
  }) async {
    final override = buildLocalEventOverride;
    if (override != null) {
      return override(item, deviceId: deviceId);
    }
    return {
      'eventId': item.eventId,
      'deviceId': deviceId,
      'entityType': item.entityType,
      'entityId': item.entityId,
      'entitySyncId': item.entitySyncId,
      'action': item.action,
    };
  }
}

final class _FakeServerSyncEventApplier extends ServerSyncEventApplier {
  _FakeServerSyncEventApplier(
    BackupPreferencesStore preferences, {
    this.applyRemoteEventOverride,
  }) : super(preferences: preferences);

  final Future<bool> Function(Map<String, dynamic> event)? applyRemoteEventOverride;

  @override
  Future<bool> applyRemoteEvent(Map<String, dynamic> event) async {
    return applyRemoteEventOverride?.call(event) ?? true;
  }
}

void main() {
  Future<LocalTrainingDatabase> registerDatabase() async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });
    return db;
  }

  Future<int> insertQueueItem(
    LocalTrainingDatabase db, {
    String eventId = 'event-1',
    String entityType = 'routine',
    int entityId = 1,
    String entitySyncId = 'routine:sync-1',
    String action = 'upsert',
    String payload = '{}',
    String status = localSyncPending,
  }) async {
    final now = DateTime(2026, 6, 18, 12).millisecondsSinceEpoch;
    await db.customStatement(
      '''
      INSERT INTO local_sync_queue
        (event_id, device_id, entity_type, entity_id, entity_sync_id, action, payload, status, attempts, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
      ''',
      [
        eventId,
        'local-device',
        entityType,
        entityId,
        entitySyncId,
        action,
        payload,
        status,
        now,
        now,
      ],
    );
    final row = await db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return row.read<int>('id');
  }

  ServerSyncEngine engine({
    required _FakeBackupPreferencesStore preferences,
    required _FakeServerSyncClient client,
    _FakeBackupArchiveService? archive,
    _FakeServerSyncSnapshotBuilder? snapshotBuilder,
    _FakeServerSyncEventApplier? eventApplier,
    Future<Map<String, Object?>?> Function(
      LocalSyncQueueData item, {
      required String deviceId,
    })?
    buildLocalEvent,
    Future<bool> Function(Map<String, dynamic> event)? applyRemoteEvent,
  }) {
    return ServerSyncEngine(
      preferences: preferences,
      serverClient: client,
      archiveService: archive ?? _FakeBackupArchiveService(preferences),
      snapshotBuilder:
          snapshotBuilder ??
          _FakeServerSyncSnapshotBuilder(buildLocalEventOverride: buildLocalEvent),
      eventApplier:
          eventApplier ??
          _FakeServerSyncEventApplier(
            preferences,
            applyRemoteEventOverride: applyRemoteEvent,
          ),
      createBackup: () async => BackupResult(
        file: File('backup.zip'),
        fileCount: 1,
        byteCount: 1,
        createdAt: DateTime.now(),
      ),
      uploadBackup: (backup) async => ServerBackupUploadResult(
        source: backup,
        endpoint: Uri.parse('https://sync.example/api/yours-backups/latest'),
        uploadedAt: DateTime.now(),
      ),
    );
  }

  test('server sync engine uploads pending queue items and marks them synced', () async {
    final db = await registerDatabase();
    await insertQueueItem(db);
    final preferences = _FakeBackupPreferencesStore();
    final client = _FakeServerSyncClient();

    final result = await engine(
      preferences: preferences,
      client: client,
    ).uploadPendingChangesToServer();
    final queue = (await db.select(db.localSyncQueue).get()).single;

    expect(result.uploadedCount, 1);
    expect(result.entitySyncIds, {'routine:sync-1'});
    expect(client.postedEvents.single.single['entitySyncId'], 'routine:sync-1');
    expect(queue.status, localSyncSynced);
  });

  test('server sync engine marks uploaded queue items failed when post fails', () async {
    final db = await registerDatabase();
    await insertQueueItem(db);
    final preferences = _FakeBackupPreferencesStore();
    final client = _FakeServerSyncClient()..failPost = true;

    await expectLater(
      engine(preferences: preferences, client: client).uploadPendingChangesToServer(),
      throwsA(isA<YoursException>()),
    );
    final queue = (await db.select(db.localSyncQueue).get()).single;

    expect(queue.status, localSyncFailed);
    expect(queue.attempts, 1);
  });

  test('server sync engine marks obsolete queue items synced without uploading them', () async {
    final db = await registerDatabase();
    await insertQueueItem(db, eventId: 'obsolete-event', entitySyncId: 'routine:obsolete');
    await insertQueueItem(db, eventId: 'live-event', entitySyncId: 'routine:live');
    final preferences = _FakeBackupPreferencesStore();
    final client = _FakeServerSyncClient();

    final result = await engine(
      preferences: preferences,
      client: client,
      buildLocalEvent: (item, {required deviceId}) async {
        if (item.entitySyncId == 'routine:obsolete') {
          return null;
        }
        return {
          'eventId': item.eventId,
          'deviceId': deviceId,
          'entityType': item.entityType,
          'entityId': item.entityId,
          'entitySyncId': item.entitySyncId,
          'action': item.action,
        };
      },
    ).uploadPendingChangesToServer();
    final queue = await db.select(db.localSyncQueue).get();

    expect(result.uploadedCount, 1);
    expect(result.entitySyncIds, {'routine:live'});
    expect(client.postedEvents.single, hasLength(1));
    expect(client.postedEvents.single.single['entitySyncId'], 'routine:live');
    expect(queue.every((item) => item.status == localSyncSynced), isTrue);
  });

  test('server sync engine pulls remote events, skips local device, and advances cursor', () async {
    await registerDatabase();
    final preferences = _FakeBackupPreferencesStore(cursor: 4);
    final client = _FakeServerSyncClient()
      ..pages.add(
        const ServerEventPage(
          events: [
            {
              'event': {
                'deviceId': 'local-device',
                'entityType': 'routine',
                'entityId': 1,
                'entitySyncId': 'routine:local',
              },
            },
            {
              'event': {
                'deviceId': 'remote-device',
                'entityType': 'routine',
                'entityId': 2,
                'entitySyncId': 'routine:remote-1',
              },
            },
            {
              'deviceId': 'remote-device',
              'entityType': 'workout_log',
              'entityId': 3,
              'entitySyncId': 'workout_log:remote-2',
              'snapshot': {'sessionSyncId': 'session-1'},
            },
          ],
          cursor: 8,
          latestCursor: 10,
          hasMore: false,
          legacyServer: false,
        ),
      );
    final applied = <String>[];

    final result = await engine(
      preferences: preferences,
      client: client,
      applyRemoteEvent: (event) async {
        applied.add(event['entitySyncId'] as String);
        return true;
      },
    ).pullAndApplyServerEvents();

    expect(result.downloadedCount, 3);
    expect(result.appliedCount, 2);
    expect(result.failedCount, 0);
    expect(applied, ['routine:remote-1', 'workout_log:remote-2']);
    expect(preferences.cursor, 10);
    expect(preferences.cursorWrites, [8, 10]);
  });

  test('server sync engine skips remote events for freshly uploaded entity sync ids', () async {
    await registerDatabase();
    final preferences = _FakeBackupPreferencesStore(cursor: 4);
    final client = _FakeServerSyncClient()
      ..pages.add(
        const ServerEventPage(
          events: [
            {
              'deviceId': 'remote-device',
              'entityType': 'routine',
              'entityId': 1,
              'entitySyncId': 'routine:just-uploaded',
            },
            {
              'deviceId': 'remote-device',
              'entityType': 'routine',
              'entityId': 2,
              'entitySyncId': 'routine:other',
            },
          ],
          cursor: 8,
          latestCursor: 8,
          hasMore: false,
          legacyServer: false,
        ),
      );
    final applied = <String>[];

    final result = await engine(
      preferences: preferences,
      client: client,
      applyRemoteEvent: (event) async {
        applied.add(event['entitySyncId'] as String);
        return true;
      },
    ).pullAndApplyServerEvents(skipEntitySyncIds: {'routine:just-uploaded'});

    expect(result.downloadedCount, 2);
    expect(result.appliedCount, 1);
    expect(result.failedCount, 0);
    expect(applied, ['routine:other']);
    expect(preferences.cursor, 8);
  });

  test('server sync engine stops cursor advancement when a remote event fails', () async {
    await registerDatabase();
    final preferences = _FakeBackupPreferencesStore(cursor: 4);
    final client = _FakeServerSyncClient()
      ..pages.add(
        const ServerEventPage(
          events: [
            {
              'deviceId': 'remote-device',
              'entityType': 'routine',
              'entityId': 2,
              'entitySyncId': 'routine:remote-1',
            },
          ],
          cursor: 8,
          latestCursor: 10,
          hasMore: false,
          legacyServer: false,
        ),
      );

    final result = await engine(
      preferences: preferences,
      client: client,
      applyRemoteEvent: (_) async => false,
    ).pullAndApplyServerEvents();

    expect(result.downloadedCount, 1);
    expect(result.appliedCount, 0);
    expect(result.failedCount, 1);
    expect(preferences.cursor, 4);
    expect(preferences.cursorWrites, isEmpty);
  });

  test(
    'server sync engine creates safety backup before pulling and uploads snapshot after sync',
    () async {
      final db = await registerDatabase();
      await insertQueueItem(db);
      final preferences = _FakeBackupPreferencesStore(cursor: 4);
      final client = _FakeServerSyncClient()
        ..pages.add(
          const ServerEventPage(
            events: [
              {
                'deviceId': 'remote-device',
                'entityType': 'routine',
                'entityId': 2,
                'entitySyncId': 'routine:remote',
              },
            ],
            cursor: 8,
            latestCursor: 8,
            hasMore: false,
            legacyServer: false,
          ),
        );
      final archive = _FakeBackupArchiveService(preferences);
      final applied = <String>[];

      final result = await engine(
        preferences: preferences,
        client: client,
        archive: archive,
        applyRemoteEvent: (event) async {
          applied.add(event['entitySyncId'] as String);
          return true;
        },
      ).syncPendingChangesAndUploadSnapshot();

      expect(archive.safetyBackupCount, 1);
      expect(client.postedEvents, hasLength(1));
      expect(result.uploadedCount, 1);
      expect(result.downloadedEventCount, 1);
      expect(result.appliedEventCount, 1);
      expect(result.latestCursor, 8);
      expect(result.backup.file.path, 'backup.zip');
      expect(result.upload.endpoint.toString(), 'https://sync.example/api/yours-backups/latest');
      expect(applied, ['routine:remote']);
    },
  );

  test('server sync engine throws when pulled remote events cannot be applied', () async {
    await registerDatabase();
    final preferences = _FakeBackupPreferencesStore(cursor: 4);
    final client = _FakeServerSyncClient()
      ..pages.add(
        const ServerEventPage(
          events: [
            {
              'deviceId': 'remote-device',
              'entityType': 'routine',
              'entityId': 2,
              'entitySyncId': 'routine:remote',
            },
          ],
          cursor: 8,
          latestCursor: 8,
          hasMore: false,
          legacyServer: false,
        ),
      );
    final archive = _FakeBackupArchiveService(preferences);

    await expectLater(
      engine(
        preferences: preferences,
        client: client,
        archive: archive,
        applyRemoteEvent: (_) async => false,
      ).syncPendingChangesAndUploadSnapshot(),
      throwsA(
        isA<YoursException>().having(
          (error) => error.code,
          'code',
          YoursErrorCode.unappliedServerChanges,
        ),
      ),
    );

    expect(archive.safetyBackupCount, 1);
    expect(preferences.cursor, 4);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_archive_service.dart';
import 'package:yours/redesign/data/backup_diagnostics_service.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/server_sync_client.dart';
import 'package:yours/redesign/data/yours_exception.dart';

final class _FakeBackupPreferencesStore extends BackupPreferencesStore {
  _FakeBackupPreferencesStore({
    this.settings = const ServerBackupSettings(baseUrl: '', apiToken: ''),
    this.cursor = 0,
    this.deviceIdFailure,
    this.cursorFailure,
  });

  final ServerBackupSettings settings;
  final int cursor;
  final Object? deviceIdFailure;
  final Object? cursorFailure;
  String? restoredAppSettingsText;
  String? restoredSyncSettingsText;

  @override
  Future<ServerBackupSettings> loadServerBackupSettings() async => settings;

  @override
  Future<String> deviceId() async {
    final failure = deviceIdFailure;
    if (failure != null) {
      throw failure;
    }
    return 'test-device';
  }

  @override
  Future<int> serverEventCursor() async {
    final failure = cursorFailure;
    if (failure != null) {
      throw failure;
    }
    return cursor;
  }

  @override
  Future<Map<String, Object?>> readAppSettings() async {
    return {
      'schemaVersion': 1,
      'exportedAt': DateTime(2026, 6, 18).toIso8601String(),
      'sharedPreferences': <String, Object?>{},
    };
  }

  @override
  Future<void> restoreAppSettingsText(String raw) async {
    restoredAppSettingsText = raw;
  }

  @override
  Future<void> saveRestoredSyncSettingsText(String raw) async {
    restoredSyncSettingsText = raw;
  }

  @override
  Future<Map<String, Object?>> syncSettingsForBackup({
    required DateTime createdAt,
    required int protocolVersion,
  }) async {
    return {
      'schemaVersion': 2,
      'mode': 'local',
      'serverBackupEnabled': false,
      'incrementalSyncEnabled': false,
      'protocolVersion': protocolVersion,
      'identityMode': 'syncId',
      'serverEventCursor': cursor,
      'createdAt': createdAt.toIso8601String(),
      'secretsIncluded': false,
    };
  }
}

final class _FakeDiagnosticsServerSyncClient extends ServerSyncClient {
  _FakeDiagnosticsServerSyncClient({this.status, this.error});

  final ServerSyncStatus? status;
  final Object? error;
  var checkStatusCalls = 0;

  @override
  Future<ServerSyncStatus> checkStatus({
    required ServerBackupSettings settings,
    required int supportedProtocolVersion,
  }) async {
    checkStatusCalls += 1;
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return status ??
        ServerSyncStatus(
          available: true,
          serverVersion: 'test-server',
          protocolVersion: supportedProtocolVersion,
          identityMode: 'syncId',
          eventCount: 7,
          latestCursor: 9,
          latestBackupBytes: 128,
          latestBackupAt: DateTime(2026, 6, 2, 12),
          message: 'ok',
        );
  }
}

bool? _previousDontWarnAboutMultipleDatabases;

Future<void> _closeRegisteredBackupTestDatabases() async {
  if (locator.isRegistered<LocalTrainingDatabase>()) {
    await locator<LocalTrainingDatabase>().close();
    await locator.unregister<LocalTrainingDatabase>();
  }
  if (locator.isRegistered<CustomExerciseDatabase>()) {
    await locator<CustomExerciseDatabase>().close();
    await locator.unregister<CustomExerciseDatabase>();
  }
  await locator.reset();
}

final class _BackupArchiveTestDatabases {
  _BackupArchiveTestDatabases._({
    required this.trainingDb,
    required this.exerciseDb,
  });

  final LocalTrainingDatabase trainingDb;
  final CustomExerciseDatabase exerciseDb;

  static Future<_BackupArchiveTestDatabases> create(Directory docs) async {
    final databases = _BackupArchiveTestDatabases._(
      trainingDb: LocalTrainingDatabase.inMemory(
        NativeDatabase(File('${docs.path}/local_training.sqlite')),
      ),
      exerciseDb: CustomExerciseDatabase.inMemory(
        NativeDatabase(File('${docs.path}/custom_exercises.sqlite')),
      ),
    );
    await databases.trainingDb.customSelect('SELECT 1').get();
    await databases.exerciseDb.customSelect('SELECT 1').get();
    return databases;
  }

  Future<void> seedEndToEndData() async {
    final repository = LocalTrainingRepository(trainingDb);
    final plan = LocalTrainingPlanModel(name: '端到端备份计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '深蹲', targetSets: 3, targetReps: 5)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '深蹲',
      setIndex: 1,
      weight: 80,
      reps: 5,
      durationSeconds: 90,
      note: '端到端恢复校验',
    );
    await repository.finishSession(sessionId, note: '完成训练');

    await exerciseDb
        .into(exerciseDb.customExercises)
        .insert(
          CustomExercisesCompanion.insert(
            syncId: const Value('custom-e2e-sync-id'),
            chineseName: '端到端自定义动作',
            englishName: const Value('E2E Custom Exercise'),
            bodyPart: '腿',
            equipment: '杠铃',
            primaryMuscles: '股四头肌',
            description: '用于备份恢复验收',
            createdAt: DateTime(2026, 6, 18, 12),
            updatedAt: DateTime(2026, 6, 18, 12),
          ),
        );
  }

  Future<void> close() async {
    await trainingDb.close();
    await exerciseDb.close();
  }
}

Future<({Directory root, Directory docs, Directory temp})> _backupArchiveTestEnvironment(
  String prefix,
) async {
  final root = await Directory.systemTemp.createTemp(prefix);
  final docs = Directory('${root.path}/docs')..createSync(recursive: true);
  final temp = Directory('${root.path}/temp')..createSync(recursive: true);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
    return switch (call.method) {
      'getApplicationDocumentsDirectory' => docs.path,
      'getTemporaryDirectory' => temp.path,
      _ => null,
    };
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(pathProviderChannel, null),
  );
  addTearDown(() async {
    await _closeRegisteredBackupTestDatabases();
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });
  return (root: root, docs: docs, temp: temp);
}

Future<void> _createBackupDatabaseFiles(Directory docs) async {
  final databases = await _BackupArchiveTestDatabases.create(docs);
  await databases.close();
}

Future<void> _createBackupDatabaseFilesWithData(Directory docs) async {
  final databases = await _BackupArchiveTestDatabases.create(docs);
  try {
    await databases.seedEndToEndData();
  } finally {
    await databases.close();
  }
}

Future<void> _writeZip(
  File output, {
  bool includeManifest = true,
  bool includeTrainingDb = true,
  bool includeExerciseDb = true,
}) async {
  final encoder = ZipFileEncoder()..create(output.path);
  try {
    if (includeTrainingDb) {
      encoder.addArchiveFile(ArchiveFile.string('databases/local_training.sqlite', 'training'));
    }
    if (includeExerciseDb) {
      encoder.addArchiveFile(ArchiveFile.string('databases/custom_exercises.sqlite', 'exercise'));
    }
    if (includeManifest) {
      encoder.addArchiveFile(ArchiveFile.string('manifest.json', '{}'));
    }
  } finally {
    await encoder.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _previousDontWarnAboutMultipleDatabases = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    // These backup tests intentionally create seed file databases, then exercise
    // the production restore path that closes and reopens locator databases.
    // Keep the scope local to this test file so app lifecycle warnings remain visible elsewhere.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases =
        _previousDontWarnAboutMultipleDatabases ?? false;
  });

  test('server smart sync suggests initial restore only for empty local data', () async {
    await _closeRegisteredBackupTestDatabases();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await _closeRegisteredBackupTestDatabases();
    });

    final service = BackupService();
    const statusWithBackup = ServerSyncStatus(
      available: true,
      serverVersion: 'test',
      protocolVersion: 2,
      identityMode: 'syncId',
      eventCount: 0,
      latestCursor: 0,
      latestBackupBytes: 128,
      latestBackupAt: null,
      message: 'ok',
    );

    expect(await service.localTrainingDataIsEmptyForTest(), isTrue);
    final emptyDecision = await service.initialRestoreDecisionForTest(statusWithBackup);
    expect(emptyDecision?.state, ServerSmartSyncState.needsInitialRestore);

    final repository = LocalTrainingRepository(db);
    await repository.savePlan(LocalTrainingPlanModel(name: '本机已有计划'));

    expect(await service.localTrainingDataIsEmptyForTest(), isFalse);
    final nonEmptyDecision = await service.initialRestoreDecisionForTest(statusWithBackup);
    expect(nonEmptyDecision, isNull);
  });

  test('server sync device identity and cursor are not portable backup settings', () {
    final service = BackupService();

    expect(service.preferenceCanBeBackedUpForTest('yours_backup_server_base_url'), isTrue);
    expect(service.preferenceCanBeBackedUpForTest('yours_backup_server_api_token'), isFalse);
    expect(service.preferenceCanBeBackedUpForTest('yours_sync_device_id'), isFalse);
    expect(service.preferenceCanBeBackedUpForTest('yours_sync_event_cursor'), isFalse);
    expect(service.preferenceCanBeBackedUpForTest('yours_sync_device_id_v2'), isFalse);
    expect(service.preferenceCanBeBackedUpForTest('yours_sync_event_cursor_v2'), isFalse);
  });

  test(
    'backup diagnostics text includes local fields without calling unconfigured server',
    () async {
      final client = _FakeDiagnosticsServerSyncClient();
      final service = BackupDiagnosticsService(
        preferences: _FakeBackupPreferencesStore(cursor: 12),
        serverClient: client,
        supportedServerProtocolVersion: 2,
      );

      final text = await service.serverDiagnosticsText();

      expect(text, startsWith('Yours server sync diagnostics'));
      expect(text, contains('configured: false'));
      expect(text, contains('baseUrl: (empty)'));
      expect(text, contains('apiKeyConfigured: false'));
      expect(text, contains('serverTransportSecure: false'));
      expect(text, contains('deviceId: test-device'));
      expect(text, contains('localCursor: 12'));
      expect(text, contains('pendingEvents: 0'));
      expect(text, isNot(contains('serverAvailable:')));
      expect(client.checkStatusCalls, 0);
    },
  );

  test('backup diagnostics text includes server status and pending events', () async {
    await _closeRegisteredBackupTestDatabases();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await _closeRegisteredBackupTestDatabases();
    });
    final now = DateTime(2026, 6, 2, 12);
    await db
        .into(db.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: const Value('pending-event'),
            deviceId: const Value('test-device'),
            entityType: 'routine',
            entityId: 1,
            entitySyncId: const Value('routine:pending'),
            action: 'upsert',
            createdAt: now,
            updatedAt: now,
          ),
        );
    final client = _FakeDiagnosticsServerSyncClient(
      status: ServerSyncStatus(
        available: true,
        serverVersion: 'YoursBackupServer/0.2',
        protocolVersion: 2,
        identityMode: 'syncId',
        eventCount: 12,
        latestCursor: 34,
        latestBackupBytes: 52834,
        latestBackupAt: DateTime(2026, 6, 1, 21, 40, 36),
        message: 'ok',
      ),
    );
    final service = BackupDiagnosticsService(
      preferences: _FakeBackupPreferencesStore(
        settings: const ServerBackupSettings(
          baseUrl: 'https://sync.example',
          apiToken: 'token',
        ),
        cursor: 11,
      ),
      serverClient: client,
      supportedServerProtocolVersion: 2,
    );

    final text = await service.serverDiagnosticsText();

    expect(text, contains('configured: true'));
    expect(text, contains('baseUrl: https://sync.example'));
    expect(text, contains('apiKeyConfigured: true'));
    expect(text, contains('serverTransportSecure: true'));
    expect(text, contains('localCursor: 11'));
    expect(text, contains('pendingEvents: 1'));
    expect(text, contains('serverAvailable: true'));
    expect(text, contains('serverVersion: YoursBackupServer/0.2'));
    expect(text, contains('protocolVersion: 2'));
    expect(text, contains('identityMode: syncId'));
    expect(text, contains('serverLatestCursor: 34'));
    expect(text, contains('serverEventCount: 12'));
    expect(text, contains('latestBackupAt: 2026-06-01T21:40:36.000'));
    expect(text, contains('latestBackupBytes: 52834'));
    expect(text, contains('message: ok'));
    expect(client.checkStatusCalls, 1);
  });

  test('backup diagnostics text records server errors without failing copy text', () async {
    final service = BackupDiagnosticsService(
      preferences: _FakeBackupPreferencesStore(
        settings: const ServerBackupSettings(
          baseUrl: 'https://sync.example',
          apiToken: 'token',
        ),
      ),
      serverClient: _FakeDiagnosticsServerSyncClient(
        error: const YoursException(YoursErrorCode.serverUnreachable),
      ),
      supportedServerProtocolVersion: 2,
    );

    final text = await service.serverDiagnosticsText();

    expect(text, startsWith('Yours server sync diagnostics'));
    expect(text, contains('serverError:'));
    expect(text, contains('YoursException'));
  });

  test('backup diagnostics text redacts tokens from settings and errors', () async {
    const secret = 'secret-token-123';
    final service = BackupDiagnosticsService(
      preferences: _FakeBackupPreferencesStore(
        settings: const ServerBackupSettings(
          baseUrl: 'http://sync.example?token=secret-token-123&api_key=abc123',
          apiToken: secret,
        ),
        deviceIdFailure: StateError('device failed with Bearer device-secret'),
        cursorFailure: StateError('cursor failed token=cursor-secret'),
      ),
      serverClient: _FakeDiagnosticsServerSyncClient(
        error: StateError(
          'server failed Authorization: Bearer $secret api_key=query-secret token=plain-secret',
        ),
      ),
      supportedServerProtocolVersion: 2,
    );

    final text = await service.serverDiagnosticsText();

    expect(text, contains('configured: true'));
    expect(text, contains('apiKeyConfigured: true'));
    expect(text, contains('serverTransportSecure: false'));
    expect(text, contains('Bearer [redacted]'));
    expect(text, contains('token=[redacted]'));
    expect(text, contains('api_key=[redacted]'));
    expect(text, isNot(contains(secret)));
    expect(text, isNot(contains('device-secret')));
    expect(text, isNot(contains('cursor-secret')));
    expect(text, isNot(contains('query-secret')));
    expect(text, isNot(contains('plain-secret')));
    expect(text, isNot(contains('abc123')));
  });

  test('backup service diagnostics entry still returns diagnostics text', () async {
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previousPlatform);

    final text = await BackupService().serverDiagnosticsText();

    expect(text, startsWith('Yours server sync diagnostics'));
  });

  test('backup archive includes databases, settings, and non-secret manifest metadata', () async {
    final env = await _backupArchiveTestEnvironment('yours_backup_archive_create_');
    await _createBackupDatabaseFiles(env.docs);

    final service = BackupArchiveService(
      preferences: _FakeBackupPreferencesStore(cursor: 42),
      serverProtocolVersion: 2,
    );
    final output = File('${env.root.path}/yours-backup.zip');

    final result = await service.writeBackupFile(output);
    final archive = ZipDecoder().decodeBytes(await output.readAsBytes(), verify: true);
    final names = archive.files.where((file) => file.isFile).map((file) => file.name).toSet();
    final manifest = archive.findFile('manifest.json');
    final manifestJson =
        jsonDecode(utf8.decode(manifest!.readBytes() ?? const [])) as Map<String, dynamic>;
    final manifestContains = manifestJson['contains'] as Map<String, dynamic>;
    final appSettingsText = utf8.decode(
      archive.findFile('settings/app_settings.json')!.readBytes() ?? const [],
    );
    final syncSettingsText = utf8.decode(
      archive.findFile('settings/sync_settings.json')!.readBytes() ?? const [],
    );
    final syncSettings = jsonDecode(syncSettingsText) as Map<String, dynamic>;

    expect(result.file, output);
    expect(names, contains('manifest.json'));
    expect(names, contains('databases/local_training.sqlite'));
    expect(names, contains('databases/custom_exercises.sqlite'));
    expect(names, contains('settings/app_settings.json'));
    expect(names, contains('settings/sync_settings.json'));
    expect(manifestJson['format'], 'yours-backup');
    expect(manifestJson['formatVersion'], 1);
    expect(manifestContains['secrets'], isFalse);
    expect(appSettingsText, isNot(contains('token')));
    expect(appSettingsText, isNot(contains('device_id')));
    expect(appSettingsText, isNot(contains('cursor')));
    expect(syncSettings['secretsIncluded'], isFalse);
    expect(syncSettings['identityMode'], 'syncId');
    expect(syncSettings['serverEventCursor'], 42);
    expect(await service.serverCursorFromBackup(output), 42);
  });

  test('backup archive restore keeps validation errors and creates safety backup', () async {
    final env = await _backupArchiveTestEnvironment('yours_backup_archive_restore_');
    await _createBackupDatabaseFiles(env.docs);

    final preferences = _FakeBackupPreferencesStore();
    final service = BackupArchiveService(
      preferences: preferences,
      serverProtocolVersion: 2,
    );
    final validBackup = File('${env.root.path}/valid.zip');
    await service.writeBackupFile(validBackup);

    final missingManifest = File('${env.root.path}/missing_manifest.zip');
    await _writeZip(missingManifest, includeManifest: false);
    await expectLater(
      service.restoreBackup(missingManifest),
      throwsA(
        isA<YoursException>().having(
          (error) => error.code,
          'code',
          YoursErrorCode.backupManifestMissing,
        ),
      ),
    );

    final missingDatabase = File('${env.root.path}/missing_database.zip');
    await _writeZip(missingDatabase, includeExerciseDb: false);
    await expectLater(
      service.restoreBackup(missingDatabase),
      throwsA(
        isA<YoursException>().having(
          (error) => error.code,
          'code',
          YoursErrorCode.backupDatabaseMissing,
        ),
      ),
    );

    await File('${env.docs.path}/local_training.sqlite').delete();
    await File('${env.docs.path}/custom_exercises.sqlite').delete();
    final result = await service.restoreBackup(validBackup);

    expect(result.source, validBackup);
    expect(result.safetyBackup.existsSync(), isTrue);
    expect(result.restoredFileCount, greaterThanOrEqualTo(4));
    expect(File('${env.docs.path}/local_training.sqlite').existsSync(), isTrue);
    expect(File('${env.docs.path}/custom_exercises.sqlite').existsSync(), isTrue);
    expect(preferences.restoredAppSettingsText, isNot(equals(null)));
    expect(preferences.restoredSyncSettingsText, isNot(equals(null)));
  });

  test('backup archive restores real training custom exercise and settings data', () async {
    final env = await _backupArchiveTestEnvironment('yours_backup_archive_e2e_');
    await _createBackupDatabaseFilesWithData(env.docs);
    final preferences = _FakeBackupPreferencesStore(cursor: 77);
    final service = BackupArchiveService(
      preferences: preferences,
      serverProtocolVersion: 2,
    );
    final backup = File('${env.root.path}/full_e2e.zip');

    await service.writeBackupFile(backup);
    await File('${env.docs.path}/local_training.sqlite').delete();
    await File('${env.docs.path}/custom_exercises.sqlite').delete();

    final result = await service.restoreBackup(backup);
    final trainingDb = locator<LocalTrainingDatabase>();
    final exerciseDb = locator<CustomExerciseDatabase>();

    final routines = await trainingDb.select(trainingDb.localRoutines).get();
    final sessions = await trainingDb.select(trainingDb.localWorkoutSessions).get();
    final logs = await trainingDb.select(trainingDb.localWorkoutLogs).get();
    final exercises = await exerciseDb.select(exerciseDb.customExercises).get();

    expect(result.safetyBackup.existsSync(), isTrue);
    expect(routines.single.name, '端到端备份计划');
    expect(sessions.single.note, '完成训练');
    expect(logs.single.note, '端到端恢复校验');
    expect(exercises.single.chineseName, '端到端自定义动作');
    expect(preferences.restoredAppSettingsText, contains('schemaVersion'));
    expect(preferences.restoredSyncSettingsText, contains('"serverEventCursor": 77'));
  });
}

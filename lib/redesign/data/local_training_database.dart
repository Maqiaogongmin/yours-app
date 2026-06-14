import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:logging/logging.dart';

part 'local_training_database.g.dart';

class LocalRoutines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  IntColumn get totalWeeks => integer().withDefault(const Constant(4))();
  IntColumn get daysPerWeek => integer().withDefault(const Constant(4))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get completedWeeksJson => text().withDefault(const Constant('[]'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class LocalTrainingDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get routineId => integer().references(LocalRoutines, #id)();
  IntColumn get week => integer()();
  IntColumn get day => integer()();
  TextColumn get name => text()();
  TextColumn get actionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get updatedAt => dateTime()();
}

class LocalSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get dayId => integer().references(LocalTrainingDays, #id)();
  IntColumn get order => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class LocalSlotEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get slotId => integer().references(LocalSlots, #id)();
  TextColumn get exerciseName => text()();
  IntColumn get exerciseId => integer().nullable()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().nullable()();
  RealColumn get targetWeight => real().nullable()();
  TextColumn get recordMode => text().withDefault(const Constant('standard'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class LocalWorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get routineId => integer().references(LocalRoutines, #id)();
  IntColumn get dayId => integer().nullable().references(LocalTrainingDays, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get updatedAt => dateTime()();
}

class LocalWorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  IntColumn get sessionId => integer().references(LocalWorkoutSessions, #id)();
  IntColumn get routineId => integer().references(LocalRoutines, #id)();
  IntColumn get dayId => integer().nullable().references(LocalTrainingDays, #id)();
  TextColumn get exerciseName => text()();
  IntColumn get setIndex => integer()();
  RealColumn get weight => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get rir => real().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get recordMode => text().withDefault(const Constant('standard'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
}

class LocalSyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().withDefault(const Constant(''))();
  TextColumn get deviceId => text().withDefault(const Constant(''))();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer()();
  TextColumn get entitySyncId => text().withDefault(const Constant(''))();
  TextColumn get action => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get serverSeq => integer().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    LocalRoutines,
    LocalTrainingDays,
    LocalSlots,
    LocalSlotEntries,
    LocalWorkoutSessions,
    LocalWorkoutLogs,
    LocalSyncQueue,
  ],
)
class LocalTrainingDatabase extends _$LocalTrainingDatabase {
  final _logger = Logger('LocalTrainingDatabase');

  LocalTrainingDatabase() : super(_openConnection());

  LocalTrainingDatabase.inMemory(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (!await _hasTable('local_sync_queue')) {
          await migrator.createTable(localSyncQueue);
        }
        if (!await _hasColumn('local_slot_entries', 'target_weight')) {
          await migrator.addColumn(localSlotEntries, localSlotEntries.targetWeight);
        }
        if (!await _hasColumn('local_slot_entries', 'record_mode')) {
          await migrator.addColumn(localSlotEntries, localSlotEntries.recordMode);
        }
        if (!await _hasColumn('local_workout_logs', 'record_mode')) {
          await migrator.addColumn(localWorkoutLogs, localWorkoutLogs.recordMode);
        }
        if (!await _hasColumn('local_workout_sessions', 'note')) {
          await migrator.addColumn(localWorkoutSessions, localWorkoutSessions.note);
        }
        if (!await _hasColumn('local_workout_logs', 'note')) {
          await migrator.addColumn(localWorkoutLogs, localWorkoutLogs.note);
        }
        if (!await _hasColumn('local_routines', 'archived')) {
          await migrator.addColumn(localRoutines, localRoutines.archived);
        }
        if (!await _hasColumn('local_routines', 'completed_weeks_json')) {
          await migrator.addColumn(localRoutines, localRoutines.completedWeeksJson);
        }
        await _ensureSyncIdColumns(migrator);
        await _ensureQueueV2Columns(migrator);
        await _backfillSyncIds();
        await _backfillQueueV2Columns();
      },
    );
  }

  Future<void> _ensureSyncIdColumns(Migrator migrator) async {
    if (!await _hasColumn('local_routines', 'sync_id')) {
      await migrator.addColumn(localRoutines, localRoutines.syncId);
    }
    if (!await _hasColumn('local_training_days', 'sync_id')) {
      await migrator.addColumn(localTrainingDays, localTrainingDays.syncId);
    }
    if (!await _hasColumn('local_slots', 'sync_id')) {
      await migrator.addColumn(localSlots, localSlots.syncId);
    }
    if (!await _hasColumn('local_slot_entries', 'sync_id')) {
      await migrator.addColumn(localSlotEntries, localSlotEntries.syncId);
    }
    if (!await _hasColumn('local_workout_sessions', 'sync_id')) {
      await migrator.addColumn(localWorkoutSessions, localWorkoutSessions.syncId);
    }
    if (!await _hasColumn('local_workout_logs', 'sync_id')) {
      await migrator.addColumn(localWorkoutLogs, localWorkoutLogs.syncId);
    }
  }

  Future<void> _ensureQueueV2Columns(Migrator migrator) async {
    if (!await _hasColumn('local_sync_queue', 'event_id')) {
      await migrator.addColumn(localSyncQueue, localSyncQueue.eventId);
    }
    if (!await _hasColumn('local_sync_queue', 'device_id')) {
      await migrator.addColumn(localSyncQueue, localSyncQueue.deviceId);
    }
    if (!await _hasColumn('local_sync_queue', 'entity_sync_id')) {
      await migrator.addColumn(localSyncQueue, localSyncQueue.entitySyncId);
    }
    if (!await _hasColumn('local_sync_queue', 'server_seq')) {
      await migrator.addColumn(localSyncQueue, localSyncQueue.serverSeq);
    }
  }

  Future<void> _backfillSyncIds() async {
    await _backfillTableSyncIds('local_routines');
    await _backfillTableSyncIds('local_training_days');
    await _backfillTableSyncIds('local_slots');
    await _backfillTableSyncIds('local_slot_entries');
    await _backfillTableSyncIds('local_workout_sessions');
    await _backfillTableSyncIds('local_workout_logs');
  }

  Future<void> _backfillTableSyncIds(String tableName) async {
    await customStatement(
      "UPDATE $tableName SET sync_id = lower(hex(randomblob(4)) || '-' || "
      "hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || "
      "substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || "
      "hex(randomblob(6))) WHERE sync_id IS NULL OR sync_id = ''",
    );
  }

  Future<void> _backfillQueueV2Columns() async {
    await customStatement(
      "UPDATE local_sync_queue SET event_id = lower(hex(randomblob(4)) || '-' || "
      "hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || "
      "substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || "
      "hex(randomblob(6))) WHERE event_id IS NULL OR event_id = ''",
    );
    await customStatement(
      "UPDATE local_sync_queue SET device_id = 'legacy-' || lower(hex(randomblob(16))) "
      "WHERE device_id IS NULL OR device_id = ''",
    );
    await customStatement(
      '''UPDATE local_sync_queue SET entity_sync_id = entity_type || ':' || '''
      '''(SELECT sync_id FROM local_routines WHERE local_routines.id = local_sync_queue.entity_id) '''
      '''WHERE (entity_sync_id IS NULL OR entity_sync_id = '') '''
      '''AND entity_type = 'routine' '''
      '''AND EXISTS (SELECT 1 FROM local_routines WHERE local_routines.id = local_sync_queue.entity_id) ''',
    );
    await customStatement(
      '''UPDATE local_sync_queue SET entity_sync_id = entity_type || ':' || '''
      '''(SELECT sync_id FROM local_workout_sessions WHERE local_workout_sessions.id = local_sync_queue.entity_id) '''
      '''WHERE (entity_sync_id IS NULL OR entity_sync_id = '') '''
      '''AND entity_type = 'workout_session' '''
      '''AND EXISTS (SELECT 1 FROM local_workout_sessions WHERE local_workout_sessions.id = local_sync_queue.entity_id) ''',
    );
    await customStatement(
      '''UPDATE local_sync_queue SET entity_sync_id = entity_type || ':' || '''
      '''(SELECT sync_id FROM local_workout_logs WHERE local_workout_logs.id = local_sync_queue.entity_id) '''
      '''WHERE (entity_sync_id IS NULL OR entity_sync_id = '') '''
      '''AND entity_type = 'workout_log' '''
      '''AND EXISTS (SELECT 1 FROM local_workout_logs WHERE local_workout_logs.id = local_sync_queue.entity_id) ''',
    );
    await customStatement(
      "UPDATE local_sync_queue SET status = 'synced' "
      "WHERE entity_sync_id IS NULL OR entity_sync_id = ''",
    );
  }

  Future<bool> _hasTable(String tableName) async {
    final rows = await customSelect(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
      variables: [Variable.withString('table'), Variable.withString(tableName)],
      readsFrom: const {},
    ).get();
    return rows.isNotEmpty;
  }

  Future<bool> _hasColumn(String tableName, String columnName) async {
    final rows = await customSelect(
      'PRAGMA table_info($tableName)',
      readsFrom: const {},
    ).get();
    return rows.any((row) => row.data['name'] == columnName);
  }

  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        _logger.info('Deleting local training table ${table.actualTableName}');
        await delete(table).go();
      }
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'local_training');
}

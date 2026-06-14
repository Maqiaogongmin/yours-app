import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/redesign_data_refresh.dart';
import 'package:yours/redesign/data/sync_identity.dart';

class LocalSyncQueueRepository {
  final LocalTrainingDatabase database;

  const LocalSyncQueueRepository(this.database);

  Future<void> enqueue(
    String entityType,
    int entityId,
    String action, {
    String? entitySyncId,
    Map<String, Object?> payload = const {},
  }) async {
    final now = DateTime.now();
    final deviceId = await SyncIdentity.deviceId();
    final resolvedEntitySyncId = entitySyncId ?? await _resolveEntitySyncId(entityType, entityId);
    await database
        .into(database.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: Value(SyncId.newId()),
            deviceId: Value(deviceId),
            entityType: entityType,
            entityId: entityId,
            entitySyncId: Value(resolvedEntitySyncId),
            action: action,
            payload: Value(jsonEncode(payload)),
            status: const Value(localSyncPending),
            createdAt: now,
            updatedAt: now,
          ),
        );
    RedesignDataRefresh.instance.notifySyncQueueChanged();
  }

  Future<int> removePendingCreate(String entityType, int entityId) async {
    final deleted =
        await (database.delete(database.localSyncQueue)..where(
              (item) =>
                  item.entityType.equals(entityType) &
                  item.entityId.equals(entityId) &
                  item.action.equals('create') &
                  item.status.equals(localSyncPending),
            ))
            .go();
    RedesignDataRefresh.instance.notifySyncQueueChanged();
    return deleted;
  }

  Future<int> removePendingNonDelete(String entityType, int entityId) async {
    final deleted =
        await (database.delete(database.localSyncQueue)..where(
              (item) =>
                  item.entityType.equals(entityType) &
                  item.entityId.equals(entityId) &
                  item.action.equals('delete').not() &
                  _needsSync(item),
            ))
            .go();
    RedesignDataRefresh.instance.notifySyncQueueChanged();
    return deleted;
  }

  Future<int> pendingCount() {
    return (database.select(
      database.localSyncQueue,
    )..where(_needsSync)).get().then((items) => items.length);
  }

  Future<List<LocalSyncQueueData>> pendingItems({int limit = 100}) {
    return (database.select(database.localSyncQueue)
          ..where(_needsSync)
          ..orderBy([(item) => OrderingTerm.asc(item.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (database.update(
      database.localSyncQueue,
    )..where((item) => item.id.isIn(ids))).write(
      LocalSyncQueueCompanion(
        status: const Value(localSyncSynced),
        updatedAt: Value(DateTime.now()),
      ),
    );
    RedesignDataRefresh.instance.notifySyncQueueChanged();
  }

  Future<void> markFailed(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (database.update(
      database.localSyncQueue,
    )..where((item) => item.id.isIn(ids))).write(
      LocalSyncQueueCompanion(
        status: const Value(localSyncFailed),
        attempts: const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    for (final id in ids) {
      await database.customStatement(
        'UPDATE local_sync_queue SET attempts = attempts + 1 WHERE id = ?',
        [id],
      );
    }
    RedesignDataRefresh.instance.notifySyncQueueChanged();
  }

  Future<DateTime?> latestPendingChangeAt() async {
    final items =
        await (database.select(database.localSyncQueue)
              ..where(_needsSync)
              ..orderBy([(item) => OrderingTerm.desc(item.updatedAt)])
              ..limit(1))
            .get();
    return items.isEmpty ? null : items.first.updatedAt;
  }

  Expression<bool> _needsSync(LocalSyncQueue item) {
    return item.status.equals(localSyncPending) | item.status.equals(localSyncFailed);
  }

  Future<String> _resolveEntitySyncId(String entityType, int entityId) async {
    final syncId = switch (entityType) {
      'routine' => await _routineSyncId(entityId),
      'workout_session' => await _sessionSyncId(entityId),
      'workout_log' => await _logSyncId(entityId),
      _ => null,
    };
    if (syncId != null && syncId.trim().isNotEmpty) {
      return '$entityType:$syncId';
    }
    return '$entityType:$entityId';
  }

  Future<String?> _routineSyncId(int id) async {
    final row = await (database.select(
      database.localRoutines,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> _sessionSyncId(int id) async {
    final row = await (database.select(
      database.localWorkoutSessions,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> _logSyncId(int id) async {
    final row = await (database.select(
      database.localWorkoutLogs,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }
}

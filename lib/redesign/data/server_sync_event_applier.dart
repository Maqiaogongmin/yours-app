import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/sync_identity.dart';

part 'server_sync_event_applier/routine_event_handler.dart';
part 'server_sync_event_applier/session_event_handler.dart';
part 'server_sync_event_applier/workout_log_event_handler.dart';
part 'server_sync_event_applier/custom_exercise_event_handler.dart';

class ServerSyncEventApplier {
  // Coordinates remote event dispatch while entity-specific rules live in part files.
  const ServerSyncEventApplier({required BackupPreferencesStore preferences})
    : _preferences = preferences;

  final BackupPreferencesStore _preferences;

  Future<bool> applyRemoteEvent(Map<String, dynamic> event) async {
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
            deviceId: Value(await _preferences.deviceId()),
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
}

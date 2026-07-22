import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';

class ServerSyncSnapshotBuilder {
  const ServerSyncSnapshotBuilder();

  Future<Map<String, Object?>?> buildLocalEvent(
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
    final snapshot = await snapshotFor(item);
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

  Future<Map<String, Object?>?> snapshotFor(LocalSyncQueueData item) async {
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
        if (actions[slot.order]['targetDurationSeconds'] != null)
          'targetDurationSeconds': actions[slot.order]['targetDurationSeconds'],
        if (actions[slot.order]['targetRestSeconds'] != null)
          'targetRestSeconds': actions[slot.order]['targetRestSeconds'],
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
      'routineNameSnapshot': session.routineNameSnapshot,
      'routineSyncIdSnapshot': session.routineSyncIdSnapshot,
      'dayNameSnapshot': session.dayNameSnapshot,
      'dayWeekSnapshot': session.dayWeekSnapshot,
      'dayIndexSnapshot': session.dayIndexSnapshot,
      'daySyncIdSnapshot': session.daySyncIdSnapshot,
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
      if (log.hasActualValues) 'hasActualValues': true,
      if (log.actualWeight != null) 'actualWeight': log.actualWeight,
      if (log.actualReps != null) 'actualReps': log.actualReps,
      if (log.actualDurationSeconds != null) 'actualDurationSeconds': log.actualDurationSeconds,
      if (log.restSeconds != null) 'restSeconds': log.restSeconds,
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
}

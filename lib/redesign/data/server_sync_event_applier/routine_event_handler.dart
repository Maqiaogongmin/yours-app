part of '../server_sync_event_applier.dart';

extension _RoutineServerSyncEventApplier on ServerSyncEventApplier {
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
}

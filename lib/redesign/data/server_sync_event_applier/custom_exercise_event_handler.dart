part of '../server_sync_event_applier.dart';

extension _CustomExerciseServerSyncEventApplier on ServerSyncEventApplier {
  Future<bool> _applyRemoteCustomExerciseEvent(
    String action,
    String? syncId,
    int? id,
    Map<String, dynamic>? snapshot,
  ) async {
    if (!locator.isRegistered<CustomExerciseDatabase>()) {
      return false;
    }
    final db = locator<CustomExerciseDatabase>();
    if (syncId == null || syncId.trim().isEmpty) {
      return true;
    }
    final exerciseId = await _localCustomExerciseIdBySyncId(db, syncId);
    if (action == 'delete' || snapshot?['deleted'] == true) {
      await _recordDeleteTombstone(
        entityType: 'custom_exercise',
        entitySyncId: 'custom_exercise:$syncId',
        entityId: exerciseId ?? id,
        updatedAt: _date(snapshot?['updatedAt']),
      );
      if (exerciseId == null) {
        return true;
      }
      await (db.update(db.customExercises)..where((row) => row.id.equals(exerciseId))).write(
        CustomExercisesCompanion(
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
    if (await _deleteTombstoneIsNotOlder('custom_exercise:$syncId', remoteUpdatedAt)) {
      return true;
    }
    if (exerciseId != null && await _localCustomExerciseIsNewer(db, exerciseId, remoteUpdatedAt)) {
      return true;
    }
    if (exerciseId == null) {
      await db
          .into(db.customExercises)
          .insert(
            CustomExercisesCompanion.insert(
              syncId: Value(syncId),
              remoteId: Value(_asInt(snapshot['remoteId'])),
              chineseName: _asString(snapshot['chineseName'], fallback: '同步动作'),
              englishName: Value(_asString(snapshot['englishName'])),
              bodyPart: _asString(snapshot['bodyPart']),
              equipment: _asString(snapshot['equipment']),
              primaryMuscles: _asString(snapshot['primaryMuscles']),
              description: _asString(snapshot['description']),
              imagePathsJson: Value(jsonEncode(_asList(snapshot['imagePaths']))),
              isCustom: Value(_asBool(snapshot['isCustom']) ?? true),
              syncStatus: const Value(localSyncSynced),
              deleted: Value(_asBool(snapshot['deleted']) ?? false),
              createdAt: _date(snapshot['createdAt']) ?? now,
              updatedAt: remoteUpdatedAt,
            ),
          );
      return true;
    }
    await (db.update(db.customExercises)..where((row) => row.id.equals(exerciseId))).write(
      CustomExercisesCompanion(
        syncId: Value(syncId),
        remoteId: Value(_asInt(snapshot['remoteId'])),
        chineseName: Value(_asString(snapshot['chineseName'], fallback: '同步动作')),
        englishName: Value(_asString(snapshot['englishName'])),
        bodyPart: Value(_asString(snapshot['bodyPart'])),
        equipment: Value(_asString(snapshot['equipment'])),
        primaryMuscles: Value(_asString(snapshot['primaryMuscles'])),
        description: Value(_asString(snapshot['description'])),
        imagePathsJson: Value(jsonEncode(_asList(snapshot['imagePaths']))),
        isCustom: Value(_asBool(snapshot['isCustom']) ?? true),
        syncStatus: const Value(localSyncSynced),
        deleted: Value(_asBool(snapshot['deleted']) ?? false),
        updatedAt: Value(remoteUpdatedAt),
      ),
    );
    return true;
  }
}

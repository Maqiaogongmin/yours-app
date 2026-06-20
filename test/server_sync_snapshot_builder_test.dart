import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/server_sync_snapshot_builder.dart';

void main() {
  test('server sync snapshot builder creates complete local event snapshots', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '快照构造测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '深蹲',
          targetSets: 3,
          targetReps: 5,
          recordMode: localRecordModeFree,
        ),
      ],
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
    );

    const builder = ServerSyncSnapshotBuilder();
    final queue = await db.select(db.localSyncQueue).get();
    final routineItem = queue.singleWhere((item) => item.entityType == 'routine');
    final sessionItem = queue.singleWhere((item) => item.entityType == 'workout_session');
    final logItem = queue.singleWhere((item) => item.entityType == 'workout_log');

    final routineEvent = await builder.buildLocalEvent(routineItem, deviceId: 'test-device');
    final routineSnapshot = routineEvent!['snapshot'] as Map<String, Object?>;
    final days = routineSnapshot['days'] as List<Object?>;
    final firstDay = days.single as Map<String, Object?>;
    final actions = firstDay['actions'] as List<Object?>;
    expect(routineEvent['entitySyncId'], 'routine:${savedPlan.syncId}');
    expect(routineSnapshot['syncId'], savedPlan.syncId);
    expect(firstDay['syncId'], day.syncId);
    expect(actions.single, containsPair('recordMode', localRecordModeFree));

    final sessionEvent = await builder.buildLocalEvent(sessionItem, deviceId: 'test-device');
    final sessionSnapshot = sessionEvent!['snapshot'] as Map<String, Object?>;
    final sessionLogs = sessionSnapshot['logs'] as List<Object?>;
    expect(sessionSnapshot['routineSyncId'], savedPlan.syncId);
    expect(sessionSnapshot['daySyncId'], day.syncId);
    expect(sessionLogs, hasLength(1));

    final log = (await db.select(db.localWorkoutLogs).get()).single;
    final logEvent = await builder.buildLocalEvent(logItem, deviceId: 'test-device');
    final logSnapshot = logEvent!['snapshot'] as Map<String, Object?>;
    expect(logEvent['entitySyncId'], 'workout_log:${log.syncId}');
    expect(logSnapshot['sessionSyncId'], sessionSnapshot['syncId']);
    expect(logSnapshot['routineSyncId'], savedPlan.syncId);
    expect(logSnapshot['exerciseName'], isNotEmpty);
  });

  test('server sync snapshot builder handles custom exercises and obsolete queue items', () async {
    await locator.reset();
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    locator
      ..registerSingleton<LocalTrainingDatabase>(trainingDb)
      ..registerSingleton<CustomExerciseDatabase>(exerciseDb);
    addTearDown(() async {
      await locator.reset();
      await trainingDb.close();
      await exerciseDb.close();
    });
    final now = DateTime(2026, 6, 2, 12);
    final exerciseId = await exerciseDb
        .into(exerciseDb.customExercises)
        .insert(
          CustomExercisesCompanion.insert(
            syncId: const Value('custom-sync-id'),
            chineseName: '自定义深蹲',
            englishName: const Value('Custom Squat'),
            bodyPart: '腿',
            equipment: '杠铃',
            primaryMuscles: '股四头肌',
            description: '自定义动作说明',
            imagePathsJson: Value(jsonEncode(['a.png', 'b.png'])),
            isCustom: const Value(true),
            deleted: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await trainingDb
        .into(trainingDb.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: const Value('custom-event'),
            deviceId: const Value('local-device'),
            entityType: 'custom_exercise',
            entityId: exerciseId,
            entitySyncId: const Value('custom_exercise:custom-sync-id'),
            action: 'upsert',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await trainingDb
        .into(trainingDb.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: const Value('delete-event'),
            deviceId: const Value('local-device'),
            entityType: 'workout_log',
            entityId: 404,
            entitySyncId: const Value('workout_log:deleted-sync-id'),
            action: 'delete',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await trainingDb
        .into(trainingDb.localSyncQueue)
        .insert(
          LocalSyncQueueCompanion.insert(
            eventId: const Value('missing-event'),
            deviceId: const Value('local-device'),
            entityType: 'workout_log',
            entityId: 405,
            entitySyncId: const Value('workout_log:missing-sync-id'),
            action: 'upsert',
            createdAt: now,
            updatedAt: now,
          ),
        );

    const builder = ServerSyncSnapshotBuilder();
    final queue = await trainingDb.select(trainingDb.localSyncQueue).get();
    final customItem = queue.singleWhere((item) => item.eventId == 'custom-event');
    final deleteItem = queue.singleWhere((item) => item.eventId == 'delete-event');
    final missingItem = queue.singleWhere((item) => item.eventId == 'missing-event');

    final customEvent = await builder.buildLocalEvent(customItem, deviceId: 'fallback-device');
    final customSnapshot = customEvent!['snapshot'] as Map<String, Object?>;
    expect(customEvent['entitySyncId'], 'custom_exercise:custom-sync-id');
    expect(customSnapshot['syncId'], 'custom-sync-id');
    expect(customSnapshot['chineseName'], '自定义深蹲');
    expect(customSnapshot['englishName'], 'Custom Squat');
    expect(customSnapshot['bodyPart'], '腿');
    expect(customSnapshot['equipment'], '杠铃');
    expect(customSnapshot['primaryMuscles'], '股四头肌');
    expect(customSnapshot['imagePaths'], ['a.png', 'b.png']);
    expect(customSnapshot['deleted'], isFalse);
    expect(customSnapshot['createdAt'], now.toIso8601String());
    expect(customSnapshot['updatedAt'], now.toIso8601String());

    final deleteEvent = await builder.buildLocalEvent(deleteItem, deviceId: 'fallback-device');
    expect(deleteEvent!['snapshot'], isNull);
    expect(deleteEvent['action'], 'delete');

    expect(await builder.buildLocalEvent(missingItem, deviceId: 'fallback-device'), isNull);
  });
}

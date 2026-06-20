import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/server_sync_event_applier.dart';

void main() {
  test('remote delete tombstones prevent older session updates from reviving data', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '删除墓碑测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '深蹲')],
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
    final session = (await db.select(db.localWorkoutSessions).get()).single;
    final service = BackupService();
    final deletedAt = DateTime(2026, 6, 2, 12);

    final deleted = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entityId': sessionId,
      'entitySyncId': 'workout_session:${session.syncId}',
      'action': 'delete',
      'snapshot': {
        'syncId': session.syncId,
        'updatedAt': deletedAt.toIso8601String(),
      },
    });
    expect(deleted, isTrue);
    expect(await db.select(db.localWorkoutSessions).get(), isEmpty);
    expect(await db.select(db.localWorkoutLogs).get(), isEmpty);

    final oldUpdate = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entityId': sessionId,
      'entitySyncId': 'workout_session:${session.syncId}',
      'action': 'upsert',
      'snapshot': {
        'syncId': session.syncId,
        'routineSyncId': savedPlan.syncId,
        'daySyncId': day.syncId,
        'startedAt': DateTime(2026, 6, 2, 10).toIso8601String(),
        'endedAt': DateTime(2026, 6, 2, 10, 30).toIso8601String(),
        'note': '旧更新不应复活',
        'updatedAt': DateTime(2026, 6, 2, 11).toIso8601String(),
        'logs': <Object?>[],
      },
    });
    expect(oldUpdate, isTrue);
    expect(await db.select(db.localWorkoutSessions).get(), isEmpty);
    final tombstone =
        (await (db.select(db.localSyncQueue)..where(
                  (item) =>
                      item.entitySyncId.equals('workout_session:${session.syncId}') &
                      item.action.equals('delete') &
                      item.status.equals(localSyncSynced),
                ))
                .get())
            .single;
    expect(tombstone.updatedAt, deletedAt);
  });

  test('server sync event applier handles remote v2 upsert and delete tombstones', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final applier = ServerSyncEventApplier(preferences: BackupPreferencesStore());
    const routineSyncId = 'direct-routine-sync-id';
    const daySyncId = 'direct-day-sync-id';
    const sessionSyncId = 'direct-session-sync-id';
    const logSyncId = 'direct-log-sync-id';
    final updatedAt = DateTime(2026, 6, 2, 12);

    final routineApplied = await applier.applyRemoteEvent({
      'entityType': 'routine',
      'entityId': 99,
      'entitySyncId': 'routine:$routineSyncId',
      'action': 'create',
      'snapshot': {
        'id': 99,
        'syncId': routineSyncId,
        'name': '直测远端计划',
        'totalWeeks': 1,
        'daysPerWeek': 1,
        'archived': false,
        'completedWeeks': <Object?>[],
        'deleted': false,
        'createdAt': updatedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'days': [
          {
            'id': 199,
            'syncId': daySyncId,
            'week': 1,
            'day': 1,
            'name': 'D1',
            'actions': [
              {
                'name': '深蹲',
                'targetSets': 3,
                'targetReps': 5,
                'slotSyncId': 'direct-slot-sync-id',
                'syncId': 'direct-slot-entry-sync-id',
              },
            ],
          },
        ],
      },
    });
    expect(routineApplied, isTrue);
    final routine = (await db.select(db.localRoutines).get()).single;
    final day = (await db.select(db.localTrainingDays).get()).single;
    expect(routine.syncId, routineSyncId);
    expect(routine.id, isNot(99));
    expect(day.syncId, daySyncId);

    final sessionApplied = await applier.applyRemoteEvent({
      'entityType': 'workout_session',
      'entityId': 299,
      'entitySyncId': 'workout_session:$sessionSyncId',
      'action': 'create',
      'snapshot': {
        'id': 299,
        'syncId': sessionSyncId,
        'routineSyncId': routineSyncId,
        'daySyncId': daySyncId,
        'startedAt': updatedAt.toIso8601String(),
        'endedAt': updatedAt.add(const Duration(minutes: 30)).toIso8601String(),
        'note': '直测远端训练',
        'updatedAt': updatedAt.toIso8601String(),
        'logs': [
          {
            'id': 399,
            'syncId': logSyncId,
            'sessionSyncId': sessionSyncId,
            'routineSyncId': routineSyncId,
            'daySyncId': daySyncId,
            'exerciseName': '深蹲',
            'setIndex': 1,
            'weight': 80.0,
            'reps': 5,
            'durationSeconds': 90,
            'createdAt': updatedAt.toIso8601String(),
          },
        ],
      },
    });
    expect(sessionApplied, isTrue);
    final session = (await db.select(db.localWorkoutSessions).get()).single;
    final log = (await db.select(db.localWorkoutLogs).get()).single;
    expect(session.syncId, sessionSyncId);
    expect(session.id, isNot(299));
    expect(log.syncId, logSyncId);
    expect(log.sessionId, session.id);

    final deleted = await applier.applyRemoteEvent({
      'entityType': 'workout_session',
      'entityId': 299,
      'entitySyncId': 'workout_session:$sessionSyncId',
      'action': 'delete',
      'snapshot': {
        'syncId': sessionSyncId,
        'updatedAt': updatedAt.add(const Duration(minutes: 5)).toIso8601String(),
      },
    });
    expect(deleted, isTrue);
    expect(await db.select(db.localWorkoutSessions).get(), isEmpty);
    expect(await db.select(db.localWorkoutLogs).get(), isEmpty);
    final tombstone =
        (await (db.select(db.localSyncQueue)..where(
                  (item) =>
                      item.entitySyncId.equals('workout_session:$sessionSyncId') &
                      item.action.equals('delete') &
                      item.status.equals(localSyncSynced),
                ))
                .get())
            .single;
    expect(tombstone.entitySyncId, 'workout_session:$sessionSyncId');
  });

  test(
    'server sync event applier does not overwrite newer local routine session or exercise',
    () async {
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
      final repository = LocalTrainingRepository(trainingDb);
      final applier = ServerSyncEventApplier(preferences: BackupPreferencesStore());
      final remoteTime = DateTime(2026, 6, 2, 12);
      final localTime = remoteTime.add(const Duration(hours: 1));

      final plan = LocalTrainingPlanModel(name: '本地较新计划', totalWeeks: 1, daysPerWeek: 1)
        ..days['1-1'] = LocalTrainingDayModel(
          week: 1,
          day: 1,
          name: 'D1',
          actions: [LocalTrainingActionModel(name: '深蹲')],
        );
      await repository.savePlan(plan);
      final savedPlan = (await repository.getPlans()).single;
      final day = savedPlan.days.values.single;
      final sessionId = await repository.startSession(savedPlan, day);
      await (trainingDb.update(
        trainingDb.localRoutines,
      )..where((row) => row.id.equals(savedPlan.id!))).write(
        LocalRoutinesCompanion(
          name: const Value('本地保留计划'),
          updatedAt: Value(localTime),
        ),
      );
      await (trainingDb.update(
        trainingDb.localWorkoutSessions,
      )..where((row) => row.id.equals(sessionId))).write(
        LocalWorkoutSessionsCompanion(
          note: const Value('本地保留训练备注'),
          updatedAt: Value(localTime),
        ),
      );
      final exerciseId = await exerciseDb
          .into(exerciseDb.customExercises)
          .insert(
            CustomExercisesCompanion.insert(
              syncId: const Value('local-newer-exercise-sync-id'),
              chineseName: '本地保留动作',
              englishName: const Value('Local Exercise'),
              bodyPart: '腿',
              equipment: '杠铃',
              primaryMuscles: '股四头肌',
              description: '本地说明',
              createdAt: remoteTime,
              updatedAt: localTime,
            ),
          );

      expect(
        await applier.applyRemoteEvent({
          'entityType': 'routine',
          'entitySyncId': 'routine:${savedPlan.syncId}',
          'action': 'update',
          'snapshot': {
            'syncId': savedPlan.syncId,
            'name': '远端旧计划',
            'totalWeeks': 4,
            'daysPerWeek': 4,
            'updatedAt': remoteTime.toIso8601String(),
            'days': <Object?>[],
          },
        }),
        isTrue,
      );
      expect(
        await applier.applyRemoteEvent({
          'entityType': 'workout_session',
          'entitySyncId':
              'workout_session:${(await trainingDb.select(trainingDb.localWorkoutSessions).get()).single.syncId}',
          'action': 'update',
          'snapshot': {
            'syncId':
                (await trainingDb.select(trainingDb.localWorkoutSessions).get()).single.syncId,
            'routineSyncId': savedPlan.syncId,
            'daySyncId': day.syncId,
            'startedAt': DateTime(2026, 6, 2, 10).toIso8601String(),
            'note': '远端旧训练备注',
            'updatedAt': remoteTime.toIso8601String(),
            'logs': <Object?>[],
          },
        }),
        isTrue,
      );
      expect(
        await applier.applyRemoteEvent({
          'entityType': 'custom_exercise',
          'entitySyncId': 'custom_exercise:local-newer-exercise-sync-id',
          'action': 'update',
          'snapshot': {
            'syncId': 'local-newer-exercise-sync-id',
            'chineseName': '远端旧动作',
            'englishName': 'Remote Exercise',
            'bodyPart': '胸',
            'equipment': '哑铃',
            'primaryMuscles': '胸大肌',
            'description': '远端旧说明',
            'updatedAt': remoteTime.toIso8601String(),
          },
        }),
        isTrue,
      );

      final routine = (await trainingDb.select(trainingDb.localRoutines).get()).single;
      final session = (await trainingDb.select(trainingDb.localWorkoutSessions).get()).single;
      final exercise = await (exerciseDb.select(
        exerciseDb.customExercises,
      )..where((row) => row.id.equals(exerciseId))).getSingle();
      expect(routine.name, '本地保留计划');
      expect(session.note, '本地保留训练备注');
      expect(exercise.chineseName, '本地保留动作');
    },
  );

  test(
    'server sync event applier keeps session logs unless remote snapshot includes logs',
    () async {
      await locator.reset();
      final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
      locator.registerSingleton<LocalTrainingDatabase>(db);
      addTearDown(() async {
        await locator.reset();
        await db.close();
      });
      final applier = ServerSyncEventApplier(preferences: BackupPreferencesStore());
      const routineSyncId = 'session-logs-routine-sync-id';
      const daySyncId = 'session-logs-day-sync-id';
      const sessionSyncId = 'session-logs-session-sync-id';
      const logSyncId = 'session-logs-log-sync-id';
      final createdAt = DateTime(2026, 6, 2, 12);

      await applier.applyRemoteEvent({
        'entityType': 'routine',
        'entitySyncId': 'routine:$routineSyncId',
        'action': 'create',
        'snapshot': {
          'syncId': routineSyncId,
          'name': '日志收敛计划',
          'totalWeeks': 1,
          'daysPerWeek': 1,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': createdAt.toIso8601String(),
          'days': [
            {'syncId': daySyncId, 'week': 1, 'day': 1, 'name': 'D1', 'actions': <Object?>[]},
          ],
        },
      });
      await applier.applyRemoteEvent({
        'entityType': 'workout_session',
        'entitySyncId': 'workout_session:$sessionSyncId',
        'action': 'create',
        'snapshot': {
          'syncId': sessionSyncId,
          'routineSyncId': routineSyncId,
          'daySyncId': daySyncId,
          'startedAt': createdAt.toIso8601String(),
          'updatedAt': createdAt.toIso8601String(),
          'logs': [
            {
              'syncId': logSyncId,
              'sessionSyncId': sessionSyncId,
              'routineSyncId': routineSyncId,
              'daySyncId': daySyncId,
              'exerciseName': '深蹲',
              'setIndex': 1,
              'weight': 80.0,
              'reps': 5,
              'durationSeconds': 90,
              'createdAt': createdAt.toIso8601String(),
            },
          ],
        },
      });
      expect(await db.select(db.localWorkoutLogs).get(), hasLength(1));

      await applier.applyRemoteEvent({
        'entityType': 'workout_session',
        'entitySyncId': 'workout_session:$sessionSyncId',
        'action': 'update',
        'snapshot': {
          'syncId': sessionSyncId,
          'routineSyncId': routineSyncId,
          'daySyncId': daySyncId,
          'startedAt': createdAt.toIso8601String(),
          'note': '缺 logs 的局部更新',
          'updatedAt': createdAt.add(const Duration(minutes: 1)).toIso8601String(),
        },
      });
      expect(await db.select(db.localWorkoutLogs).get(), hasLength(1));

      await applier.applyRemoteEvent({
        'entityType': 'workout_session',
        'entitySyncId': 'workout_session:$sessionSyncId',
        'action': 'update',
        'snapshot': {
          'syncId': sessionSyncId,
          'routineSyncId': routineSyncId,
          'daySyncId': daySyncId,
          'startedAt': createdAt.toIso8601String(),
          'note': '带空 logs 的完整更新',
          'updatedAt': createdAt.add(const Duration(minutes: 2)).toIso8601String(),
          'logs': <Object?>[],
        },
      });
      expect(await db.select(db.localWorkoutLogs).get(), isEmpty);
    },
  );

  test('server sync event applier prevents older workout log updates after delete', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });
    final applier = ServerSyncEventApplier(preferences: BackupPreferencesStore());
    const routineSyncId = 'log-delete-routine-sync-id';
    const sessionSyncId = 'log-delete-session-sync-id';
    const logSyncId = 'log-delete-log-sync-id';
    final createdAt = DateTime(2026, 6, 2, 12);
    final deletedAt = createdAt.add(const Duration(minutes: 5));

    await applier.applyRemoteEvent({
      'entityType': 'workout_log',
      'entitySyncId': 'workout_log:$logSyncId',
      'action': 'create',
      'snapshot': {
        'syncId': logSyncId,
        'sessionSyncId': sessionSyncId,
        'routineSyncId': routineSyncId,
        'exerciseName': '深蹲',
        'setIndex': 1,
        'weight': 80.0,
        'reps': 5,
        'durationSeconds': 90,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': createdAt.toIso8601String(),
      },
    });
    expect(await db.select(db.localWorkoutLogs).get(), hasLength(1));

    await applier.applyRemoteEvent({
      'entityType': 'workout_log',
      'entitySyncId': 'workout_log:$logSyncId',
      'action': 'delete',
      'snapshot': {
        'syncId': logSyncId,
        'updatedAt': deletedAt.toIso8601String(),
      },
    });
    expect(await db.select(db.localWorkoutLogs).get(), isEmpty);

    await applier.applyRemoteEvent({
      'entityType': 'workout_log',
      'entitySyncId': 'workout_log:$logSyncId',
      'action': 'update',
      'snapshot': {
        'syncId': logSyncId,
        'sessionSyncId': sessionSyncId,
        'routineSyncId': routineSyncId,
        'exerciseName': '深蹲',
        'setIndex': 1,
        'weight': 90.0,
        'reps': 3,
        'durationSeconds': 100,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': deletedAt.subtract(const Duration(minutes: 1)).toIso8601String(),
      },
    });
    expect(await db.select(db.localWorkoutLogs).get(), isEmpty);
  });

  test(
    'server sync event applier handles custom exercise updates deletes and tombstones',
    () async {
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
      final applier = ServerSyncEventApplier(preferences: BackupPreferencesStore());
      const syncId = 'remote-custom-exercise-sync-id';
      final createdAt = DateTime(2026, 6, 2, 12);

      await applier.applyRemoteEvent({
        'entityType': 'custom_exercise',
        'entityId': 200,
        'entitySyncId': 'custom_exercise:$syncId',
        'action': 'create',
        'snapshot': {
          'syncId': syncId,
          'remoteId': 200,
          'chineseName': '远端动作',
          'englishName': 'Remote Move',
          'bodyPart': '背',
          'equipment': '绳索',
          'primaryMuscles': '背阔肌',
          'description': '远端说明',
          'imagePaths': ['remote-a.png'],
          'isCustom': true,
          'deleted': false,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': createdAt.toIso8601String(),
        },
      });
      var exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
      expect(exercise.syncId, syncId);
      expect(exercise.id, isNot(200));
      expect(exercise.imagePathsJson, jsonEncode(['remote-a.png']));

      await applier.applyRemoteEvent({
        'entityType': 'custom_exercise',
        'entitySyncId': 'custom_exercise:$syncId',
        'action': 'update',
        'snapshot': {
          'syncId': syncId,
          'chineseName': '远端动作新版',
          'englishName': 'Remote Move New',
          'bodyPart': '肩',
          'equipment': '哑铃',
          'primaryMuscles': '三角肌',
          'description': '新版说明',
          'imagePaths': ['remote-b.png'],
          'isCustom': true,
          'deleted': false,
          'updatedAt': createdAt.add(const Duration(minutes: 1)).toIso8601String(),
        },
      });
      exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
      expect(exercise.chineseName, '远端动作新版');
      expect(exercise.bodyPart, '肩');
      expect(exercise.imagePathsJson, jsonEncode(['remote-b.png']));

      await applier.applyRemoteEvent({
        'entityType': 'custom_exercise',
        'entityId': 200,
        'entitySyncId': 'custom_exercise:$syncId',
        'action': 'delete',
        'snapshot': {
          'syncId': syncId,
          'updatedAt': createdAt.add(const Duration(minutes: 2)).toIso8601String(),
        },
      });
      exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
      expect(exercise.deleted, isTrue);
      final tombstone =
          (await (trainingDb.select(trainingDb.localSyncQueue)..where(
                    (item) =>
                        item.entitySyncId.equals('custom_exercise:$syncId') &
                        item.action.equals('delete') &
                        item.status.equals(localSyncSynced),
                  ))
                  .get())
              .single;
      expect(tombstone.entitySyncId, 'custom_exercise:$syncId');

      await applier.applyRemoteEvent({
        'entityType': 'custom_exercise',
        'entitySyncId': 'custom_exercise:$syncId',
        'action': 'update',
        'snapshot': {
          'syncId': syncId,
          'chineseName': '旧更新不应复活',
          'englishName': 'Old Remote Move',
          'bodyPart': '胸',
          'equipment': '器械',
          'primaryMuscles': '胸大肌',
          'description': '旧说明',
          'imagePaths': <Object?>[],
          'isCustom': true,
          'deleted': false,
          'updatedAt': createdAt.add(const Duration(seconds: 30)).toIso8601String(),
        },
      });
      exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
      expect(exercise.deleted, isTrue);
      expect(exercise.chineseName, '远端动作新版');
    },
  );

  test('remote v2 events create local rows by sync id without using remote numeric ids', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final service = BackupService();
    const routineSyncId = 'remote-routine-sync-id';
    const daySyncId = 'remote-day-sync-id';
    const sessionSyncId = 'remote-session-sync-id';
    const firstLogSyncId = 'remote-log-sync-id-1';
    const secondLogSyncId = 'remote-log-sync-id-2';

    final routineApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'routine',
      'entityId': 7,
      'entitySyncId': 'routine:$routineSyncId',
      'action': 'create',
      'snapshot': {
        'id': 7,
        'syncId': routineSyncId,
        'name': '跨设备计划',
        'totalWeeks': 1,
        'daysPerWeek': 1,
        'archived': true,
        'completedWeeks': [1],
        'deleted': false,
        'createdAt': DateTime(2026, 6, 2, 10, 45, 27).toIso8601String(),
        'updatedAt': DateTime(2026, 6, 2, 10, 45, 27).toIso8601String(),
        'days': [
          {
            'id': 118,
            'syncId': daySyncId,
            'week': 1,
            'day': 1,
            'name': 'D1',
            'actions': [
              {
                'name': '哑铃农夫行走',
                'targetSets': 3,
                'targetReps': 8,
                'slotSyncId': 'remote-slot-sync-id-1',
                'syncId': 'remote-slot-entry-sync-id-1',
              },
              {
                'name': '哑铃弯举',
                'targetSets': 3,
                'targetReps': 8,
                'recordMode': localRecordModeFree,
                'slotSyncId': 'remote-slot-sync-id-2',
                'syncId': 'remote-slot-entry-sync-id-2',
              },
            ],
          },
        ],
      },
    });
    expect(routineApplied, isTrue);
    final routine = (await db.select(db.localRoutines).get()).single;
    expect(routine.syncId, routineSyncId);
    expect(routine.id, isNot(7));
    expect(routine.archived, isTrue);
    expect(jsonDecode(routine.completedWeeksJson), [1]);
    final day = (await db.select(db.localTrainingDays).get()).single;
    expect(day.syncId, daySyncId);
    expect(day.routineId, routine.id);

    final sessionSnapshot = {
      'id': 112,
      'syncId': sessionSyncId,
      'routineId': 7,
      'routineSyncId': routineSyncId,
      'dayId': 118,
      'daySyncId': daySyncId,
      'startedAt': DateTime(2026, 6, 2, 10, 45, 30).toIso8601String(),
      'endedAt': DateTime(2026, 6, 2, 10, 45, 38).toIso8601String(),
      'note': '',
      'updatedAt': DateTime(2026, 6, 2, 10, 45, 38).toIso8601String(),
      'logs': [
        {
          'id': 1783,
          'syncId': firstLogSyncId,
          'sessionId': 112,
          'sessionSyncId': sessionSyncId,
          'routineId': 7,
          'routineSyncId': routineSyncId,
          'dayId': 118,
          'daySyncId': daySyncId,
          'exerciseName': '哑铃农夫行走',
          'setIndex': 1,
          'weight': 0.0,
          'reps': 8,
          'durationSeconds': 1,
          'createdAt': DateTime(2026, 6, 2, 10, 45, 32).toIso8601String(),
        },
        {
          'id': 1784,
          'syncId': secondLogSyncId,
          'sessionId': 112,
          'sessionSyncId': sessionSyncId,
          'routineId': 7,
          'routineSyncId': routineSyncId,
          'dayId': 118,
          'daySyncId': daySyncId,
          'exerciseName': '哑铃弯举',
          'setIndex': 1,
          'weight': 0.0,
          'reps': 0,
          'durationSeconds': 2,
          'recordMode': localRecordModeFree,
          'createdAt': DateTime(2026, 6, 2, 10, 45, 33).toIso8601String(),
        },
      ],
    };

    final sessionApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entityId': 112,
      'entitySyncId': 'workout_session:$sessionSyncId',
      'action': 'create',
      'snapshot': sessionSnapshot,
    });
    expect(sessionApplied, isTrue);
    final session = (await db.select(db.localWorkoutSessions).get()).single;
    expect(session.syncId, sessionSyncId);
    expect(session.id, isNot(112));
    expect(session.routineId, routine.id);
    expect(session.dayId, day.id);
    final logs = await db.select(db.localWorkoutLogs).get();
    expect(logs.map((log) => log.syncId), containsAll([firstLogSyncId, secondLogSyncId]));
    expect(logs.every((log) => log.sessionId == session.id), isTrue);
    expect(logs.every((log) => log.routineId == routine.id), isTrue);
    expect(logs.every((log) => log.dayId == day.id), isTrue);
    final freeLog = logs.singleWhere((log) => log.syncId == secondLogSyncId);
    expect(freeLog.recordMode, localRecordModeFree);
    expect(freeLog.durationSeconds, 2);

    final logApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_log',
      'entityId': 1783,
      'entitySyncId': 'workout_log:$firstLogSyncId',
      'action': 'create',
      'snapshot': (sessionSnapshot['logs'] as List<Object?>).first,
    });
    expect(logApplied, isTrue);
    final afterLogEvent = await db.select(db.localWorkoutLogs).get();
    expect(afterLogEvent, hasLength(2));

    final incompleteRoutineApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'routine',
      'entitySyncId': 'routine:$routineSyncId',
      'action': 'update',
      'snapshot': {
        'syncId': routineSyncId,
        'name': '跨设备计划',
        'updatedAt': DateTime(2026, 6, 2, 10, 46).toIso8601String(),
      },
    });
    expect(incompleteRoutineApplied, isTrue);
    expect(await db.select(db.localTrainingDays).get(), hasLength(1));

    final incompleteSessionApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entitySyncId': 'workout_session:$sessionSyncId',
      'action': 'update',
      'snapshot': {
        'syncId': sessionSyncId,
        'routineSyncId': routineSyncId,
        'daySyncId': daySyncId,
        'startedAt': DateTime(2026, 6, 2, 10, 45, 30).toIso8601String(),
        'updatedAt': DateTime(2026, 6, 2, 10, 46).toIso8601String(),
      },
    });
    expect(incompleteSessionApplied, isTrue);
    expect(await db.select(db.localWorkoutLogs).get(), hasLength(2));
  });

  test(
    'remote history events with changed sync ids do not duplicate existing workout records',
    () async {
      await locator.reset();
      final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
      locator.registerSingleton<LocalTrainingDatabase>(db);
      addTearDown(() async {
        await locator.reset();
        await db.close();
      });

      final repository = LocalTrainingRepository(db);
      final plan = LocalTrainingPlanModel(name: '两个月增肌PPL六练', totalWeeks: 1, daysPerWeek: 1)
        ..days['1-1'] = LocalTrainingDayModel(
          week: 1,
          day: 1,
          name: 'D1',
          actions: [LocalTrainingActionModel(name: '杠铃深蹲')],
        );
      await repository.savePlan(plan);
      final savedPlan = (await repository.getPlans()).single;
      final day = savedPlan.days.values.single;
      final sessionId = await repository.startSession(savedPlan, day);
      await repository.addLog(
        sessionId: sessionId,
        routineId: savedPlan.id!,
        dayId: day.id,
        exerciseName: '杠铃深蹲',
        setIndex: 1,
        weight: 75,
        reps: 6,
        durationSeconds: 120,
        note: '杠铃深蹲 / Squats；RIR：2；杠铃深蹲｜主项，稳定优先。',
      );
      await repository.finishSession(sessionId, note: '热 累 健身房好小气 人少就不开空调');

      final localSession = await (db.select(
        db.localWorkoutSessions,
      )..where((row) => row.id.equals(sessionId))).getSingle();
      final localLog = (await db.select(db.localWorkoutLogs).get()).single;
      final service = BackupService();
      const oldRoutineSyncId = 'old-routine-sync-id';
      const oldSessionSyncId = 'old-session-sync-id';
      const oldLogSyncId = 'old-log-sync-id';
      final remoteLogSnapshot = {
        'syncId': oldLogSyncId,
        'sessionSyncId': oldSessionSyncId,
        'routineSyncId': oldRoutineSyncId,
        'exerciseName': localLog.exerciseName,
        'setIndex': localLog.setIndex,
        'weight': localLog.weight,
        'reps': localLog.reps,
        'rir': localLog.rir,
        'durationSeconds': localLog.durationSeconds,
        'recordMode': localLog.recordMode,
        'note': localLog.note,
        'createdAt': localLog.createdAt.toIso8601String(),
        'updatedAt': localLog.createdAt.toIso8601String(),
      };

      final sessionApplied = await service.applyRemoteSyncEventForTest({
        'entityType': 'workout_session',
        'entitySyncId': 'workout_session:$oldSessionSyncId',
        'action': 'create',
        'snapshot': {
          'syncId': oldSessionSyncId,
          'routineSyncId': oldRoutineSyncId,
          'startedAt': localSession.startedAt.toIso8601String(),
          'endedAt': localSession.endedAt?.toIso8601String(),
          'note': localSession.note,
          'updatedAt': localSession.updatedAt.toIso8601String(),
          'logs': [remoteLogSnapshot],
        },
      });
      expect(sessionApplied, isTrue);
      expect(await db.select(db.localRoutines).get(), hasLength(1));
      expect(await db.select(db.localWorkoutSessions).get(), hasLength(1));
      expect(await db.select(db.localWorkoutLogs).get(), hasLength(1));

      final logApplied = await service.applyRemoteSyncEventForTest({
        'entityType': 'workout_log',
        'entitySyncId': 'workout_log:$oldLogSyncId',
        'action': 'create',
        'snapshot': remoteLogSnapshot,
      });
      expect(logApplied, isTrue);
      expect(await db.select(db.localRoutines).get(), hasLength(1));
      expect(await db.select(db.localWorkoutSessions).get(), hasLength(1));
      expect(await db.select(db.localWorkoutLogs).get(), hasLength(1));
    },
  );

  test('legacy history events with missing parents do not block remote sync', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final service = BackupService();
    const routineSyncId = 'missing-routine-sync-id';
    const sessionSyncId = 'legacy-session-sync-id';
    const logSyncId = 'legacy-log-sync-id';
    final createdAt = DateTime(2026, 5, 21, 19, 37, 24);

    final obsoleteUpdateHandled = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entitySyncId': 'workout_session:obsolete-session-sync-id',
      'action': 'update',
      'snapshot': null,
    });
    expect(obsoleteUpdateHandled, isTrue);

    final sessionApplied = await service.applyRemoteSyncEventForTest({
      'entityType': 'workout_session',
      'entitySyncId': 'workout_session:$sessionSyncId',
      'action': 'create',
      'snapshot': {
        'syncId': sessionSyncId,
        'routineSyncId': routineSyncId,
        'startedAt': createdAt.toIso8601String(),
        'updatedAt': createdAt.toIso8601String(),
        'logs': [
          {
            'syncId': logSyncId,
            'sessionSyncId': sessionSyncId,
            'routineSyncId': routineSyncId,
            'exerciseName': '历史训练动作',
            'setIndex': 1,
            'weight': 20.0,
            'reps': 10,
            'createdAt': createdAt.toIso8601String(),
          },
        ],
      },
    });
    expect(sessionApplied, isTrue);

    final routines = await db.select(db.localRoutines).get();
    expect(routines, hasLength(1));
    expect(routines.single.syncId, routineSyncId);
    expect(routines.single.deleted, isTrue);
    expect(routines.single.archived, isTrue);
    expect(await LocalTrainingRepository(db).getPlans(), isEmpty);

    final sessions = await db.select(db.localWorkoutSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.syncId, sessionSyncId);
    expect(sessions.single.routineId, routines.single.id);

    final logs = await db.select(db.localWorkoutLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.syncId, logSyncId);
    expect(logs.single.sessionId, sessions.single.id);
    expect(logs.single.routineId, routines.single.id);
  });
}

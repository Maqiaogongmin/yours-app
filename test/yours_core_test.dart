import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/yours_vault_service.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Yours training and exercise seeds are valid', () async {
    final trainingRaw = await rootBundle.loadString('assets/data/demo_training_data.json');
    final training = jsonDecode(trainingRaw) as Map<String, dynamic>;

    expect(training['routines'], isA<List<dynamic>>());
    expect(training['days'], isA<List<dynamic>>());
    expect(training['sessions'], isA<List<dynamic>>());
    expect(training['logs'], isA<List<dynamic>>());
    expect(training['routines'] as List<dynamic>, isEmpty);
    expect(training['days'] as List<dynamic>, isEmpty);

    final exercisesRaw = await rootBundle.loadString('assets/data/custom_exercises_seed.json');
    final exercises = jsonDecode(exercisesRaw) as Map<String, dynamic>;
    final rows = exercises['exercises'] as List<dynamic>;

    expect(rows, hasLength(5));
    expect(rows.first, containsPair('chineseName', isA<String>()));
  });

  test('training logs can overwrite a saved set without duplicating it', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '有思测试计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推', targetSets: 3, targetReps: 8),
      ],
    );

    final routineId = await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);

    await repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: day.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 50,
      reps: 6,
      durationSeconds: 60,
      note: '第一组肩部略紧',
    );
    await repository.deleteSetLogs(sessionId: sessionId, exerciseName: '杠铃卧推', setIndex: 1);
    await repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: day.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 50,
      reps: 8,
      durationSeconds: 120,
      note: '调整姿势后稳定',
    );

    final logs = await db.select(db.localWorkoutLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.reps, 8);
    expect(logs.single.setIndex, 1);
    expect(logs.single.note, '调整姿势后稳定');

    final detailLogs = await repository.getLogsForDate(DateTime.now());
    expect(detailLogs.single.note, '调整姿势后稳定');
  });

  test('workout detail logs keep real training order instead of exercise name order', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '排序测试计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '腿B',
      actions: [
        LocalTrainingActionModel(name: '螃蟹走'),
        LocalTrainingActionModel(name: '传统硬拉'),
        LocalTrainingActionModel(name: '罗马尼亚硬拉'),
      ],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);

    Future<void> insertLog(String name, int setIndex, DateTime createdAt) {
      return db
          .into(db.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              sessionId: sessionId,
              routineId: savedPlan.id!,
              dayId: Value(day.id),
              exerciseName: name,
              setIndex: setIndex,
              weight: const Value(0),
              reps: const Value(10),
              durationSeconds: const Value(60),
              syncStatus: const Value(localSyncPending),
              createdAt: createdAt,
            ),
          );
    }

    await insertLog('螃蟹走', 1, DateTime(2026, 5, 24, 19, 50));
    await insertLog('传统硬拉', 1, DateTime(2026, 5, 24, 20, 7));
    await insertLog('罗马尼亚硬拉', 1, DateTime(2026, 5, 24, 20, 30));

    final logs = await repository.getLogsForDate(DateTime(2026, 5, 24));

    expect(logs.map((log) => log.exerciseName), [
      '螃蟹走',
      '传统硬拉',
      '罗马尼亚硬拉',
    ]);
  });

  test('plans can be archived and weeks can be marked without deleting history', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '可重复计划', totalWeeks: 2, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推'),
        LocalTrainingActionModel(name: '快走', recordMode: localRecordModeFree),
      ],
    );
    await repository.savePlan(plan);
    final saved = (await repository.getPlans()).single;
    final sessionId = await repository.startSession(saved, saved.days['1-1']);
    await repository.finishSession(sessionId);

    final completed = await repository.toggleCompletedWeek(saved.id!, 1);
    expect(completed, {1});
    await repository.setPlanArchived(saved.id!, true);

    expect(await repository.getPlans(), hasLength(1));
    expect(await repository.watchPlans(archived: false).first, isEmpty);
    final archived = (await repository.watchPlans(archived: true).first).single;
    expect(archived.archived, isTrue);
    expect(archived.completedWeeks, {1});
    expect(await db.select(db.localWorkoutSessions).get(), hasLength(1));
  });

  test('free records do not count as strength volume or standard sets', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '混合训练计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推', targetSets: 1, targetReps: 8),
        LocalTrainingActionModel(
          name: '快走',
          recordMode: localRecordModeFree,
          note: '操场 20 分钟',
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
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 50,
      reps: 8,
      durationSeconds: 60,
      recordMode: localRecordModeStandard,
    );
    await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '快走',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 1200,
      note: '操场 20 分钟',
      recordMode: localRecordModeFree,
    );
    await repository.finishSession(sessionId);

    final stats = await repository.getStats(
      from: DateTime.now().subtract(const Duration(days: 1)),
      to: DateTime.now().add(const Duration(days: 1)),
    );
    expect(stats.totalVolume, 400);
    expect(stats.setCount, 1);
    expect(stats.freeRecordCount, 1);

    final sessions = await repository.getWorkoutSessionsForDate(DateTime.now());
    expect(sessions, hasLength(1));
    final freeLog = sessions.single.logs.singleWhere((log) => log.exerciseName == '快走');
    expect(freeLog.recordMode, localRecordModeFree);
    expect(freeLog.durationSeconds, 1200);

    final records = await repository.getDailyRecordsForMonth(DateTime.now());
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final record = records[today]!;
    expect(record.totalVolume, 400);
    expect(record.setCount, 1);
    expect(record.freeRecordCount, 1);
  });

  test('empty open sessions stay visible without being resumed or adding duration', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '中断记录测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '散步', recordMode: localRecordModeFree)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    final startedAt = DateTime(2026, 6, 2, 20);
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(sessionId))).write(
      LocalWorkoutSessionsCompanion(startedAt: Value(startedAt)),
    );

    final resumable = await repository.findOpenSessionForDay(
      routineId: savedPlan.id!,
      dayId: day.id,
    );
    expect(resumable, isNull);

    final sessions = await repository.getWorkoutSessionsForDate(startedAt);
    expect(sessions, hasLength(1));
    expect(sessions.single.id, sessionId);
    expect(sessions.single.endedAt, isNull);
    expect(sessions.single.logs, isEmpty);

    final records = await repository.getDailyRecordsForMonth(startedAt);
    final record = records[DateTime(2026, 6, 2)]!;
    expect(record.sessionCount, 1);
    expect(record.duration, Duration.zero);

    final loggedSessionId = await repository.startSession(savedPlan, day);
    await repository.addLog(
      sessionId: loggedSessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '散步',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 10 * 60,
      recordMode: localRecordModeFree,
    );
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(loggedSessionId))).write(
      LocalWorkoutSessionsCompanion(
        startedAt: Value(startedAt.subtract(const Duration(hours: 1))),
      ),
    );
    final loggedResume = await repository.findOpenSessionForDay(
      routineId: savedPlan.id!,
      dayId: day.id,
    );
    expect(loggedResume?.sessionId, loggedSessionId);
  });

  test('empty free session can be completed with existing session and log formats', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '补全自由记录', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '散步', recordMode: localRecordModeFree)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    final startedAt = DateTime(2026, 6, 2, 20);
    final endedAt = DateTime(2026, 6, 2, 20, 40);
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(sessionId))).write(
      LocalWorkoutSessionsCompanion(startedAt: Value(startedAt)),
    );

    final logId = await repository.completeEmptyWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      sessionNote: '晚饭后',
      exerciseName: '散步',
      recordMode: localRecordModeFree,
      setIndex: 1,
      weight: 0,
      reps: 0,
      actionNote: '公园一圈',
    );

    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();
    final log = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(logId))).getSingle();
    expect(session.startedAt, startedAt);
    expect(session.endedAt, endedAt);
    expect(session.note, '晚饭后');
    expect(log.exerciseName, '散步');
    expect(log.recordMode, localRecordModeFree);
    expect(log.durationSeconds, 40 * 60);
    expect(log.note, '公园一圈');

    final queue = await db.select(db.localSyncQueue).get();
    expect(
      queue.where(
        (item) =>
            item.entityType == 'workout_session' &&
            item.entityId == sessionId &&
            item.action == 'update',
      ),
      hasLength(1),
    );
    expect(
      queue.where(
        (item) =>
            item.entityType == 'workout_log' && item.entityId == logId && item.action == 'create',
      ),
      hasLength(1),
    );
  });

  test('session times and workout notes update through existing sync entities', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '记录编辑测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '快走', recordMode: localRecordModeFree)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    final logId = await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '快走',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 10 * 60,
      recordMode: localRecordModeFree,
    );
    final startedAt = DateTime(2026, 6, 10, 20, 51);
    final endedAt = DateTime(2026, 6, 10, 21);

    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      note: '训练备注',
    );
    await repository.updateWorkoutLog(
      logId: logId,
      setIndex: 1,
      weight: 0,
      reps: 0,
      note: '动作备注',
      durationSeconds: 9 * 60,
    );

    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();
    final log = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(logId))).getSingle();
    expect(session.startedAt, startedAt);
    expect(session.endedAt, endedAt);
    expect(session.note, '训练备注');
    expect(log.durationSeconds, 9 * 60);
    expect(log.note, '动作备注');

    await expectLater(
      repository.updateWorkoutSession(
        sessionId: sessionId,
        startedAt: endedAt,
        endedAt: startedAt,
        note: '',
      ),
      throwsArgumentError,
    );
  });

  test('workout sessions are grouped by time and can be deleted with sync event', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '删除训练记录测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '杠铃卧推')],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final firstSessionId = await repository.startSession(savedPlan, day);
    await repository.addLog(
      sessionId: firstSessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 60,
      reps: 8,
      durationSeconds: 60,
    );
    await repository.finishSession(firstSessionId, note: '第一次训练');

    final secondSessionId = await repository.startSession(savedPlan, day);
    await repository.addLog(
      sessionId: secondSessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 62.5,
      reps: 6,
      durationSeconds: 60,
    );
    await repository.finishSession(secondSessionId, note: '第二次训练');

    final sessions = await repository.getWorkoutSessionsForDate(DateTime.now());
    expect(sessions, hasLength(2));
    expect(sessions.first.id, firstSessionId);
    expect(sessions.last.id, secondSessionId);
    final firstSession = (await (db.select(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(firstSessionId))).get()).single;
    await db
        .update(db.localSyncQueue)
        .write(
          const LocalSyncQueueCompanion(status: Value(localSyncSynced)),
        );
    await repository.finishSession(firstSessionId, note: '待删除更新');
    await repository.finishSession(secondSessionId, note: '应保留更新');

    await repository.deleteWorkoutSession(firstSessionId);

    final remainingSessions = await repository.getWorkoutSessionsForDate(DateTime.now());
    expect(remainingSessions, hasLength(1));
    expect(remainingSessions.single.id, secondSessionId);

    final deletedLogs = await (db.select(
      db.localWorkoutLogs,
    )..where((log) => log.sessionId.equals(firstSessionId))).get();
    expect(deletedLogs, isEmpty);

    final deleteEvents =
        await (db.select(db.localSyncQueue)..where(
              (item) =>
                  item.entityType.equals('workout_session') &
                  item.entityId.equals(firstSessionId) &
                  item.action.equals('delete'),
            ))
            .get();
    expect(deleteEvents, hasLength(1));
    expect(deleteEvents.single.entitySyncId, 'workout_session:${firstSession.syncId}');
    final pendingNonDeleteEvents =
        await (db.select(db.localSyncQueue)..where(
              (item) =>
                  item.entityType.equals('workout_session') &
                  item.entityId.equals(firstSessionId) &
                  item.action.equals('delete').not() &
                  (item.status.equals(localSyncPending) | item.status.equals(localSyncFailed)),
            ))
            .get();
    expect(pendingNonDeleteEvents, isEmpty);
    final otherSessionPendingEvents =
        await (db.select(db.localSyncQueue)..where(
              (item) =>
                  item.entityType.equals('workout_session') &
                  item.entityId.equals(secondSessionId) &
                  item.action.equals('delete').not() &
                  (item.status.equals(localSyncPending) | item.status.equals(localSyncFailed)),
            ))
            .get();
    expect(otherSessionPendingEvents, hasLength(1));
  });

  test('server smart sync suggests initial restore only for empty local data', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
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

  test('new local sync queue events use stable sync ids', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '稳定身份测试', totalWeeks: 1, daysPerWeek: 1);
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

    final routine = (await db.select(db.localRoutines).get()).single;
    final session = (await db.select(db.localWorkoutSessions).get()).single;
    final log = (await db.select(db.localWorkoutLogs).get()).single;
    expect(routine.syncId, isNotEmpty);
    expect(day.syncId, isNotEmpty);
    expect(session.syncId, isNotEmpty);
    expect(log.syncId, isNotEmpty);

    final queue = await db.select(db.localSyncQueue).get();
    expect(queue.map((item) => item.entitySyncId), contains('routine:${routine.syncId}'));
    expect(queue.map((item) => item.entitySyncId), contains('workout_session:${session.syncId}'));
    expect(queue.map((item) => item.entitySyncId), contains('workout_log:${log.syncId}'));
    expect(queue.every((item) => item.eventId.isNotEmpty), isTrue);
    expect(queue.every((item) => item.deviceId.isNotEmpty), isTrue);
  });

  test('database migrations backfill stable sync ids for old local data', () async {
    final dir = await Directory.systemTemp.createTemp('yours-sync-migration-');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    final trainingFile = File('${dir.path}/training.sqlite');
    final oldTraining = sqlite.sqlite3.open(trainingFile.path);
    final timestamp = DateTime(2026, 1, 1, 8).millisecondsSinceEpoch;
    try {
      oldTraining
        ..execute('PRAGMA user_version = 3')
        ..execute('''
          CREATE TABLE local_routines (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            name TEXT NOT NULL,
            total_weeks INTEGER NOT NULL DEFAULT 4,
            days_per_week INTEGER NOT NULL DEFAULT 4,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            deleted INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_training_days (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            routine_id INTEGER NOT NULL,
            week INTEGER NOT NULL,
            day INTEGER NOT NULL,
            name TEXT NOT NULL,
            actions_json TEXT NOT NULL DEFAULT '[]',
            sync_status TEXT NOT NULL DEFAULT 'pending',
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_slots (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            day_id INTEGER NOT NULL,
            "order" INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''')
        ..execute('''
          CREATE TABLE local_slot_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            slot_id INTEGER NOT NULL,
            exercise_name TEXT NOT NULL,
            exercise_id INTEGER NULL,
            target_sets INTEGER NOT NULL DEFAULT 3,
            target_reps INTEGER NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''')
        ..execute('''
          CREATE TABLE local_workout_sessions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            routine_id INTEGER NOT NULL,
            day_id INTEGER NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_workout_logs (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            session_id INTEGER NOT NULL,
            routine_id INTEGER NOT NULL,
            day_id INTEGER NULL,
            exercise_name TEXT NOT NULL,
            set_index INTEGER NOT NULL,
            weight REAL NOT NULL DEFAULT 0,
            reps INTEGER NOT NULL DEFAULT 0,
            rir REAL NULL,
            duration_seconds INTEGER NOT NULL DEFAULT 0,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            created_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_sync_queue (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL DEFAULT '{}',
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          INSERT INTO local_routines
            (id, name, total_weeks, days_per_week, sync_status, deleted, created_at, updated_at)
          VALUES (1, '旧计划', 1, 1, 'pending', 0, $timestamp, $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_training_days
            (id, routine_id, week, day, name, actions_json, sync_status, updated_at)
          VALUES (1, 1, 1, 1, 'D1', '[]', 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_slots (id, day_id, "order", sync_status)
          VALUES (1, 1, 0, 'pending')
        ''')
        ..execute('''
          INSERT INTO local_slot_entries
            (id, slot_id, exercise_name, target_sets, target_reps, sync_status)
          VALUES (1, 1, '深蹲', 3, 5, 'pending')
        ''')
        ..execute('''
          INSERT INTO local_workout_sessions
            (id, routine_id, day_id, started_at, sync_status, updated_at)
          VALUES (1, 1, 1, $timestamp, 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_workout_logs
            (id, session_id, routine_id, day_id, exercise_name, set_index, weight, reps, duration_seconds, sync_status, created_at)
          VALUES (1, 1, 1, 1, '深蹲', 1, 80, 5, 90, 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_sync_queue
            (id, entity_type, entity_id, action, payload, status, attempts, created_at, updated_at)
          VALUES (1, 'routine', 1, 'upsert', '{}', 'pending', 0, $timestamp, $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_sync_queue
            (id, entity_type, entity_id, action, payload, status, attempts, created_at, updated_at)
          VALUES (2, 'workout_session', 999, 'delete', '{}', 'pending', 0, $timestamp, $timestamp)
        ''');
    } finally {
      oldTraining.dispose();
    }

    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase(trainingFile));
    addTearDown(trainingDb.close);
    final routine = (await trainingDb.select(trainingDb.localRoutines).get()).single;
    final day = (await trainingDb.select(trainingDb.localTrainingDays).get()).single;
    final slot = (await trainingDb.select(trainingDb.localSlots).get()).single;
    final entry = (await trainingDb.select(trainingDb.localSlotEntries).get()).single;
    final session = (await trainingDb.select(trainingDb.localWorkoutSessions).get()).single;
    final log = (await trainingDb.select(trainingDb.localWorkoutLogs).get()).single;
    final queue = await (trainingDb.select(
      trainingDb.localSyncQueue,
    )..orderBy([(item) => OrderingTerm.asc(item.id)])).get();

    expect([
      routine.syncId,
      day.syncId,
      slot.syncId,
      entry.syncId,
      session.syncId,
      log.syncId,
    ], everyElement(isNotEmpty));
    expect(queue.first.eventId, isNotEmpty);
    expect(queue.first.deviceId, startsWith('legacy-'));
    expect(queue.first.entitySyncId, 'routine:${routine.syncId}');
    expect(queue.last.entityType, 'workout_session');
    expect(queue.last.entitySyncId, isEmpty);
    expect(queue.last.status, localSyncSynced);
    expect(routine.archived, isFalse);
    expect(routine.completedWeeksJson, '[]');
    expect(entry.recordMode, localRecordModeStandard);
    expect(log.recordMode, localRecordModeStandard);

    final exerciseFile = File('${dir.path}/custom.sqlite');
    final oldExercises = sqlite.sqlite3.open(exerciseFile.path);
    try {
      oldExercises
        ..execute('PRAGMA user_version = 1')
        ..execute('''
          CREATE TABLE custom_exercises (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            chinese_name TEXT NOT NULL,
            english_name TEXT NOT NULL DEFAULT '',
            body_part TEXT NOT NULL,
            equipment TEXT NOT NULL,
            primary_muscles TEXT NOT NULL,
            description TEXT NOT NULL,
            image_paths_json TEXT NOT NULL DEFAULT '[]',
            is_custom INTEGER NOT NULL DEFAULT 1,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            deleted INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE custom_exercise_images (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            exercise_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            caption TEXT NULL,
            created_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          INSERT INTO custom_exercises
            (id, chinese_name, body_part, equipment, primary_muscles, description, created_at, updated_at)
          VALUES (1, '旧动作', '腿', '杠铃', '股四头肌', '旧库动作', $timestamp, $timestamp)
        ''');
    } finally {
      oldExercises.dispose();
    }
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase(exerciseFile));
    addTearDown(exerciseDb.close);
    final exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
    expect(exercise.syncId, isNotEmpty);
  });

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

  test('server status parses protocol version and latest cursor', () {
    final status = ServerSyncStatus.fromJson({
      'ok': true,
      'serverVersion': 'YoursBackupServer/0.2',
      'protocolVersion': 2,
      'identityMode': 'syncId',
      'eventCount': 12,
      'latestCursor': 12,
      'latestBackup': {
        'bytes': 52834,
        'updatedAt': '2026-06-01T21:40:36',
      },
      'message': 'ok',
    });

    expect(status.available, isTrue);
    expect(status.protocolVersion, 2);
    expect(status.identityMode, 'syncId');
    expect(status.latestCursor, 12);
    expect(status.latestBackupBytes, 52834);
    expect(status.latestBackupAt, DateTime.parse('2026-06-01T21:40:36'));
  });

  test('local gym session resumes an unfinished stored session at the next set', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '恢复测试计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '推A',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推', targetSets: 4, targetReps: 6),
        LocalTrainingActionModel(name: '上斜哑铃卧推', targetSets: 2, targetReps: 8),
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
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 52.5,
      reps: 6,
      durationSeconds: 60,
      note: '第一组',
    );
    await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '杠铃卧推',
      setIndex: 2,
      weight: 52.5,
      reps: 6,
      durationSeconds: 120,
      note: '第二组',
    );

    final session = LocalGymSessionController.instance;
    await session.startOrResume(savedPlan, day);

    expect(session.currentExercise, 'built_in:bench_press');
    expect(session.setIndex, 3);
    expect(session.getSavedDataForCurrentSet(), isNull);

    final restoredPrevious = session.previewPreviousSet();
    expect(restoredPrevious, isTrue);
    expect(session.setIndex, 2);
    expect(session.getSavedDataForCurrentSet()?.reps, 6);

    await session.finishSession(note: '恢复后手动结束', markIncomplete: true);
  });

  test('local gym session keeps notes per set and returns across exercise boundary', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '哑铃侧平举',
          targetSets: 3,
          targetReps: 10,
          note: '动作默认备注',
        ),
        LocalTrainingActionModel(
          name: '绳索下压',
          targetSets: 2,
          targetReps: 12,
          note: '第二个动作默认备注',
        ),
      ],
    );
    final plan = LocalTrainingPlanModel(name: '训练计时测试', totalWeeks: 1, daysPerWeek: 1)
      ..days['1-1'] = day;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(plan, day);

    expect(session.currentExercise, '哑铃侧平举');
    expect(session.setIndex, 1);
    expect(session.currentSetNote, '动作默认备注');

    session.updateCurrentSetNote('第一组备注');
    expect(session.currentSetNote, '第一组备注');

    expect(session.previewNextSet(), isTrue);
    expect(session.setIndex, 2);
    expect(session.currentSetNote, '动作默认备注');

    session.updateCurrentSetNote('第二组备注');
    expect(session.previewNextSet(), isTrue);
    expect(session.setIndex, 3);
    expect(session.currentSetNote, '动作默认备注');

    expect(session.previewPreviousSet(), isTrue);
    expect(session.setIndex, 2);
    expect(session.currentSetNote, '第二组备注');

    expect(session.previewNextSet(), isTrue);
    expect(session.previewNextSet(), isTrue);
    expect(session.currentExercise, '绳索下压');
    expect(session.setIndex, 1);

    expect(session.previewPreviousSet(), isTrue);
    expect(session.currentExercise, '哑铃侧平举');
    expect(session.setIndex, 3);
    expect(session.currentSetNote, '动作默认备注');
  });

  test('free record elapsed time is not reset by exercise preview navigation', () async {
    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '自由记录',
      actions: [
        LocalTrainingActionModel(name: '长跑', recordMode: localRecordModeFree),
        LocalTrainingActionModel(name: '杠铃卧推', targetSets: 1, targetReps: 8),
      ],
    );
    final plan = LocalTrainingPlanModel(name: '自由记录计时测试', totalWeeks: 1, daysPerWeek: 1)
      ..days['1-1'] = day;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(plan, day);
    expect(session.currentExercise, '长跑');
    expect(session.isCurrentFreeRecord, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final beforePreview = session.currentActionElapsed;
    expect(beforePreview.inSeconds, greaterThanOrEqualTo(1));

    expect(session.previewNextSet(), isTrue);
    expect(session.currentExercise, '杠铃卧推');
    expect(session.previewPreviousSet(), isTrue);
    expect(session.currentExercise, '长跑');

    final afterPreview = session.currentActionElapsed;
    expect(afterPreview, greaterThanOrEqualTo(beforePreview));
  });

  test('custom exercise repository imports the Yours seed library', () async {
    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = CustomExerciseRepository(db);

    await repository.ensureSeedData();

    final rows = await db.select(db.customExercises).get();
    expect(rows.length, greaterThanOrEqualTo(1));
    expect(rows.every((row) => row.chineseName.trim().isNotEmpty), isTrue);
  });

  test('Yours Vault export writes manifest and plan files', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final repository = LocalTrainingRepository(trainingDb);
    final plan = LocalTrainingPlanModel(name: 'Vault 测试计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推'),
        LocalTrainingActionModel(name: '快走', recordMode: localRecordModeFree),
      ],
    );
    await repository.savePlan(plan);

    final dir = await Directory.systemTemp.createTemp('yours_vault_test_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).exportVault(dir);

    expect(result.planCount, 1);
    final manifest = File('${dir.path}/manifest.json');
    expect(manifest.existsSync(), isTrue);
    final decoded = jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    expect(decoded['format'], 'yours-vault');
    final planFile = Directory('${dir.path}/plans').listSync().whereType<File>().single;
    final planJson = jsonDecode(await planFile.readAsString()) as Map<String, dynamic>;
    final weeks = planJson['weeks'] as List<dynamic>;
    final firstDay = (weeks.single as Map<String, dynamic>)['days'] as List<dynamic>;
    final actions = (firstDay.single as Map<String, dynamic>)['actions'] as List<dynamic>;
    final freeAction = actions.cast<Map<String, dynamic>>().singleWhere(
      (action) => action['exercise'] == '快走',
    );
    expect(freeAction['recordMode'], localRecordModeFree);
  });

  test('Yours Vault resolves reopened databases after restore', () async {
    if (locator.isRegistered<LocalTrainingDatabase>()) {
      await locator.unregister<LocalTrainingDatabase>();
    }
    if (locator.isRegistered<CustomExerciseDatabase>()) {
      await locator.unregister<CustomExerciseDatabase>();
    }

    final oldTrainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final oldExerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(oldTrainingDb);
    locator.registerSingleton<CustomExerciseDatabase>(oldExerciseDb);
    final service = YoursVaultService();

    await locator.unregister<LocalTrainingDatabase>();
    await locator.unregister<CustomExerciseDatabase>();
    await oldTrainingDb.close();
    await oldExerciseDb.close();

    final reopenedTrainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final reopenedExerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(reopenedTrainingDb);
    locator.registerSingleton<CustomExerciseDatabase>(reopenedExerciseDb);
    addTearDown(() async {
      if (locator.isRegistered<LocalTrainingDatabase>()) {
        await locator.unregister<LocalTrainingDatabase>();
      }
      if (locator.isRegistered<CustomExerciseDatabase>()) {
        await locator.unregister<CustomExerciseDatabase>();
      }
      await reopenedTrainingDb.close();
      await reopenedExerciseDb.close();
    });

    final repository = LocalTrainingRepository(reopenedTrainingDb);
    await repository.savePlan(LocalTrainingPlanModel(name: '恢复后计划'));

    final dir = await Directory.systemTemp.createTemp('yours_vault_reopened_test_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    final result = await service.exportVault(dir);

    expect(result.planCount, 1);
    expect(File('${dir.path}/manifest.json').existsSync(), isTrue);
  });

  test('Yours Vault inbox imports a new plan', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_new_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/new-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': 'Inbox 新计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '推',
                'actions': [
                  {'exercise': '杠铃卧推', 'sets': 4, 'reps': '6-8'},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 1);
    expect(result.failedFiles, isEmpty);
    final plans = await LocalTrainingRepository(trainingDb).getPlans();
    expect(plans.single.name, 'Inbox 新计划');
    expect(plans.single.days.values.single.actions.single.targetReps, 6);
  });

  test('Yours Vault inbox updates an existing plan without deleting workout logs', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );

    final repository = LocalTrainingRepository(trainingDb);
    final plan = LocalTrainingPlanModel(
      name: '两个月增肌PPL六练',
      totalWeeks: 1,
      daysPerWeek: 1,
      archived: true,
      completedWeeks: {1},
    );
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '推',
      actions: [LocalTrainingActionModel(name: '杠铃卧推', targetSets: 2, targetReps: 6)],
    );
    final routineId = await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final sessionId = await repository.startSession(savedPlan, savedPlan.days.values.single);
    await repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: savedPlan.days.values.single.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 50,
      reps: 6,
      durationSeconds: 60,
    );

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_update_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/update-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'action': 'upsert',
        'matchName': '两个月增肌PPL六练',
        'name': '两个月增肌PPL六练',
        'totalWeeks': 1,
        'daysPerWeek': 1,
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '推',
                'actions': [
                  {'name': '杠铃卧推', 'sets': 4, 'reps': 8},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 1);
    final plans = await repository.getPlans();
    expect(plans, hasLength(1));
    final updated = plans.single;
    expect(updated.id, routineId);
    expect(updated.syncId, savedPlan.syncId);
    expect(updated.archived, isTrue);
    expect(updated.completedWeeks, contains(1));
    expect(updated.days.values.single.actions.single.targetSets, 4);
    expect(await trainingDb.localWorkoutSessions.count().getSingle(), 1);
    expect(await trainingDb.localWorkoutLogs.count().getSingle(), 1);
  });

  test('Yours Vault inbox imports exercises before plans', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_exercise_first_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/new-exercise.exercise.json').writeAsString(
      jsonEncode({
        'format': 'yours-exercise',
        'formatVersion': 1,
        'action': 'upsert',
        'name': '新动作',
        'category1': '背部',
        'category2': '器械',
      }),
    );
    await File('${dir.path}/inbox/new-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': '含新动作计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '拉',
                'actions': [
                  {'exercise': '新动作', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedExercises, 1);
    expect(result.importedPlans, 1);
    expect(result.failedFiles, isEmpty);
  });

  test('Yours Vault inbox reports missing exercises and malformed plans', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_errors_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/missing.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': '缺动作计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '训练',
                'actions': [
                  {'exercise': '不存在动作', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );
    await File('${dir.path}/inbox/bad.plan.json').writeAsString('{');

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 0);
    expect(result.failedFiles, hasLength(2));
    expect(
      result.failedFiles.map((file) => file.message).join('\n'),
      contains('不存在动作'),
    );
    expect(
      result.failedFiles.map((file) => file.message).join('\n'),
      contains('Unexpected end of input'),
    );
  });

  test('Yours Vault inbox rejects ambiguous plan updates', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );
    final repository = LocalTrainingRepository(trainingDb);
    await repository.savePlan(LocalTrainingPlanModel(name: '重复计划'));
    await repository.savePlan(LocalTrainingPlanModel(name: '重复计划'));

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_ambiguous_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/ambiguous.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'action': 'update',
        'matchName': '重复计划',
        'name': '重复计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '训练',
                'actions': [
                  {'exercise': '杠铃卧推', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 0);
    expect(result.failedFiles.single.message, contains('Multiple existing plans'));
    expect(await trainingDb.localRoutines.count().getSingle(), 2);
  });
}

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/sync_identity.dart';

void main() {
  test('free record actions default to one target set when sets are omitted', () async {
    final fromJson = LocalTrainingActionModel.fromJson({
      'name': '散步',
      'recordMode': localRecordModeFree,
    });
    expect(fromJson.targetSets, 1);

    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '自由记录默认组数', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '散步', recordMode: localRecordModeFree)],
    );

    await repository.savePlan(plan);
    final saved = (await repository.getPlans()).single.days.values.single.actions.single;
    expect(saved.recordMode, localRecordModeFree);
    expect(saved.targetSets, 1);
  });

  test('editing a plan keeps training days referenced by saved sessions', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '引用保留计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '腿A',
      actions: [
        LocalTrainingActionModel(name: '深蹲'),
      ],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final oldDay = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, oldDay);
    await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: oldDay.id,
      exerciseName: '深蹲',
      setIndex: 1,
      weight: 100,
      reps: 5,
      durationSeconds: 60,
    );

    savedPlan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '腿A 更新',
      actions: [
        LocalTrainingActionModel(name: '前蹲'),
      ],
    );
    await repository.savePlan(savedPlan);

    final oldDayRow = await (db.select(
      db.localTrainingDays,
    )..where((day) => day.id.equals(oldDay.id!))).getSingleOrNull();
    final detailSessions = await repository.getWorkoutSessionsForDate(DateTime.now());

    expect(oldDayRow?.name, '腿A');
    expect(detailSessions.single.dayName, '腿A');
    expect((await repository.getPlans()).single.days.values.single.name, '腿A 更新');
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

  test('batched local training readers preserve plan targets and workout summaries', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final strengthPlan = LocalTrainingPlanModel(
      name: '批量读取力量计划',
      totalWeeks: 2,
      daysPerWeek: 2,
    );
    strengthPlan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '推',
      actions: [
        LocalTrainingActionModel(
          name: '杠铃卧推',
          targetSets: 4,
          targetReps: 6,
          targetWeight: 80,
        ),
        LocalTrainingActionModel(name: '快走', recordMode: localRecordModeFree),
      ],
    );
    strengthPlan.days['1-2'] = LocalTrainingDayModel(
      week: 1,
      day: 2,
      name: '拉',
      actions: [LocalTrainingActionModel(name: '传统硬拉', targetSets: 3, targetReps: 5)],
    );
    await repository.savePlan(strengthPlan);

    final accessoryPlan = LocalTrainingPlanModel(name: '批量读取辅助计划');
    accessoryPlan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '辅助',
      actions: [LocalTrainingActionModel(name: '侧平举', targetSets: 2, targetReps: 15)],
    );
    await repository.savePlan(accessoryPlan);

    Future<void> expectPlans(List<LocalTrainingPlanModel> plans) async {
      final byName = {for (final plan in plans) plan.name: plan};
      final savedStrength = byName['批量读取力量计划']!;
      expect(savedStrength.days, hasLength(2));
      final pushActions = savedStrength.days['1-1']!.actions;
      expect(pushActions[0].name, 'built_in:bench_press');
      expect(pushActions[0].targetSets, 4);
      expect(pushActions[0].targetReps, 6);
      expect(pushActions[0].targetWeight, 80);
      expect(pushActions[0].syncId, isNotEmpty);
      expect(pushActions[1].recordMode, localRecordModeFree);
      expect(byName['批量读取辅助计划']!.days['1-1']!.actions.single.targetReps, 15);
    }

    await expectPlans(await repository.getPlans());
    await expectPlans(await repository.watchPlans().first);

    final savedPlan = (await repository.getPlans()).singleWhere((plan) => plan.name == '批量读取力量计划');
    final day = savedPlan.days['1-1']!;
    final firstSessionId = await repository.startSession(savedPlan, day);
    final secondSessionId = await repository.startSession(savedPlan, day);
    final emptyEndedSessionId = await repository.startSession(savedPlan, day);
    final emptyOpenSessionId = await repository.startSession(savedPlan, day);
    final olderOpenSessionId = await repository.startSession(savedPlan, day);
    final workoutDate = DateTime(2026, 6, 3, 8);

    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(firstSessionId))).write(
      LocalWorkoutSessionsCompanion(
        startedAt: Value(workoutDate),
        endedAt: Value(workoutDate.add(const Duration(minutes: 30))),
        note: const Value('上午力量'),
      ),
    );
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(secondSessionId))).write(
      LocalWorkoutSessionsCompanion(
        startedAt: Value(workoutDate.add(const Duration(hours: 10))),
        endedAt: Value(workoutDate.add(const Duration(hours: 10, minutes: 20))),
        note: const Value('未完成训练计划：晚上补充'),
      ),
    );
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(emptyEndedSessionId))).write(
      LocalWorkoutSessionsCompanion(
        startedAt: Value(workoutDate.add(const Duration(hours: 12))),
        endedAt: Value(workoutDate.add(const Duration(hours: 12, minutes: 5))),
      ),
    );
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(emptyOpenSessionId))).write(
      LocalWorkoutSessionsCompanion(startedAt: Value(workoutDate.add(const Duration(hours: 13)))),
    );
    await (db.update(
      db.localWorkoutSessions,
    )..where((session) => session.id.equals(olderOpenSessionId))).write(
      LocalWorkoutSessionsCompanion(startedAt: Value(workoutDate.add(const Duration(hours: 11)))),
    );

    Future<void> addFixedLog({
      required int sessionId,
      required String exerciseName,
      required int setIndex,
      required double weight,
      required int reps,
      required int durationSeconds,
      required DateTime createdAt,
      String recordMode = localRecordModeStandard,
    }) async {
      await db
          .into(db.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              syncId: Value(SyncId.newId()),
              sessionId: sessionId,
              routineId: savedPlan.id!,
              dayId: Value(day.id),
              exerciseName: exerciseName,
              setIndex: setIndex,
              weight: Value(weight),
              reps: Value(reps),
              durationSeconds: Value(durationSeconds),
              recordMode: Value(recordMode),
              syncStatus: const Value(localSyncPending),
              createdAt: createdAt,
            ),
          );
    }

    await addFixedLog(
      sessionId: firstSessionId,
      exerciseName: '杠铃卧推',
      setIndex: 0,
      weight: 80,
      reps: 6,
      durationSeconds: 90,
      createdAt: workoutDate.add(const Duration(minutes: 1)),
    );
    await addFixedLog(
      sessionId: firstSessionId,
      exerciseName: '杠铃卧推',
      setIndex: 0,
      weight: 82.5,
      reps: 5,
      durationSeconds: 95,
      createdAt: workoutDate.add(const Duration(minutes: 3)),
    );
    await addFixedLog(
      sessionId: secondSessionId,
      exerciseName: '快走',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 1200,
      recordMode: localRecordModeFree,
      createdAt: workoutDate.add(const Duration(hours: 10, minutes: 1)),
    );
    await addFixedLog(
      sessionId: olderOpenSessionId,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 60,
      reps: 8,
      durationSeconds: 80,
      createdAt: workoutDate.add(const Duration(hours: 11, minutes: 1)),
    );

    final sessions = await repository.getWorkoutSessionsForDate(workoutDate);
    expect(sessions.map((session) => session.id), [
      firstSessionId,
      secondSessionId,
      olderOpenSessionId,
      emptyOpenSessionId,
    ]);
    expect(sessions.first.logs.map((log) => log.setIndex), [1, 2]);
    expect(sessions[1].logs.single.recordMode, localRecordModeFree);
    expect(sessions[1].logs.single.durationSeconds, 1200);

    final records = await repository.getDailyRecordsForMonth(workoutDate);
    final record = records[DateTime(2026, 6, 3)]!;
    expect(record.sessionCount, 4);
    expect(record.setCount, 3);
    expect(record.freeRecordCount, 1);
    expect(record.totalVolume, 80 * 6 + 82.5 * 5 + 60 * 8);
    expect(record.duration, const Duration(minutes: 50));
    expect(record.incomplete, isTrue);
    expect(record.note, contains('上午力量'));
    expect(record.note, contains('未完成训练计划'));

    final resumable = await repository.findOpenSessionForDay(
      routineId: savedPlan.id!,
      dayId: day.id,
    );
    expect(resumable?.sessionId, olderOpenSessionId);
    expect(resumable?.logs.single.exerciseName, '杠铃卧推');
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

  test('reading history repairs only a single zero-duration free log', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '自由记录修复', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '散步', recordMode: localRecordModeFree)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final startedAt = DateTime(2026, 7, 11, 17, 41, 38);
    final endedAt = DateTime(2026, 7, 11, 18, 26, 40);

    final repairableSessionId = await repository.startSession(savedPlan, day);
    final repairableLogId = await repository.addLog(
      sessionId: repairableSessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '散步',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 0,
      recordMode: localRecordModeFree,
    );
    await repository.updateWorkoutSession(
      sessionId: repairableSessionId,
      startedAt: startedAt,
      endedAt: endedAt,
      note: '',
    );

    final ambiguousSessionId = await repository.startSession(savedPlan, day);
    await repository.updateWorkoutSession(
      sessionId: ambiguousSessionId,
      startedAt: startedAt.add(const Duration(hours: 2)),
      endedAt: endedAt.add(const Duration(hours: 2)),
      note: '',
    );
    for (final exercise in ['散步', '慢跑']) {
      await repository.addLog(
        sessionId: ambiguousSessionId,
        routineId: savedPlan.id!,
        dayId: day.id,
        exerciseName: exercise,
        setIndex: 1,
        weight: 0,
        reps: 0,
        durationSeconds: 0,
        recordMode: localRecordModeFree,
      );
    }

    final sessions = await repository.getWorkoutSessionsForDate(startedAt);
    final repaired = sessions.singleWhere((session) => session.id == repairableSessionId);
    final ambiguous = sessions.singleWhere((session) => session.id == ambiguousSessionId);
    expect(repaired.logs.single.durationSeconds, 2702);
    expect(ambiguous.logs.map((log) => log.durationSeconds), everyElement(0));

    final stored = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(repairableLogId))).getSingle();
    expect(stored.durationSeconds, 2702);
    final queue = await db.select(db.localSyncQueue).get();
    expect(
      queue.where(
        (item) =>
            item.entityType == 'workout_log' &&
            item.entityId == repairableLogId &&
            item.action == 'update',
      ),
      hasLength(1),
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
}

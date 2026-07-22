import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';

void main() {
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
        LocalTrainingActionModel(name: '长跑', targetSets: 1, recordMode: localRecordModeFree),
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

  test('free record target duration defaults to zero without explicit duration', () async {
    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '腿A',
      actions: [
        LocalTrainingActionModel(
          name: 'built_in:plank',
          targetReps: 45,
          recordMode: localRecordModeFree,
        ),
      ],
    );
    final plan = LocalTrainingPlanModel(name: '平板支撑测试', totalWeeks: 1, daysPerWeek: 1)
      ..days['1-1'] = day;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(plan, day);

    expect(session.currentExercise, 'built_in:plank');
    expect(session.currentTargetSets, 1);
    expect(session.currentFreeRecordTargetDurationSeconds, 0);
    await session.finishSessionLocal(note: 'free duration default cleanup');
  });

  test('free record target duration uses explicit duration', () async {
    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '腿A',
      actions: [
        LocalTrainingActionModel(
          name: '螃蟹走',
          targetSets: 2,
          targetReps: 12,
          targetDurationSeconds: 60,
          recordMode: localRecordModeFree,
        ),
      ],
    );
    final plan = LocalTrainingPlanModel(name: '自由记录时长测试', totalWeeks: 1, daysPerWeek: 1)
      ..days['1-1'] = day;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(plan, day);

    expect(session.currentExercise, '螃蟹走');
    expect(session.currentFreeRecordTargetDurationSeconds, 60);
    await session.finishSessionLocal(note: 'free duration explicit cleanup');
  });

  test('early finish keeps user note without automatic incomplete marker', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '提前结束测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '深蹲', targetSets: 2)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(savedPlan, day);
    await session.saveSet(weight: 80, reps: 8, restSeconds: 0);
    await session.finishSessionLocal(note: '状态不佳，收工。', markIncomplete: true);

    final sessions = await repository.getWorkoutSessionsForDate(DateTime.now());
    expect(sessions.single.note, '状态不佳，收工。');
    expect(sessions.single.note, isNot(contains('未完成训练计划')));
  });

  test('local gym replacement only affects the active session action', () async {
    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '临时替换',
      actions: [
        LocalTrainingActionModel(name: '蝴蝶机夹胸', targetSets: 3, targetReps: 10),
        LocalTrainingActionModel(name: '绳索下压', targetSets: 2, targetReps: 12),
      ],
    );
    final plan = LocalTrainingPlanModel(name: '替换测试', totalWeeks: 1, daysPerWeek: 1)
      ..days['1-1'] = day;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(plan, day);

    expect(session.currentExercise, '蝴蝶机夹胸');
    session.replaceCurrentAction(
      LocalTrainingActionModel(
        name: '绳索夹胸',
        targetSets: 2,
        targetReps: 8,
        recordMode: localRecordModeFree,
        targetDurationSeconds: 60,
      ),
    );

    expect(session.currentExercise, '绳索夹胸');
    expect(session.isCurrentFreeRecord, isTrue);
    expect(session.currentAction.targetDurationSeconds, 60);
    expect(session.currentTargetSets, 2);
    expect(session.currentTargetReps, 8);
    expect(day.actions.first.name, '蝴蝶机夹胸');
    expect(plan.days['1-1']!.actions.first.name, '蝴蝶机夹胸');
  });

  test('free record plan targets persist through actions json', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);

    final plan = LocalTrainingPlanModel(name: '自由记录计划设置', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '平板支撑',
          targetSets: 3,
          targetWeight: 10,
          targetRestSeconds: 45,
          targetDurationSeconds: 60,
          recordMode: localRecordModeFree,
        ),
      ],
    );

    await repository.savePlan(plan);
    final saved = (await repository.getPlans()).single.days.values.single.actions.single;

    expect(saved.recordMode, localRecordModeFree);
    expect(saved.targetSets, 3);
    expect(saved.targetWeight, 10);
    expect(saved.targetRestSeconds, 45);
    expect(saved.targetDurationSeconds, 60);
  });

  test('free record saves sets weight and duration without effective sets', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '自由记录保存测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '平板支撑',
          targetSets: 3,
          recordMode: localRecordModeFree,
        ),
      ],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(savedPlan, day);
    expect(session.currentTargetSets, 3);
    expect(session.setIndex, 1);

    await session.completeFreeRecord(
      weight: 10,
      durationSeconds: 45,
      restSeconds: 0,
    );
    expect(session.setIndex, 2);
    await session.completeFreeRecord(
      weight: 10,
      durationSeconds: 45,
      restSeconds: 0,
    );
    expect(session.setIndex, 3);
    await session.completeFreeRecord(
      weight: 10,
      durationSeconds: 45,
      restSeconds: 0,
    );
    expect(session.isFinished, isTrue);

    await session.finishSessionLocal(note: '自由记录完成');

    final logs = await db.select(db.localWorkoutLogs).get();
    expect(logs, hasLength(3));
    expect(logs.every((log) => log.recordMode == localRecordModeFree), isTrue);
    expect(logs.map((log) => log.setIndex), [1, 2, 3]);
    expect(logs.every((log) => log.weight == 10), isTrue);
    expect(logs.every((log) => log.durationSeconds == 45), isTrue);
    expect(logs.every((log) => log.hasActualValues), isTrue);
    expect(logs.every((log) => log.actualWeight == 10), isTrue);
    expect(logs.every((log) => log.actualDurationSeconds == 45), isTrue);
    expect(logs.every((log) => log.restSeconds == 0), isTrue);

    final records = await repository.getDailyRecordsForMonth(DateTime.now());
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    expect(records[today]?.setCount, 0);
    expect(records[today]?.freeRecordCount, 3);
  });

  test('local gym persists typed input as a draft without creating a workout log', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '草稿测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [LocalTrainingActionModel(name: '杠铃卧推', targetSets: 2)],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final session = LocalGymSessionController.instance;
    await session.startOrResume(savedPlan, day);

    await session.updateCurrentInputDraft(
      weightText: '72.5',
      repsText: '6',
      restText: '',
      noteText: '保留输入',
    );
    await session.flushInputDrafts();

    expect(await db.select(db.localWorkoutLogs).get(), isEmpty);
    expect((await db.select(db.localWorkoutSetDrafts).get()).single.weightText, '72.5');
    expect(session.previewNextSet(), isTrue);
    expect(session.previewPreviousSet(), isTrue);
    expect(session.currentInputDraft?.weightText, '72.5');
    expect(session.currentInputDraft?.noteText, '保留输入');

    await session.finishSessionLocal(note: '结束草稿测试');
    expect(await db.select(db.localWorkoutSetDrafts).get(), isEmpty);
  });

  test('undoing the final set resumes elapsed timer updates', () async {
    await locator.reset();
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '撤销完成态计时测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推', targetSets: 1, targetReps: 8),
      ],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;

    final session = LocalGymSessionController.instance;
    await session.startOrResume(savedPlan, day);
    await session.saveSet(weight: 60, reps: 8, restSeconds: 0);
    expect(session.isFinished, isTrue);

    var tickCount = 0;
    void listener() {
      tickCount += 1;
    }

    session.addListener(listener);
    addTearDown(() => session.removeListener(listener));
    final undo = await session.undoCurrentSet();
    expect(undo, isNotNull);
    expect(session.isFinished, isFalse);

    final afterUndoNotifications = tickCount;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(tickCount, greaterThan(afterUndoNotifications));

    await session.finishSessionLocal(note: '测试结束', markIncomplete: true);
  });
}

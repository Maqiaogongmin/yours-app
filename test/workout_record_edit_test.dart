import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/pages/home/home_page.dart';
import 'package:yours/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workout record keeps inline time, duration, and note editing', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '页面测试', totalWeeks: 1, daysPerWeek: 1);
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
    final logId = await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '散步',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 9 * 60,
      note: '动作备注',
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: yoursLightTheme,
        home: WorkoutRecordDetailPage(date: startedAt, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    Finder textFieldWithValue(String value) {
      return find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == value,
      );
    }

    expect(textFieldWithValue('20'), findsOneWidget);
    expect(textFieldWithValue('51'), findsOneWidget);
    expect(textFieldWithValue('21'), findsOneWidget);
    expect(find.byKey(ValueKey('session-$sessionId-end-minutes')), findsOneWidget);
    expect(find.byKey(ValueKey('log-duration-$logId-hours')), findsOneWidget);
    expect(find.byKey(ValueKey('log-duration-$logId-minutes')), findsOneWidget);
    expect(find.byKey(ValueKey('log-duration-$logId-seconds')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(ValueKey('log-duration-$logId-minutes'))).width,
      lessThan(40),
    );
    expect(
      tester.getSize(find.byKey(ValueKey('session-$sessionId-start-hours'))).width,
      lessThan(40),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('log-duration-$logId-minutes')))
          .controller
          ?.text,
      '09',
    );
    expect(textFieldWithValue('训练备注'), findsOneWidget);
    expect(textFieldWithValue('动作备注'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);

    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-minutes')), '01');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('log-duration-$logId-minutes')))
          .controller
          ?.text,
      '10',
    );
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);

    await tester.enterText(find.byKey(ValueKey('log-duration-$logId-minutes')), '08');
    await tester.pump();
    expect(textFieldWithValue('59'), findsOneWidget);

    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-minutes')), '60');
    await tester.enterText(find.byKey(ValueKey('log-duration-$logId-minutes')), '60');
    await tester.enterText(find.byKey(ValueKey('log-duration-$logId-seconds')), '99');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('session-$sessionId-end-minutes')))
          .controller
          ?.text,
      '59',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('log-duration-$logId-minutes')))
          .controller
          ?.text,
      '08',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('log-duration-$logId-seconds')))
          .controller
          ?.text,
      '00',
    );

    final timePartFields = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLength == 2,
    );
    expect(timePartFields, findsNWidgets(7));
    for (final field in tester.widgetList<TextField>(timePartFields)) {
      expect(field.controller?.text.contains(':'), isFalse);
    }

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();
    final log = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(logId))).getSingle();
    expect(session.startedAt, startedAt);
    expect(session.endedAt, DateTime(2026, 6, 10, 20, 59));
    expect(log.durationSeconds, 8 * 60);
    expect(log.note, '动作备注');
  });

  testWidgets('interrupted empty workout uses split end time and library exercise picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    addTearDown(exerciseDb.close);
    if (locator.isRegistered<CustomExerciseDatabase>()) {
      await locator.unregister<CustomExerciseDatabase>();
    }
    locator.registerSingleton<CustomExerciseDatabase>(exerciseDb);
    addTearDown(() async {
      if (locator.isRegistered<CustomExerciseDatabase>()) {
        await locator.unregister<CustomExerciseDatabase>();
      }
    });

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '测试散步',
        bodyPart: '有氧',
        equipment: '徒手',
        primaryMuscles: '心肺',
        description: '',
      ),
    );

    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '中断测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(week: 1, day: 1, name: 'D1');
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    final startedAt = DateTime(2026, 6, 10, 20);
    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: null,
      note: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: yoursLightTheme,
        home: WorkoutRecordDetailPage(date: startedAt, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final twoDigitFields = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLength == 2,
    );
    expect(find.text('添加动作'), findsOneWidget);
    expect(twoDigitFields, findsNWidgets(4));
    expect(
      find.byWidgetPredicate((widget) => widget is TextField && widget.controller?.text == '20:50'),
      findsNothing,
    );

    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-hours')), '20');
    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-minutes')), '50');
    await tester.tap(find.text('添加动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试散步'));
    await tester.pumpAndSettle();
    expect(find.text('测试散步'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自由记录').last);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('session-duration-$sessionId-hours')), findsOneWidget);
    expect(find.byKey(ValueKey('session-duration-$sessionId-minutes')), findsOneWidget);
    expect(find.byKey(ValueKey('session-duration-$sessionId-seconds')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('session-duration-$sessionId-minutes')))
          .controller
          ?.text,
      '50',
    );

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final logs = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.sessionId.equals(sessionId))).get();
    expect(logs, hasLength(1));
    expect(logs.single.exerciseName, '测试散步');
    expect(logs.single.recordMode, localRecordModeFree);
    expect(logs.single.durationSeconds, 50 * 60);
  });

  testWidgets('interrupted empty workout asks for an exercise before saving', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '中断测试', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(week: 1, day: 1, name: 'D1');
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;
    final sessionId = await repository.startSession(savedPlan, day);
    final startedAt = DateTime(2026, 7, 1, 20);
    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: null,
      note: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: yoursLightTheme,
        home: WorkoutRecordDetailPage(date: startedAt, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-hours')), '20');
    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-minutes')), '45');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('保存失败：请先添加动作'), findsOneWidget);
    expect(find.text('保存失败：未知错误'), findsNothing);
  });

  testWidgets('unfinished workout with an existing log keeps split end time after reopening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '重开测试', totalWeeks: 1, daysPerWeek: 1);
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
    final logId = await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '散步',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 0,
      recordMode: localRecordModeFree,
    );
    final startedAt = DateTime(2026, 6, 11, 20);
    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: startedAt,
      endedAt: null,
      note: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: yoursLightTheme,
        home: WorkoutRecordDetailPage(date: startedAt, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final twoDigitFields = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLength == 2,
    );
    expect(twoDigitFields, findsNWidgets(7));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == '--:--',
      ),
      findsNothing,
    );

    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-hours')), '20');
    await tester.enterText(find.byKey(ValueKey('session-$sessionId-end-minutes')), '30');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();
    final log = await (db.select(
      db.localWorkoutLogs,
    )..where((row) => row.id.equals(logId))).getSingle();
    expect(session.endedAt, DateTime(2026, 6, 11, 20, 30));
    expect(log.durationSeconds, 30 * 60);
  });
}

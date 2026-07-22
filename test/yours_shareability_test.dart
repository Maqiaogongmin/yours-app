import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/shareability/yours_share_models.dart';
import 'package:yours/redesign/shareability/yours_workout_share_poster_page.dart';
import 'package:yours/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('share poster options default to deep purple', () {
    const options = YoursSharePosterOptions();
    expect(options.preset, YoursSharePosterPreset.deepPurple);
    expect(options.showWorkoutName, isTrue);
    expect(options.showBrand, isTrue);
  });

  test('workout share data aggregates exercise count from sessions', () {
    final date = DateTime(2026, 6, 17);
    final data = YoursWorkoutShareData.fromRecord(
      record: LocalTrainingDailyRecord(
        date: date,
        name: '上肢力量训练',
        sessionCount: 2,
        setCount: 3,
        totalVolume: 8420,
        duration: const Duration(minutes: 48),
        note: '今天状态不错',
      ),
      sessions: [
        LocalWorkoutSessionEditModel(
          id: 1,
          startedAt: date,
          endedAt: date.add(const Duration(minutes: 20)),
          dayId: 1,
          dayName: '休息',
          note: '撤销最后一组，返回记录页\n返回上一个动作后，计时器继续运行。',
          logs: [
            LocalWorkoutLogEditModel(
              id: 1,
              sessionId: 1,
              exerciseName: '卧推',
              setIndex: 1,
              weight: 80,
              reps: 8,
              note: '',
              createdAt: date,
            ),
            LocalWorkoutLogEditModel(
              id: 2,
              sessionId: 1,
              exerciseName: '卧推',
              setIndex: 2,
              weight: 80,
              reps: 8,
              note: '',
              createdAt: date,
            ),
          ],
        ),
        LocalWorkoutSessionEditModel(
          id: 2,
          startedAt: date,
          endedAt: date.add(const Duration(minutes: 48)),
          dayId: 1,
          dayName: '休息',
          note: '',
          logs: [
            LocalWorkoutLogEditModel(
              id: 3,
              sessionId: 2,
              exerciseName: '哑铃划船',
              setIndex: 1,
              weight: 40,
              reps: 10,
              note: '',
              createdAt: date,
            ),
          ],
        ),
      ],
      fallbackName: '训练记录',
    );

    expect(data.workoutName, '休息');
    expect(data.recordLabel, '训练记录');
    expect(data.note, '撤销最后一组，返回记录页\n返回上一个动作后，计时器继续运行。');
    expect(data.exerciseCount, 2);
    expect(data.setCount, 3);
    expect(data.totalVolume, 8420);
  });

  test('workout share name aggregates distinct session day snapshots', () {
    final date = DateTime(2026, 6, 29);
    final data = YoursWorkoutShareData.fromRecord(
      record: LocalTrainingDailyRecord(
        date: date,
        name: '训练记录',
        sessionCount: 2,
        setCount: 2,
        totalVolume: 1000,
        duration: const Duration(minutes: 60),
        note: '',
      ),
      sessions: [
        LocalWorkoutSessionEditModel(
          id: 1,
          startedAt: date.add(const Duration(hours: 8)),
          endedAt: date.add(const Duration(hours: 9)),
          routineName: '两个月增肌PPL六练',
          dayName: '推A',
          dayWeek: 8,
          dayIndex: 1,
          note: '',
          logs: const [],
        ),
        LocalWorkoutSessionEditModel(
          id: 2,
          startedAt: date.add(const Duration(hours: 15)),
          endedAt: date.add(const Duration(hours: 16)),
          routineName: '两个月增肌PPL六练',
          dayName: '拉A',
          dayWeek: 8,
          dayIndex: 2,
          note: '',
          logs: const [],
        ),
      ],
      fallbackName: '训练记录',
    );

    expect(data.workoutName, '推A + 拉A');
    expect(data.workoutSubtitle, '两个月增肌PPL六练 · W8 D1 + W8 D2');
  });

  test('workout share name does not fall back to daily record summary text', () {
    final date = DateTime(2026, 6, 16);
    final data = YoursWorkoutShareData.fromRecord(
      record: LocalTrainingDailyRecord(
        date: date,
        name: '未完成训练',
        sessionCount: 1,
        setCount: 1,
        totalVolume: 0,
        duration: const Duration(minutes: 40),
        note: '明天体检 休息\n未完成训练计划',
        incomplete: true,
      ),
      sessions: [
        LocalWorkoutSessionEditModel(
          id: 1,
          startedAt: date,
          endedAt: date.add(const Duration(minutes: 40)),
          note: '明天体检 休息\n未完成训练计划',
          logs: const [],
        ),
      ],
      fallbackName: '训练记录',
    );

    expect(data.workoutName, isEmpty);
    expect(data.workoutName, isNot('未完成训练'));
    expect(data.workoutName, isNot('训练记录'));
  });

  test(
    'workout sessions resolve day name from log day id when session day id is missing',
    () async {
      final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = LocalTrainingRepository(db);
      final now = DateTime(2026, 6, 16, 8);
      final routineId = await db
          .into(db.localRoutines)
          .insert(
            LocalRoutinesCompanion.insert(
              name: '测试计划',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final dayId = await db
          .into(db.localTrainingDays)
          .insert(
            LocalTrainingDaysCompanion.insert(
              routineId: routineId,
              week: 1,
              day: 1,
              name: '胸A',
              updatedAt: now,
            ),
          );
      final sessionId = await db
          .into(db.localWorkoutSessions)
          .insert(
            LocalWorkoutSessionsCompanion.insert(
              routineId: routineId,
              startedAt: now,
              endedAt: Value(now.add(const Duration(minutes: 40))),
              note: const Value('未完成训练计划'),
              updatedAt: now,
            ),
          );
      await db
          .into(db.localWorkoutLogs)
          .insert(
            LocalWorkoutLogsCompanion.insert(
              sessionId: sessionId,
              routineId: routineId,
              dayId: Value(dayId),
              exerciseName: '杠铃卧推',
              setIndex: 1,
              weight: const Value(60),
              reps: const Value(8),
              durationSeconds: const Value(60),
              createdAt: now.add(const Duration(minutes: 1)),
            ),
          );

      final sessions = await repository.getWorkoutSessionsForDate(now);
      final data = YoursWorkoutShareData.fromRecord(
        record: LocalTrainingDailyRecord(
          date: DateTime(2026, 6, 16),
          name: '未完成训练',
          sessionCount: 1,
          setCount: 1,
          totalVolume: 480,
          duration: const Duration(minutes: 40),
          note: '未完成训练计划',
          incomplete: true,
        ),
        sessions: sessions,
        fallbackName: '训练记录',
      );

      expect(sessions.single.dayId, dayId);
      expect(sessions.single.dayName, '胸A');
      expect(data.workoutName, '胸A');
    },
  );

  test('starting a session stores stable routine and day snapshots', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final now = DateTime(2026, 6, 29, 8);
    final routineId = await db
        .into(db.localRoutines)
        .insert(
          LocalRoutinesCompanion.insert(
            syncId: const Value('routine-sync'),
            name: '两个月增肌PPL六练',
            totalWeeks: const Value(8),
            daysPerWeek: const Value(7),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final dayId = await db
        .into(db.localTrainingDays)
        .insert(
          LocalTrainingDaysCompanion.insert(
            syncId: const Value('day-sync'),
            routineId: routineId,
            week: 8,
            day: 1,
            name: '推A',
            updatedAt: now,
          ),
        );

    final sessionId = await repository.startSession(
      LocalTrainingPlanModel(
        id: routineId,
        syncId: 'routine-sync',
        name: '两个月增肌PPL六练',
        totalWeeks: 8,
        daysPerWeek: 7,
      ),
      LocalTrainingDayModel(
        id: dayId,
        syncId: 'day-sync',
        week: 8,
        day: 1,
        name: '推A',
      ),
    );
    final session = await (db.select(
      db.localWorkoutSessions,
    )..where((row) => row.id.equals(sessionId))).getSingle();

    expect(session.routineNameSnapshot, '两个月增肌PPL六练');
    expect(session.routineSyncIdSnapshot, 'routine-sync');
    expect(session.dayNameSnapshot, '推A');
    expect(session.dayWeekSnapshot, 8);
    expect(session.dayIndexSnapshot, 1);
    expect(session.daySyncIdSnapshot, 'day-sync');
  });

  test('workout sessions do not infer stale missing day ids from the routine schedule', () async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LocalTrainingRepository(db);
    final base = DateTime(2026, 6, 16, 19);
    final routineId = await db
        .into(db.localRoutines)
        .insert(
          LocalRoutinesCompanion.insert(
            name: '两个月增肌PPL六练',
            totalWeeks: const Value(8),
            daysPerWeek: const Value(7),
            createdAt: base,
            updatedAt: base,
          ),
        );

    for (final entry in [
      (week: 6, day: 2, name: '拉A'),
      (week: 6, day: 3, name: '休息'),
      (week: 6, day: 4, name: '腿A'),
    ]) {
      await db
          .into(db.localTrainingDays)
          .insert(
            LocalTrainingDaysCompanion.insert(
              routineId: routineId,
              week: entry.week,
              day: entry.day,
              name: entry.name,
              updatedAt: base,
            ),
          );
    }
    final anchorDay =
        await (db.select(db.localTrainingDays)..where(
              (day) => day.routineId.equals(routineId) & day.week.equals(6) & day.day.equals(4),
            ))
            .getSingle();

    await db.customStatement('PRAGMA foreign_keys = OFF');
    final staleSessionId = await db
        .into(db.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            routineId: routineId,
            dayId: const Value(683),
            startedAt: base,
            endedAt: Value(base.add(const Duration(minutes: 40))),
            note: const Value('未完成训练计划'),
            updatedAt: base,
          ),
        );
    await db
        .into(db.localWorkoutLogs)
        .insert(
          LocalWorkoutLogsCompanion.insert(
            sessionId: staleSessionId,
            routineId: routineId,
            dayId: const Value(683),
            exerciseName: '杠铃划船',
            setIndex: 1,
            weight: const Value(60),
            reps: const Value(8),
            durationSeconds: const Value(60),
            createdAt: base.add(const Duration(minutes: 1)),
          ),
        );

    final restSessionId = await db
        .into(db.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            routineId: routineId,
            dayId: const Value(684),
            startedAt: base.add(const Duration(days: 1)),
            endedAt: Value(base.add(const Duration(days: 1, minutes: 55))),
            note: const Value('散步喂猫'),
            updatedAt: base,
          ),
        );
    await db
        .into(db.localWorkoutLogs)
        .insert(
          LocalWorkoutLogsCompanion.insert(
            sessionId: restSessionId,
            routineId: routineId,
            dayId: const Value(684),
            exerciseName: '散步',
            setIndex: 1,
            durationSeconds: const Value(3300),
            recordMode: const Value(localRecordModeFree),
            createdAt: base.add(const Duration(days: 1, minutes: 1)),
          ),
        );
    await db.customStatement('PRAGMA foreign_keys = ON');

    final anchorSessionId = await db
        .into(db.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            routineId: routineId,
            dayId: Value(anchorDay.id),
            startedAt: base.add(const Duration(days: 2)),
            endedAt: Value(base.add(const Duration(days: 2, minutes: 73))),
            note: const Value('撤销最后一组，返回记录页'),
            updatedAt: base,
          ),
        );
    await db
        .into(db.localWorkoutLogs)
        .insert(
          LocalWorkoutLogsCompanion.insert(
            sessionId: anchorSessionId,
            routineId: routineId,
            dayId: Value(anchorDay.id),
            exerciseName: '深蹲',
            setIndex: 1,
            weight: const Value(100),
            reps: const Value(5),
            durationSeconds: const Value(60),
            createdAt: base.add(const Duration(days: 2, minutes: 1)),
          ),
        );

    final day16 = await repository.getWorkoutSessionsForDate(base);
    final day17 = await repository.getWorkoutSessionsForDate(base.add(const Duration(days: 1)));
    final day18 = await repository.getWorkoutSessionsForDate(base.add(const Duration(days: 2)));

    expect(day16.single.dayName, isEmpty);
    expect(day17.single.dayName, isEmpty);
    expect(day18.single.dayName, '腿A');
  });

  for (final preset in YoursSharePosterPreset.values) {
    testWidgets('share poster renders $preset preset without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: yoursDarkTheme,
          home: Center(
            child: SizedBox(
              width: 360,
              child: YoursWorkoutSharePoster(
                data: _shareData(),
                options: YoursSharePosterOptions(preset: preset),
              ),
            ),
          ),
        ),
      );

      expect(find.text('上肢力量训练'), findsOneWidget);
      expect(find.text('一次完整、安静、值得保存的训练完成记录。'), findsNothing);
      expect(find.text('8,420'), findsOneWidget);
      final volumeText = tester.widget<Text>(find.text('8,420'));
      expect(volumeText.style?.fontFamily, 'RobotoCondensed');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('share poster hides optional note component', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursDarkTheme,
        home: Center(
          child: SizedBox(
            width: 360,
            child: YoursWorkoutSharePoster(
              data: _shareData(),
              options: const YoursSharePosterOptions(showNote: false),
            ),
          ),
        ),
      ),
    );

    expect(find.text('今天状态不错，卧推最后两组控制得更稳。'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('share poster page calls save channel', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var saved = false;
    messenger.setMockMethodCallHandler(const MethodChannel('yours/photos'), (call) async {
      if (call.method == 'saveImageToPhotos') {
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['bytes'], isA<Uint8List>());
        saved = true;
        return true;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(const MethodChannel('yours/photos'), null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(280, 700), textScaler: TextScaler.linear(1.4)),
          child: YoursWorkoutSharePosterPage(
            data: _shareData(),
            exportPosterBytes: (_, _) async => Uint8List.fromList([1, 2, 3]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFEDE4D8));
    expect(find.byType(YoursTonalAction), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.file_download_outlined));
    for (var i = 0; i < 10 && !saved; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(saved, isTrue);
  });

  testWidgets('share poster settings sections expand from compact headers', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(280, 700), textScaler: TextScaler.linear(1.2)),
          child: YoursWorkoutSharePosterPage(
            data: _shareData(),
            exportPosterBytes: (_, _) async => Uint8List.fromList([1, 2, 3]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('背景'), findsOneWidget);
    expect(find.text('组件'), findsOneWidget);
    final sectionCards = tester
        .widgetList<YoursSurfaceCard>(find.byType(YoursSurfaceCard))
        .where((card) => card.role == YoursSurfaceRole.controlOverlay)
        .toList();
    expect(sectionCards, hasLength(2));
    var sections = tester.widgetList<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).toList();
    expect(sections, hasLength(2));
    expect(sections.every((section) => section.crossFadeState == CrossFadeState.showFirst), isTrue);

    await tester.tap(find.text('背景'));
    await tester.pumpAndSettle();
    sections = tester.widgetList<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).toList();
    expect(sections.first.crossFadeState, CrossFadeState.showSecond);
    expect(sections.last.crossFadeState, CrossFadeState.showFirst);

    await tester.tap(find.text('组件'));
    await tester.pumpAndSettle();
    sections = tester.widgetList<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).toList();
    expect(sections.first.crossFadeState, CrossFadeState.showSecond);
    expect(sections.last.crossFadeState, CrossFadeState.showSecond);
    expect(tester.takeException(), isNull);
  });
}

YoursWorkoutShareData _shareData() {
  return YoursWorkoutShareData(
    workoutName: '上肢力量训练',
    recordLabel: '训练记录',
    date: DateTime(2026, 6, 17),
    duration: const Duration(minutes: 48),
    exerciseCount: 6,
    setCount: 18,
    totalVolume: 8420,
    note: '今天状态不错，卧推最后两组控制得更稳。',
  );
}

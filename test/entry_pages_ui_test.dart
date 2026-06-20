import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/app_update_service.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/pages/exercises/exercise_library_page.dart';
import 'package:yours/redesign/pages/home/home_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_mode_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';
import 'package:yours/redesign/pages/plan/plan_page.dart';
import 'package:yours/redesign/pages/profile/profile_page.dart';
import 'package:yours/redesign/pages/profile/settings_page.dart';
import 'package:yours/theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await locator.reset();
  });

  testWidgets('home renders empty and long-note workout records', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    locator.registerSingleton<LocalTrainingDatabase>(db);
    final repository = _NoSeedTrainingRepository(db);
    final recordDate = DateTime(DateTime.now().year, DateTime.now().month, 10, 8);
    final emptyDate = DateTime(DateTime.now().year, DateTime.now().month, 11);
    final plan = LocalTrainingPlanModel(name: '页面验收计划', totalWeeks: 1, daysPerWeek: 1);
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
      reps: 8,
      durationSeconds: 0,
    );
    const longNote = '这是一段很长的训练备注，用于验证首页训练记录卡在字体放大和窄屏下仍然能够正常换行显示。';
    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: recordDate,
      endedAt: recordDate.add(const Duration(minutes: 45)),
      note: longNote,
    );

    await tester.pumpWidget(_testApp(HomePage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey('home-day-${recordDate.year}-${recordDate.month}-${recordDate.day}')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('home-record-card')), findsOneWidget);
    expect(find.text(longNote), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_outlined), findsOneWidget);
    final volumeTop = tester.getTopLeft(find.text('总训练量 kg')).dy;
    final setTop = tester.getTopLeft(find.text('有效组')).dy;
    final minuteTop = tester.getTopLeft(find.text('分钟')).dy;
    expect((volumeTop - setTop).abs(), lessThan(2));
    expect((volumeTop - minuteTop).abs(), lessThan(2));
    final statusRect = tester.getRect(find.text('已记录'));
    final shareRect = tester.getRect(find.widgetWithIcon(IconButton, Icons.ios_share_outlined));
    expect(statusRect.right, lessThan(shareRect.left));
    final shareButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.ios_share_outlined),
    );
    expect(shareButton.style?.backgroundColor?.resolve({}), Colors.transparent);
    expect(shareButton.style?.foregroundColor?.resolve({}), isNot(Colors.red));
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(ValueKey('home-day-${emptyDate.year}-${emptyDate.month}-${emptyDate.day}')),
    );
    await tester.pump();
    expect(find.text('当天还没有训练记录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home labels free-only workout records as free items', (tester) async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    locator.registerSingleton<LocalTrainingDatabase>(db);
    final repository = _NoSeedTrainingRepository(db);
    final recordDate = DateTime(DateTime.now().year, DateTime.now().month, 12, 8);
    final plan = LocalTrainingPlanModel(name: '自由记录计划', totalWeeks: 1, daysPerWeek: 1);
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
    await repository.addLog(
      sessionId: sessionId,
      routineId: savedPlan.id!,
      dayId: day.id,
      exerciseName: '快走',
      setIndex: 1,
      weight: 0,
      reps: 0,
      durationSeconds: 1200,
      recordMode: localRecordModeFree,
    );
    await repository.updateWorkoutSession(
      sessionId: sessionId,
      startedAt: recordDate,
      endedAt: recordDate.add(const Duration(minutes: 20)),
      note: '',
    );

    await tester.pumpWidget(_testApp(HomePage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('home-day-${recordDate.year}-${recordDate.month}-${recordDate.day}')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('home-record-card')), findsOneWidget);
    expect(find.text('自由项目'), findsOneWidget);
    expect(find.text('有效组'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan page preserves filters, cards, menus, and swipe actions', (tester) async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _NoSeedTrainingRepository(db);
    final activeId = await repository.savePlan(
      LocalTrainingPlanModel(
        name: '这是一个用于验证长标题不会溢出的训练计划 Long Training Plan',
        totalWeeks: 12,
        daysPerWeek: 7,
      ),
    );
    final archivedId = await repository.savePlan(
      LocalTrainingPlanModel(name: '已归档计划', archived: true),
    );

    await tester.pumpWidget(_testApp(PlanPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('plan-card-$activeId')), findsOneWidget);
    expect(find.text('待同步'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-create')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byKey(ValueKey('plan-card-$activeId')), const Offset(-220, 0));
    await tester.pump();
    expect(find.text('编辑'), findsWidgets);
    expect(find.text('删除'), findsWidgets);

    await tester.tap(find.text('已归档'));
    await tester.pumpAndSettle();
    expect(find.text('已归档计划'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('plan-menu-$archivedId')));
    await tester.pumpAndSettle();
    expect(find.text('恢复使用'), findsOneWidget);
    Navigator.of(tester.element(find.text('恢复使用'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('使用中'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('plan-menu-$activeId')));
    await tester.pumpAndSettle();
    expect(find.text('归档'), findsOneWidget);
    Navigator.of(tester.element(find.text('归档'))).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('local gym mode starts and renders active workout inputs', (tester) async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await LocalGymSessionController.instance.finishSessionLocal(
        note: 'widget smoke cleanup',
        markIncomplete: true,
      );
      await locator.reset();
      await db.close();
    });

    final repository = _NoSeedTrainingRepository(db);
    final plan = LocalTrainingPlanModel(name: '训练中页面验收计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '深蹲',
          targetSets: 3,
          targetReps: 8,
          targetWeight: 80,
          targetRestSeconds: 90,
        ),
      ],
    );
    await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final day = savedPlan.days.values.single;

    await tester.pumpWidget(_testApp(LocalGymModePage(plan: savedPlan, day: day)));
    await tester.pumpAndSettle();

    expect(find.text('训练计时'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('保存本组并继续'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await LocalGymSessionController.instance.finishSessionLocal(
      note: 'widget smoke cleanup',
      markIncomplete: true,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('exercise library preserves search, filters, empty state, and sheets', (
    tester,
  ) async {
    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _NoSeedExerciseRepository(db);
    await repository.saveExercise(
      CustomExerciseModel(
        chineseName: '超长名称杠铃深蹲 Long Barbell Squat Exercise',
        bodyPart: '脚・下半身トレーニング',
        equipment: '杠铃',
        primaryMuscles: '股四头肌',
        description: '很长的动作说明，用于验证动作卡在窄屏和字体放大时不会发生文字溢出。',
      ),
    );
    await repository.saveExercise(
      CustomExerciseModel(
        chineseName: '俯卧撑',
        bodyPart: '胸部',
        equipment: '徒手',
        primaryMuscles: '胸大肌',
        description: '基础推类动作',
      ),
    );

    await tester.pumpWidget(_testApp(ExerciseLibraryPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('超长名称杠铃深蹲 Long Barbell Squat Exercise'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-add')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final searchField = find.descendant(
      of: find.byKey(const ValueKey('exercise-search')),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, '不存在的动作');
    await tester.pump();
    expect(find.byKey(const ValueKey('exercise-empty-state')), findsOneWidget);
    expect(find.textContaining('没有找到匹配动作'), findsOneWidget);

    await tester.enterText(searchField, '');
    await tester.pump();
    await tester.drag(
      find.descendant(
        of: find.byKey(const ValueKey('exercise-filter')),
        matching: find.byType(ListView),
      ),
      const Offset(-240, 0),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('exercise-filter')),
        matching: find.text('脚・下半身トレーニング'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('俯卧撑'), findsNothing);

    await tester.tap(find.text('超长名称杠铃深蹲 Long Barbell Squat Exercise'));
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    Navigator.of(tester.element(find.text('编辑'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('exercise-add')));
    await tester.pumpAndSettle();
    expect(find.text('保存到本地动作库'), findsOneWidget);
  });

  testWidgets('settings entries keep navigation and about callback', (tester) async {
    var aboutOpened = false;
    await tester.pumpWidget(
      _testApp(SettingsPage(onAbout: () => aboutOpened = true)),
    );

    expect(find.byKey(const ValueKey('settings-appearance')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-language')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-about')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-appearance')));
    await tester.pumpAndSettle();
    expect(find.text('跟随系统'), findsOneWidget);
    Navigator.of(tester.element(find.text('跟随系统'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-about')));
    expect(aboutOpened, isTrue);
  });

  testWidgets('profile entry cards render and settings navigation remains available', (
    tester,
  ) async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    await tester.pumpWidget(_testApp(const ProfilePage()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('profile-account-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-data-entry')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-settings-entry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-appearance')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile data management and about entry states remain reachable', (tester) async {
    final db = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(db);
    addTearDown(() async {
      await locator.reset();
      await db.close();
    });

    await tester.pumpWidget(_testApp(const ProfilePage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('profile-data-entry')));
    await tester.pumpAndSettle();
    expect(find.text('数据管理'), findsWidgets);
    expect(find.text('服务器同步'), findsOneWidget);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('立即同步'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.text('数据管理').last)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-settings-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-about')));
    await tester.pumpAndSettle();
    expect(find.text('关于有思（Yours）'), findsWidgets);
    expect(find.text('官网'), findsOneWidget);
    expect(find.text('GitHub 仓库'), findsOneWidget);
  });

  testWidgets('data management page renders server states and busy actions', (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = ValueNotifier<YoursDataManagementSnapshot>(
      YoursDataManagementSnapshot(
        latestBackupName: 'yours-backup.zip',
        latestBackupUpdatedAt: DateTime(2026, 6, 19, 21, 37),
        latestVaultPath: '/Users/ly/Documents/YoursVault',
        latestVaultExportedAt: DateTime(2026, 6, 19, 21, 36),
        serverConfigured: true,
        serverSyncStatus: ServerSyncStatus(
          available: true,
          serverVersion: '1.0.0',
          protocolVersion: 1,
          identityMode: 'localId',
          eventCount: 12,
          latestCursor: 9,
          latestBackupBytes: 2048,
          latestBackupAt: null,
          message: 'ok',
        ),
        pendingSyncCount: 3,
      ),
    );
    addTearDown(snapshot.dispose);
    var syncCalls = 0;
    final vaultCompleter = Completer<void>();
    final exportCompleter = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        YoursDataManagementPage(
          snapshotListenable: snapshot,
          onExportVault: () => vaultCompleter.future,
          onImportVaultInbox: () async {},
          onCreateBackup: () => exportCompleter.future,
          onExportBackupToICloud: () async {},
          onRestoreBackupFromICloud: () async {},
          onRestoreBackup: () async {},
          onEditServer: () async {},
          onCheckServer: () async {},
          onSyncServer: () async => syncCalls++,
          onCopyServerDiagnostics: () async {},
        ),
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('数据管理'), findsOneWidget);
    expect(find.text('上次导出：06-19 21:36'), findsOneWidget);
    expect(find.text('上次备份：06-19 21:37'), findsOneWidget);
    expect(find.text('备份文件包含训练数据，请妥善保存，不要公开分享。'), findsOneWidget);
    expect(find.textContaining('事件 12 条'), findsOneWidget);
    expect(find.text('3 条'), findsOneWidget);
    await tester.ensureVisible(find.text('导出 Vault'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出 Vault'));
    await tester.pump();
    expect(find.text('正在导出 Vault'), findsOneWidget);
    expect(find.text('处理中...'), findsOneWidget);
    expect(find.text('创建并导出'), findsOneWidget);

    vaultCompleter.complete();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('立即同步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即同步'));
    await tester.pump();
    expect(syncCalls, 1);

    await tester.ensureVisible(find.text('创建并导出'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建并导出'));
    await tester.pump();
    expect(find.text('处理中...'), findsOneWidget);

    exportCompleter.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('data management page disables server actions when unconfigured', (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = ValueNotifier<YoursDataManagementSnapshot>(
      const YoursDataManagementSnapshot(
        serverConfigured: false,
        serverStatusError: YoursDataManagementError.text('timeout'),
        pendingSyncCount: 0,
      ),
    );
    addTearDown(snapshot.dispose);
    var syncCalls = 0;

    await tester.pumpWidget(
      _testApp(
        YoursDataManagementPage(
          snapshotListenable: snapshot,
          onExportVault: () async {},
          onImportVaultInbox: () async {},
          onCreateBackup: () async {},
          onExportBackupToICloud: () async {},
          onRestoreBackupFromICloud: () async {},
          onRestoreBackup: () async {},
          onEditServer: () async {},
          onCheckServer: () async {},
          onSyncServer: () async => syncCalls++,
          onCopyServerDiagnostics: () async {},
        ),
        textScale: 1.4,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('连接失败'), findsOneWidget);
    await tester.ensureVisible(find.text('立即同步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即同步'));
    await tester.pump();
    expect(syncCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data management activity status follows current locale', (tester) async {
    final activity = YoursDataManagementActivity.recentVaultExportFailed(
      YoursDataManagementError.raw(Exception('boom')),
    );

    Widget activityText() {
      return Builder(
        builder: (context) => Text(activity.localizedText(context)),
      );
    }

    await tester.pumpWidget(_testApp(activityText(), locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recent Vault export failed: Unknown error'), findsOneWidget);
    expect(find.textContaining('最近导出 Vault 失败'), findsNothing);

    await tester.pumpWidget(_testApp(activityText(), locale: const Locale('ja')));
    await tester.pumpAndSettle();
    expect(find.textContaining('最近の Vault エクスポートに失敗しました'), findsOneWidget);
    expect(find.textContaining('最近导出 Vault 失败'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about yours sheet renders update state matrix', (tester) async {
    final updateService = AppUpdateService(isAndroid: () => true);
    final upToDate = updateService.evaluateAndroidUpdate(
      currentVersion: '1.0.0',
      currentBuild: 10,
      manifest: const AndroidUpdateManifest(
        latestVersion: '1.0.0',
        latestBuild: 10,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: ['ok'],
      ),
    );
    final hasUpdate = updateService.evaluateAndroidUpdate(
      currentVersion: '1.0.0',
      currentBuild: 10,
      manifest: const AndroidUpdateManifest(
        latestVersion: '1.1.0',
        latestBuild: 11,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: ['new'],
      ),
    );
    var checkCalls = 0;

    for (final state in <AppUpdateState>[
      const AppUpdateState.idle(),
      const AppUpdateState.checking(),
      upToDate,
      hasUpdate,
      const AppUpdateState.failed('network'),
    ]) {
      await tester.pumpWidget(
        _testApp(
          YoursAboutSheet(
            officialWebsiteUrl: 'https://yours-app.uk',
            githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
            showUpdateCheck: true,
            updateState: state,
            onCheckUpdate: () async => checkCalls++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('关于有思（Yours）'), findsOneWidget);
      expect(find.text('官网'), findsOneWidget);
      expect(find.text('GitHub 仓库'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      _testApp(
        YoursAboutSheet(
          officialWebsiteUrl: 'https://yours-app.uk',
          githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
          showUpdateCheck: true,
          updateState: const AppUpdateState.idle(),
          onCheckUpdate: () async => checkCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('检查 Android APK 新版本'), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await tester.pump();
    expect(checkCalls, 1);

    await tester.pumpWidget(
      _testApp(
        YoursAboutSheet(
          officialWebsiteUrl: 'https://yours-app.uk',
          githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
          showUpdateCheck: true,
          updateState: const AppUpdateState.checking(),
          onCheckUpdate: () async => checkCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('正在检查...'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        YoursAboutSheet(
          officialWebsiteUrl: 'https://yours-app.uk',
          githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
          showUpdateCheck: true,
          updateState: upToDate,
          onCheckUpdate: () async => checkCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('当前已是最新版本'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        YoursAboutSheet(
          officialWebsiteUrl: 'https://yours-app.uk',
          githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
          showUpdateCheck: true,
          updateState: hasUpdate,
          onCheckUpdate: () async => checkCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('发现新版本 1.1.0，去官网下载'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        YoursAboutSheet(
          officialWebsiteUrl: 'https://yours-app.uk',
          githubRepositoryUrl: 'https://github.com/Maqiaogongmin/yours-app',
          showUpdateCheck: true,
          updateState: const AppUpdateState.failed('network'),
          onCheckUpdate: () async => checkCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂时无法检查更新'), findsOneWidget);
  });

  testWidgets('entry pages fit 280 width at 1.4 text scale', (tester) async {
    tester.view.physicalSize = const Size(280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);
    final planRepository = _NoSeedTrainingRepository(trainingDb);
    final exerciseRepository = _NoSeedExerciseRepository(exerciseDb);
    await planRepository.savePlan(
      LocalTrainingPlanModel(name: '非常长的训练计划标题 Long training plan title'),
    );
    await exerciseRepository.saveExercise(
      CustomExerciseModel(
        chineseName: '非常长的动作名称 Long exercise title',
        bodyPart: '脚・下半身トレーニング',
        equipment: '自重训练',
        primaryMuscles: '全身',
        description: '用于检查响应式布局的长说明文字',
      ),
    );

    for (final page in <Widget>[
      PlanPage(repository: planRepository),
      ExerciseLibraryPage(repository: exerciseRepository),
      SettingsPage(onAbout: () {}),
    ]) {
      await tester.pumpWidget(_testApp(page, textScale: 1.4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('plan edit and day edit flow fit dark 280 width at 1.4 text scale', (tester) async {
    tester.view.physicalSize = const Size(280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plan = LocalTrainingPlanModel(
      name: '非常长的计划编辑标题 Long plan edit title',
      totalWeeks: 2,
      daysPerWeek: 3,
    );
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '非常长的训练日名称 Long day name',
      actions: [
        LocalTrainingActionModel(
          name: '深蹲',
          targetSets: 5,
          targetReps: 12,
          targetWeight: 120,
          targetRestSeconds: 90,
          note: '这是一段很长的动作备注，用于验证动作参数和备注在深色窄屏下不会溢出。',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(PlanEditPage(plan: plan), theme: yoursDarkTheme, textScale: 1.4),
    );
    await tester.pumpAndSettle();
    expect(find.text('非常长的计划编辑标题 Long plan edit title'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('非常长的训练日名称 Long day name'));
    await tester.pumpAndSettle();
    expect(find.textContaining('深蹲'), findsWidgets);
    expect(find.textContaining('动作备注'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan edit returns saved changes and cancel keeps null result', (tester) async {
    final plan = LocalTrainingPlanModel(name: '原计划', totalWeeks: 2, daysPerWeek: 2);
    LocalTrainingPlanModel? saved;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<LocalTrainingPlanModel>(
                MaterialPageRoute(builder: (_) => PlanEditPage(plan: plan.deepCopy())),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '新计划名称');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.enterText(find.byType(TextField).at(2), '4');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(saved?.name, '新计划名称');
    expect(saved?.totalWeeks, 3);
    expect(saved?.daysPerWeek, 4);

    saved = null;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day edit returns updated action target parameters', (tester) async {
    final day = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(
          name: '深蹲',
          targetSets: 3,
          targetReps: 8,
          targetWeight: 80,
          targetRestSeconds: 60,
          note: '旧备注',
        ),
      ],
    );
    LocalTrainingDayModel? saved;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<LocalTrainingDayModel>(
                MaterialPageRoute(
                  builder: (_) => DayEditPage(editDay: day.copyWith(), week: 1, day: 1),
                ),
              );
            },
            child: const Text('open-day'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-day'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '5');
    await tester.enterText(fields.at(1), '12');
    await tester.enterText(fields.at(2), '100.5');
    await tester.enterText(fields.at(3), '90');
    await tester.enterText(fields.at(4), '新动作备注');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final action = saved!.actions.single;
    expect(action.targetSets, 5);
    expect(action.targetReps, 12);
    expect(action.targetWeight, 100.5);
    expect(action.targetRestSeconds, 90);
    expect(action.note, '新动作备注');
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise editor sheet supports long fields in dark small layout', (tester) async {
    tester.view.physicalSize = const Size(280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _NoSeedExerciseRepository(db);

    await tester.pumpWidget(
      _testApp(ExerciseLibraryPage(repository: repository), theme: yoursDarkTheme, textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-add')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '非常长的自定义动作名称 Long custom exercise name');
    await tester.enterText(fields.at(1), '胸・Push category with long label');
    await tester.enterText(fields.at(2), '器械名称很长的分类');
    expect(find.text('保存到本地动作库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise editor requires name and returns edited values', (tester) async {
    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _NoSeedExerciseRepository(db);

    await tester.pumpWidget(_testApp(ExerciseLibraryPage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存到本地动作库'));
    await tester.pumpAndSettle();
    expect(find.text('保存到本地动作库'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '自定义划船');
    await tester.enterText(fields.at(2), '背部');
    await tester.enterText(fields.at(3), '哑铃');
    await tester.enterText(fields.at(4), '动作说明');
    await tester.tap(find.text('保存到本地动作库'));
    await tester.pumpAndSettle();

    final saved = await repository.listExercises();
    expect(saved.single.chineseName, '自定义划船');
    expect(saved.single.bodyPart, '背部');
    expect(saved.single.equipment, '哑铃');
    expect(saved.single.description, '动作说明');
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise editor updates existing exercise values', (tester) async {
    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _NoSeedExerciseRepository(db);
    await repository.saveExercise(
      CustomExerciseModel(
        chineseName: '旧动作',
        bodyPart: '旧分类',
        equipment: '旧器械',
        primaryMuscles: '背部',
        description: '旧说明',
      ),
    );

    await tester.pumpWidget(_testApp(ExerciseLibraryPage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('旧动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '新动作');
    await tester.enterText(fields.at(2), '新分类');
    await tester.enterText(fields.at(3), '新器械');
    await tester.enterText(fields.at(4), '新说明');
    await tester.tap(find.text('保存到本地动作库'));
    await tester.pumpAndSettle();

    final saved = await repository.listExercises();
    expect(saved.single.chineseName, '新动作');
    expect(saved.single.bodyPart, '新分类');
    expect(saved.single.equipment, '新器械');
    expect(saved.single.description, '新说明');
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(
  Widget home, {
  double textScale = 1,
  ThemeData? theme,
  Locale locale = const Locale('zh'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? yoursLightTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: home),
    ),
  );
}

class _NoSeedTrainingRepository extends LocalTrainingRepository {
  _NoSeedTrainingRepository(super.database);

  @override
  Future<void> ensureSeedData() async {}

  @override
  Stream<List<LocalTrainingPlanModel>> watchPlans({bool? archived}) {
    return Stream.fromFuture(
      getPlans().then(
        (plans) =>
            archived == null ? plans : plans.where((plan) => plan.archived == archived).toList(),
      ),
    );
  }
}

class _NoSeedExerciseRepository extends CustomExerciseRepository {
  _NoSeedExerciseRepository(super.database);

  @override
  Future<void> ensureSeedData() async {}
}

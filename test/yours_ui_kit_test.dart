import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/theme/theme.dart';

void main() {
  for (final theme in [yoursLightTheme, yoursDarkTheme]) {
    final themeName = theme.brightness.name;

    testWidgets('Yours UI Kit handles long labels on small screens in $themeName', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(280, 600),
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      YoursPageHeader(
                        title: '训练记录',
                        subtitle: 'iCloud Driveから復元しながら本地优先记录',
                      ),
                      YoursMetricTile(
                        label: '本项用时 / Duration',
                        value: '00:08:30',
                      ),
                      SizedBox(height: 8),
                      YoursStatusPill(label: '未完成训练记录', tone: YoursTone.danger),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(YoursMetricTile), findsOneWidget);
      expect(find.byType(YoursStatusPill), findsOneWidget);
    });
  }

  testWidgets('YoursTimeValue keeps compact editable time fields', (tester) async {
    final hour = TextEditingController(text: '00');
    final minute = TextEditingController(text: '08');
    final second = TextEditingController(text: '30');
    addTearDown(hour.dispose);
    addTearDown(minute.dispose);
    addTearDown(second.dispose);

    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: Center(
            child: YoursTimeValue(
              keyPrefix: 'duration',
              hourController: hour,
              minuteController: minute,
              secondController: second,
              onChanged: () => changes++,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('duration-hours'))).width, lessThan(40));
    await tester.enterText(find.byKey(const ValueKey('duration-minutes')), '09');
    expect(changes, greaterThan(0));
    expect(minute.text, '09');
  });

  testWidgets('YoursTimeValue supports body typography for form values', (tester) async {
    final hour = TextEditingController(text: '00');
    final minute = TextEditingController(text: '08');
    addTearDown(hour.dispose);
    addTearDown(minute.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: YoursTimeValue(
            keyPrefix: 'form-duration',
            hourController: hour,
            minuteController: minute,
            onChanged: () {},
            textRole: YoursTextRole.body,
          ),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('form-duration-hours')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.style.fontSize, 14);
    expect(editable.style.fontFamily, 'Roboto');
  });

  testWidgets('YoursInlineFormValueSlot centers compact values in the shared value lane', (
    tester,
  ) async {
    final hour = TextEditingController(text: '00');
    final minute = TextEditingController(text: '08');
    final second = TextEditingController(text: '30');
    addTearDown(hour.dispose);
    addTearDown(minute.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1200,
              child: YoursInlineFormRow(
                label: '本项用时',
                fieldWidthFactor: 0.5,
                field: YoursInlineFormValueSlot(
                  key: const ValueKey('duration-value-lane'),
                  alignment: Alignment.center,
                  child: YoursTimeValue(
                    keyPrefix: 'wide-duration',
                    hourController: hour,
                    minuteController: minute,
                    secondController: second,
                    onChanged: () {},
                    textRole: YoursTextRole.body,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final hourCenter = tester.getCenter(find.byKey(const ValueKey('wide-duration-hours')));
    final secondCenter = tester.getCenter(find.byKey(const ValueKey('wide-duration-seconds')));
    final valueSlotRect = tester.getRect(find.byKey(const ValueKey('duration-value-lane')));
    final expectedLaneCenter = valueSlotRect.right - (valueSlotRect.width * 0.74 / 2);
    expect((hourCenter.dx + secondCenter.dx) / 2, closeTo(expectedLaneCenter, 1));
  });

  testWidgets('Yours actions expose primary and danger states', (tester) async {
    var primaryTapped = false;
    var tonalTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: Column(
            children: [
              YoursPrimaryAction(
                label: '保存训练记录',
                onPressed: () => primaryTapped = true,
              ),
              const YoursDangerAction(label: '撤销上一组', onPressed: null),
              YoursTonalAction(
                label: '保存到照片',
                icon: Icons.file_download_outlined,
                onPressed: () => tonalTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('保存训练记录'));
    expect(primaryTapped, isTrue);
    await tester.tap(find.text('保存到照片'));
    expect(tonalTapped, isTrue);
    final tonalButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('保存到照片'), matching: find.byType(TextButton)),
    );
    final tonalBg = tonalButton.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(tonalBg, isNot(const Color(0xFFD86F32)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('YoursAsyncStatusPanel compact grid keeps two-column summary density', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursDarkTheme,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(393, 852)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: YoursAsyncStatusPanel(
                  title: '本地数据安全',
                  layout: YoursStatusPanelLayout.compactGrid,
                  items: [
                    ('备份包', '已有', YoursTone.accent),
                    ('手动导出', '文件', YoursTone.accent),
                    ('待同步', '16 条', YoursTone.warning),
                    ('服务器', '未配置', YoursTone.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final backupTop = tester.getTopLeft(find.text('备份包')).dy;
    final exportTop = tester.getTopLeft(find.text('手动导出')).dy;
    final pendingTop = tester.getTopLeft(find.text('待同步')).dy;
    final serverTop = tester.getTopLeft(find.text('服务器')).dy;

    expect((backupTop - exportTop).abs(), lessThan(1));
    expect((pendingTop - serverTop).abs(), lessThan(1));
    expect(pendingTop, greaterThan(backupTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('YoursAsyncStatusPanel stacks compact grid when text is enlarged', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursDarkTheme,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(320, 852), textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: YoursAsyncStatusPanel(
                  title: '本地数据安全',
                  layout: YoursStatusPanelLayout.compactGrid,
                  items: [
                    ('备份包', '已有', YoursTone.accent),
                    ('手动导出', '文件', YoursTone.accent),
                    ('待同步', '16 条', YoursTone.warning),
                    ('服务器', '未配置', YoursTone.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('手动导出')).dy,
      greaterThan(tester.getTopLeft(find.text('备份包')).dy),
    );
    expect(
      tester.getTopLeft(find.text('待同步')).dy,
      greaterThan(tester.getTopLeft(find.text('手动导出')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('YoursManagementAction compact density reduces button height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: Column(
            children: const [
              YoursManagementAction(
                key: ValueKey('regular-action'),
                icon: Icons.sync_outlined,
                label: '立即同步',
                onTap: null,
              ),
              YoursManagementAction(
                key: ValueKey('compact-action'),
                icon: Icons.sync_outlined,
                label: '立即同步',
                density: YoursComponentDensity.compact,
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );

    final regularHeight = tester.getSize(find.byKey(const ValueKey('regular-action'))).height;
    final compactHeight = tester.getSize(find.byKey(const ValueKey('compact-action'))).height;
    expect(compactHeight, lessThan(regularHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('control overlay keeps a subdued light-mode surface', (tester) async {
    late Color overlay;
    late Color card;
    late Color fg;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Builder(
          builder: (context) {
            overlay = context.yoursSurface(YoursSurfaceRole.controlOverlay);
            card = context.yoursSurface(YoursSurfaceRole.card);
            fg = context.yoursSurfaceForeground(YoursSurfaceRole.controlOverlay);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(overlay, isNot(card));
    expect(overlay.computeLuminance(), greaterThan(0.65));
    expect(fg.computeLuminance(), lessThan(0.12));
  });

  testWidgets('YoursActionGroup wraps three management actions before labels are squeezed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(430, 932)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: YoursActionGroup(
                  children: [
                    YoursManagementAction(
                      icon: Icons.cloud_upload_outlined,
                      label: '导出备份',
                      density: YoursComponentDensity.compact,
                      onTap: null,
                    ),
                    YoursManagementAction(
                      icon: Icons.folder_copy_outlined,
                      label: '导出 Vault',
                      density: YoursComponentDensity.compact,
                      onTap: null,
                    ),
                    YoursManagementAction(
                      icon: Icons.file_open_outlined,
                      label: '从 iCloud 恢复',
                      density: YoursComponentDensity.compact,
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('从 iCloud 恢复')).dy,
      greaterThan(tester.getTopLeft(find.text('导出备份')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Yours second batch components handle dense localized content', (tester) async {
    final searchController = TextEditingController(text: 'スクワット');
    addTearDown(searchController.dispose);

    var selectedChip = '全部';
    var selectedSegment = false;
    var searchChanges = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 720),
            textScaler: TextScaler.linear(1.4),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SafeArea(
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        YoursSearchField(
                          controller: searchController,
                          hintText: '搜索动作 / Search exercises',
                          onChanged: () => setState(() => searchChanges++),
                        ),
                        const SizedBox(height: 8),
                        YoursFilterChipBar<String>(
                          items: const ['全部', 'Chest and upper push', '脚・下半身トレーニング'],
                          selected: selectedChip,
                          labelBuilder: (item) => item,
                          onChanged: (item) => setState(() => selectedChip = item),
                        ),
                        const SizedBox(height: 8),
                        YoursSegmentedFilter<bool>(
                          segments: const [(false, '启用中'), (true, 'Archived plans')],
                          selected: selectedSegment,
                          onChanged: (value) => setState(() => selectedSegment = value),
                        ),
                        const SizedBox(height: 8),
                        YoursListActionCard(
                          leading: const YoursIconBadge(icon: Icons.fitness_center_outlined),
                          title: '非常长的训练计划标题 Long training plan title',
                          subtitle: '第 1 周 · D1 · 这是很长的说明文字，用来验证不会溢出',
                          status: const YoursStatusPill(label: '同步等待中'),
                          detail: '12 actions',
                          onTap: () {},
                        ),
                        const SizedBox(height: 8),
                        const YoursEmptyState(message: '没有找到匹配的动作 No matching exercises'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(YoursSearchField), findsOneWidget);
    expect(find.byType(YoursFilterChipBar<String>), findsOneWidget);
    expect(find.byType(YoursSegmentedFilter<bool>), findsOneWidget);
    expect(find.byType(YoursListActionCard), findsOneWidget);
    expect(find.byType(YoursEmptyState), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(-220, 0));
    await tester.pump();
    await tester.tap(find.text('脚・下半身トレーニング'));
    await tester.pump();
    expect(selectedChip, '脚・下半身トレーニング');

    await tester.tap(find.text('Archived plans'));
    await tester.pump();
    expect(selectedSegment, isTrue);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(searchController.text, isEmpty);
    expect(searchChanges, greaterThan(0));
  });

  testWidgets('Yours list and empty states expose disabled, busy, and action states', (
    tester,
  ) async {
    var cardTaps = 0;
    var emptyActionTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursLightTheme,
        home: Scaffold(
          body: Column(
            children: [
              YoursListActionCard(
                title: 'Disabled',
                enabled: false,
                onTap: () => cardTaps++,
              ),
              YoursListActionCard(
                title: 'Busy',
                busy: true,
                onTap: () => cardTaps++,
              ),
              YoursEmptyState(
                message: 'Nothing here',
                icon: Icons.inbox_outlined,
                actionLabel: 'Create',
                onAction: () => emptyActionTaps++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Disabled'));
    await tester.tap(find.text('Busy'));
    expect(cardTaps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Create'));
    expect(emptyActionTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Yours shareability prep components handle states and long text', (tester) async {
    var actionTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: yoursDarkTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 760),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: SafeArea(
              child: SizedBox(
                width: 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      YoursRecordCardPattern(
                        title: '六月十六日 · 非常长的训练记录标题 Long workout record title',
                        subtitle: '本地优先记录',
                        status: const YoursStatusPill(label: '未完成', tone: YoursTone.danger),
                        metrics: const [
                          YoursStatBlock(label: '总容量 Volume', value: '12000kg'),
                          YoursStatBlock(label: '有效组数', value: '18'),
                          YoursStatBlock(label: '训练分钟', value: '75'),
                        ],
                        note: '这是一段很长的训练备注，用来确认分享前置卡片语义在深色、小屏和字体放大时不会溢出。',
                      ),
                      const SizedBox(height: 8),
                      YoursSummaryCard(
                        title: '训练完成总结 Long summary title',
                        subtitle: '第 1 周 · D1',
                        metrics: const [
                          YoursStatBlock(label: '动作', value: '5'),
                          YoursStatBlock(label: '组数', value: '18'),
                        ],
                        actions: [
                          YoursManagementAction(
                            icon: Icons.sync_outlined,
                            label: '立即同步',
                            detail: '同步本地等待队列',
                            onTap: () => actionTaps++,
                          ),
                          const YoursManagementAction(
                            icon: Icons.delete_outline,
                            label: '危险恢复操作',
                            tone: YoursTone.danger,
                            enabled: false,
                            onTap: null,
                          ),
                          const YoursManagementAction(
                            icon: Icons.hourglass_top_rounded,
                            label: '处理中',
                            busy: true,
                            onTap: null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(YoursRecordCardPattern), findsOneWidget);
    expect(find.byType(YoursSummaryCard), findsOneWidget);
    expect(find.byType(YoursManagementAction), findsNWidgets(3));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.scrollUntilVisible(find.text('立即同步'), 120);
    await tester.tap(find.text('立即同步'));
    expect(actionTaps, 1);
  });
}

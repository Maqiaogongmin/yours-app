/// Main shell — pure 4-tab bottom nav. No top bar. No floating gear.
///
/// Page content fills the screen. Gear icon is managed by each page individually.
/// Only the home page shows a gear (embedded in "今日状态" header).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yours/redesign/data/app_update_service.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/redesign_data_refresh.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/navigation/tab_item.dart';
import 'package:yours/redesign/pages/exercises/exercise_library_page.dart';
import 'package:yours/redesign/pages/home/home_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_mode_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';
import 'package:yours/redesign/pages/plan/plan_page.dart';
import 'package:yours/redesign/pages/profile/profile_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const int _screenshotInitialTab = int.fromEnvironment(
    'YOURS_SCREENSHOT_TAB',
    defaultValue: 0,
  );
  final BackupService _backupService = BackupService();
  final AppUpdateService _appUpdateService = AppUpdateService.instance;
  int _selectedIndex = _screenshotInitialTab < 0
      ? 0
      : (_screenshotInitialTab > 3 ? 3 : _screenshotInitialTab);
  int _dataRevision = 0;
  bool _autoBackupRunning = false;
  bool _autoServerSyncRunning = false;
  DateTime? _lastAutoServerSyncAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RedesignDataRefresh.instance.revision.addListener(_handleDataRefresh);
    _createDailyBackupIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAutomaticServerSync(reason: 'app_open'));
    });
    unawaited(_appUpdateService.checkForUpdates(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RedesignDataRefresh.instance.revision.removeListener(_handleDataRefresh);
    super.dispose();
  }

  void _handleDataRefresh() {
    if (!mounted) {
      return;
    }
    setState(() {
      _dataRevision = RedesignDataRefresh.instance.revision.value;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _createBackgroundBackupIfNeeded();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_runAutomaticServerSync(reason: 'app_resumed'));
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _createDailyBackupIfNeeded() async {
    await _createAutomaticBackupIfNeeded(reason: 'daily_open', daily: true);
  }

  Future<void> _createBackgroundBackupIfNeeded() async {
    await _createAutomaticBackupIfNeeded(reason: 'app_background', daily: true);
  }

  Future<void> _createAutomaticBackupIfNeeded({
    required String reason,
    required bool daily,
  }) async {
    if (_autoBackupRunning) {
      return;
    }
    _autoBackupRunning = true;
    try {
      await _backupService.createAutomaticBackupIfNeeded(reason: reason, daily: daily);
      await _runAutomaticServerSync(reason: 'after_$reason');
    } on Object {
      // 自动备份不能打断正常使用；失败信息仍可在手动备份/恢复时暴露。
    } finally {
      _autoBackupRunning = false;
    }
  }

  Future<void> _runAutomaticServerSync({required String reason}) async {
    if (_autoServerSyncRunning) {
      return;
    }
    final now = DateTime.now();
    final last = _lastAutoServerSyncAt;
    if (last != null && now.difference(last) < const Duration(minutes: 5)) {
      return;
    }
    _autoServerSyncRunning = true;
    try {
      final settings = await _backupService.loadServerBackupSettings();
      if (!settings.isConfigured) {
        return;
      }
      _lastAutoServerSyncAt = now;
      final result = await _backupService.syncNowWithServer();
      final sync = result.sync;
      if (result.state == ServerSmartSyncState.synced &&
          sync != null &&
          sync.appliedEventCount > 0) {
        RedesignDataRefresh.instance.notifyRestored();
      }
    } on Object {
      // 自动同步不能打断正常使用；手动“立即同步”会显示具体错误。
    } finally {
      _autoServerSyncRunning = false;
    }
  }

  void _openActiveWorkout() {
    final session = LocalGymSessionController.instance;
    final plan = session.plan;
    if (plan == null || !session.isActive) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalGymModePage(plan: plan, day: session.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useTabletShell = width >= 760;
    final palette = context.yoursPalette;
    final pages = IndexedStack(
      index: _selectedIndex,
      children: [
        HomePage(key: ValueKey('home-$_dataRevision')),
        PlanPage(key: ValueKey('plan-$_dataRevision')),
        ExerciseLibraryPage(key: ValueKey('exercise-$_dataRevision')),
        const ProfilePage(),
      ],
    );

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            if (useTabletShell)
              Row(
                children: [
                  _SideNavRail(selectedIndex: _selectedIndex, onTap: _onTabTapped),
                  Expanded(child: pages),
                ],
              )
            else
              pages,
            _ActiveWorkoutBubble(onTap: _openActiveWorkout),
          ],
        ),
      ),
      bottomNavigationBar: useTabletShell
          ? null
          : _BottomNavBar(
              selectedIndex: _selectedIndex,
              onTap: _onTabTapped,
            ),
    );
  }
}

class _SideNavRail extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _SideNavRail({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final surface = palette.surface;
    final border = palette.border;
    final fg = palette.fg;
    final muted = palette.muted;
    const items = TabItem.values;

    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      child: Column(
        children: [
          Tooltip(
            message: context.l10n.appName,
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.accent.withValues(alpha: 0.24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: palette.brightness == Brightness.light ? 0.08 : 0.28,
                    ),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  'assets/images/yours-icon-512.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (final entry in items.asMap().entries) ...[
            _SideNavItem(
              item: entry.value,
              selected: entry.key == selectedIndex,
              fg: fg,
              muted: muted,
              palette: palette,
              onTap: () => onTap(entry.key),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final TabItem item;
  final bool selected;
  final Color fg;
  final Color muted;
  final YoursPalette palette;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.selected,
    required this.fg,
    required this.muted,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label(context.l10n),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? Border.all(color: palette.accent.withValues(alpha: 0.18))
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              YoursTabIcon(
                asset: item.iconAsset,
                color: selected ? palette.accent : muted,
                size: 25,
              ),
              const SizedBox(height: 6),
              Text(
                item.label(context.l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? fg : muted,
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveWorkoutBubble extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveWorkoutBubble({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final session = LocalGymSessionController.instance;
    final palette = context.yoursPalette;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.isActive || session.plan == null) {
          return const SizedBox.shrink();
        }
        return Positioned(
          right: 18,
          bottom: 18,
          child: SafeArea(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      offset: const Offset(0, 8),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      _elapsedText(session.elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _elapsedText(Duration elapsed) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = elapsed.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = TabItem.values;
    final palette = context.yoursPalette;
    final surface = palette.surface;
    final border = palette.border;
    final muted = palette.muted;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.5)),
        color: surface,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 6,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isSelected = i == selectedIndex;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? palette.accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: YoursTabIcon(
                      asset: item.iconAsset,
                      color: isSelected ? palette.accent : muted,
                      size: 23,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label(context.l10n),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? palette.accent : muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class YoursTabIcon extends StatelessWidget {
  final String asset;
  final Color color;
  final double size;

  const YoursTabIcon({
    super.key,
    required this.asset,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

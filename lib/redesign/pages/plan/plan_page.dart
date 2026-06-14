/// Plan page — uniform card sizing, swipe-to-reveal delete, grid day cells.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/pages/plan/exercise_picker_page.dart';
import 'package:yours/redesign/pages/plan/local_gym_mode_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

typedef TrainingDay = LocalTrainingDayModel;
typedef AppPlan = LocalTrainingPlanModel;

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Page
// ═══════════════════════════════════════════════════════════════════════════════

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final LocalTrainingRepository _repository;
  late final Future<void> _initFuture;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _repository = LocalTrainingRepository(locator<LocalTrainingDatabase>());
    _initFuture = _repository.ensureSeedData();
  }

  void _editPlan(AppPlan source) async {
    final plan = source.deepCopy();
    final result = await Navigator.of(context).push<AppPlan>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlanEditPage(plan: plan),
      ),
    );
    if (result != null && mounted) {
      try {
        await _repository.savePlan(result);
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
  }

  void _createPlan() async {
    final plan = AppPlan(name: context.l10n.planNewName, totalWeeks: 4, daysPerWeek: 4);
    final result = await Navigator.of(context).push<AppPlan>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlanEditPage(plan: plan),
      ),
    );
    if (result != null && mounted) {
      try {
        await _repository.savePlan(result);
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
  }

  Future<bool> _deletePlan(AppPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.planDeleteTitle),
        content: Text(context.l10n.planDeleteMessage(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(
              context.l10n.commonDelete,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && plan.id != null) {
      try {
        await _repository.deletePlan(plan.id!);
        return true;
      } on Object catch (error) {
        _showLocalSaveError(error);
      }
    }
    return false;
  }

  Future<void> _setPlanArchived(AppPlan plan, bool archived) async {
    if (plan.id == null) {
      return;
    }
    try {
      await _repository.setPlanArchived(plan.id!, archived);
    } on Object catch (error) {
      _showLocalSaveError(error);
    }
  }

  void _showLocalSaveError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.planLocalSaveFailed(localizedErrorDetail(context, error)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPlanDetail(AppPlan plan) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailPage(plan: plan.deepCopy()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (initSnapshot.hasError) {
          return _hint(
            context.l10n.planDatabaseInitFailed(
              localizedErrorDetail(context, initSnapshot.error!),
            ),
          );
        }

        return StreamBuilder<List<AppPlan>>(
          stream: _repository.watchPlans(archived: _showArchived),
          builder: (context, snapshot) {
            final plans = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.planTitle,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: palette.fg,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              plans.isEmpty
                                  ? context.l10n.planNone
                                  : context.l10n.planCount(plans.length),
                              style: TextStyle(fontSize: 14, color: palette.muted),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _createPlan,
                          child: Text(
                            context.l10n.planCreate,
                            style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SegmentedButton<bool>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return palette.accentSoft;
                          }
                          return palette.surface;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return palette.accent;
                          }
                          return palette.fg;
                        }),
                        iconColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return palette.accent;
                          }
                          return palette.muted;
                        }),
                        side: WidgetStateProperty.resolveWith((states) {
                          final color = states.contains(WidgetState.selected)
                              ? palette.accent
                              : palette.border;
                          return BorderSide(color: color, width: 1.2);
                        }),
                      ),
                      segments: [
                        ButtonSegment(value: false, label: Text(context.l10n.planActive)),
                        ButtonSegment(value: true, label: Text(context.l10n.planArchived)),
                      ],
                      selected: {_showArchived},
                      onSelectionChanged: (selection) {
                        setState(() => _showArchived = selection.first);
                      },
                    ),
                  ),

                  if (plans.isEmpty)
                    _hint(_showArchived ? context.l10n.planNoArchived : context.l10n.planNoActive)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        context.l10n.planSwipeHint,
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ),
                  if (plans.isNotEmpty)
                    ...List.generate(plans.length, (i) {
                      final p = plans[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SwipeActionsWrapper(
                          key: ValueKey('plan_${p.id ?? i}'),
                          onEdit: () => _editPlan(p),
                          onDelete: () async => _deletePlan(p),
                          child: GestureDetector(
                            onTap: () => _openPlanDetail(p),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 110),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(kCardRadius),
                                border: Border.all(color: palette.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: palette.fg,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: _showArchived
                                            ? context.l10n.planRestoreActive
                                            : context.l10n.planArchive,
                                        onSelected: (value) {
                                          if (value == 'archive') {
                                            _setPlanArchived(p, true);
                                          } else if (value == 'restore') {
                                            _setPlanArchived(p, false);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: _showArchived ? 'restore' : 'archive',
                                            child: Text(
                                              _showArchived
                                                  ? context.l10n.planRestoreActive
                                                  : context.l10n.planArchive,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.l10n.planSummary(p.totalWeeks, p.daysPerWeek),
                                    style: TextStyle(fontSize: 13, color: palette.muted),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: p.hasFullSchedule
                                          ? palette.success.withValues(alpha: 0.14)
                                          : palette.accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      p.hasFullSchedule
                                          ? context.l10n.planScheduleReady
                                          : context.l10n.planScheduleIncomplete,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: p.hasFullSchedule ? palette.success : palette.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.syncStatus == localSyncPending
                                        ? context.l10n.commonPendingSync
                                        : context.l10n.commonSynced,
                                    style: TextStyle(fontSize: 12, color: palette.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _hint(String text) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
        color: palette.panel,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Swipe-to-Reveal Edit/Delete (custom, no package dependency)
// ═══════════════════════════════════════════════════════════════════════════════

class _SwipeActionsWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  const _SwipeActionsWrapper({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SwipeActionsWrapper> createState() => _SwipeActionsWrapperState();
}

class _SwipeActionsWrapperState extends State<_SwipeActionsWrapper> {
  double _slideOffset = 0;
  bool _revealed = false;
  static const double _actionWidth = 160;
  double _dragStartOffset = 0;
  Offset? _pointerStart;
  bool _trackingHorizontalDrag = false;

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartOffset = _slideOffset;
    _pointerStart = event.position;
    _trackingHorizontalDrag = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final pointerStart = _pointerStart;
    if (pointerStart == null) {
      return;
    }

    final distance = event.position - pointerStart;
    if (!_trackingHorizontalDrag) {
      final isHorizontalDrag = distance.dx.abs() > 4 && distance.dx.abs() > distance.dy.abs();
      if (!isHorizontalDrag) {
        return;
      }
      _trackingHorizontalDrag = true;
    }

    setState(() {
      _slideOffset = (_dragStartOffset + distance.dx).clamp(-_actionWidth, 0);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_trackingHorizontalDrag) {
      _pointerStart = null;
      return;
    }

    final shouldReveal = _slideOffset < -_actionWidth * 0.5;

    setState(() {
      _revealed = shouldReveal;
      _slideOffset = shouldReveal ? -_actionWidth : 0;
    });
    _pointerStart = null;
    _trackingHorizontalDrag = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerStart = null;
    _trackingHorizontalDrag = false;
  }

  void _hideActions() {
    if (!_revealed && _slideOffset == 0) {
      return;
    }
    setState(() {
      _slideOffset = 0;
      _revealed = false;
    });
  }

  void _handleEditTap() {
    _hideActions();
    widget.onEdit();
  }

  Future<void> _handleDeleteTap() async {
    final deleted = await widget.onDelete();
    if (mounted && !deleted) {
      _hideActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background action strip. A foreground copy below owns taps after reveal,
              // because transformed cards can still win hit testing on the exposed area.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: _actionWidth,
                  child: _ActionButtons(onEdit: _handleEditTap, onDelete: _handleDeleteTap),
                ),
              ),
              // Card — tapping a revealed card closes it before start can fire again.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _revealed ? _hideActions : null,
                child: Transform.translate(
                  offset: Offset(_slideOffset, 0),
                  child: AbsorbPointer(
                    absorbing: _revealed,
                    child: card,
                  ),
                ),
              ),
              if (_revealed)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: _actionWidth,
                    child: _ActionButtons(onEdit: _handleEditTap, onDelete: _handleDeleteTap),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _ActionButtons({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: ColoredBox(
              color: kAccent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.commonEdit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: ColoredBox(
              color: kRed,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.commonDelete,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Detail Page — select week/day before entering Gym Mode
// ═══════════════════════════════════════════════════════════════════════════════

class PlanDetailPage extends StatefulWidget {
  final AppPlan plan;

  const PlanDetailPage({super.key, required this.plan});

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  late final LocalTrainingRepository _repository;
  late AppPlan _plan;
  final Set<int> _collapsedWeeks = <int>{};

  @override
  void initState() {
    super.initState();
    _repository = LocalTrainingRepository(locator<LocalTrainingDatabase>());
    _plan = widget.plan.deepCopy();
    _loadCollapsedWeeks();
  }

  String get _foldPreferencePrefix =>
      'yours_plan_week_fold_${_plan.syncId ?? _plan.id ?? 'draft'}_';

  Future<void> _loadCollapsedWeeks() async {
    final prefs = SharedPreferencesAsync();
    final collapsed = <int>{};
    for (var week = 1; week <= _plan.totalWeeks; week++) {
      if (await prefs.getBool('$_foldPreferencePrefix$week') ?? false) {
        collapsed.add(week);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _collapsedWeeks
        ..clear()
        ..addAll(collapsed);
    });
  }

  Future<void> _toggleWeekFold(int week) async {
    final collapsed = !_collapsedWeeks.contains(week);
    setState(() {
      if (collapsed) {
        _collapsedWeeks.add(week);
      } else {
        _collapsedWeeks.remove(week);
      }
    });
    await SharedPreferencesAsync().setBool('$_foldPreferencePrefix$week', collapsed);
  }

  Future<void> _toggleWeekCompleted(int week) async {
    if (_plan.id == null) {
      return;
    }
    try {
      final completedWeeks = await _repository.toggleCompletedWeek(_plan.id!, week);
      if (!mounted) {
        return;
      }
      setState(() => _plan.completedWeeks = completedWeeks);
    } on Object catch (error) {
      _showLocalSaveError(error);
    }
  }

  Future<void> _restoreArchivedPlan() async {
    if (_plan.id == null) {
      return;
    }
    try {
      await _repository.setPlanArchived(_plan.id!, false);
      if (!mounted) {
        return;
      }
      setState(() => _plan.archived = false);
    } on Object catch (error) {
      _showLocalSaveError(error);
    }
  }

  Future<void> _startDay(BuildContext context, TrainingDay day) async {
    if (day.actions.isEmpty) {
      return;
    }
    final navigator = Navigator.of(context);
    if (_plan.archived) {
      final restore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.planRestoreArchivedTitle),
          content: Text(context.l10n.planRestoreArchivedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.planRestoreActive),
            ),
          ],
        ),
      );
      if (restore != true || !mounted) {
        return;
      }
      await _restoreArchivedPlan();
      if (!mounted || _plan.archived) {
        return;
      }
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => LocalGymModePage(
          plan: _plan.deepCopy(),
          day: day.copyWith(),
        ),
      ),
    );
  }

  void _openDayEdit(BuildContext context, TrainingDay day) async {
    final key = '${day.week}-${day.day}';
    final dayData = _plan.days.containsKey(key) ? _plan.days[key]!.copyWith() : day.copyWith();

    final result = await Navigator.of(context).push<TrainingDay>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DayEditPage(
          editDay: dayData,
          week: day.week,
          day: day.day,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final updatedPlan = _plan.deepCopy();
    updatedPlan.days[key] = result;

    try {
      await _repository.savePlan(updatedPlan);
    } on Object catch (error) {
      _showLocalSaveError(error);
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _plan = updatedPlan);
  }

  void _showLocalSaveError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.planLocalSaveFailed(localizedErrorDetail(context, error)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.planDaySelection,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(kGutter, 16, kGutter, 28),
        children: [
          _summaryCard(),
          const SizedBox(height: 14),
          ...List.generate(_plan.totalWeeks, (wi) {
            final week = wi + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _weekBlock(context, week),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final palette = context.yoursPalette;
    final scheduledDays = _plan.days.values.where((day) => day.actions.isNotEmpty).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _plan.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.planScheduledDays(
              context.l10n.planSummary(_plan.totalWeeks, _plan.daysPerWeek),
              scheduledDays,
            ),
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
        ],
      ),
    );
  }

  Widget _weekBlock(BuildContext context, int week) {
    final palette = context.yoursPalette;
    final collapsed = _collapsedWeeks.contains(week);
    final completed = _plan.completedWeeks.contains(week);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleWeekFold(week),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.planWeek(week),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.fg,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: completed
                        ? context.l10n.planUnmarkWeekComplete
                        : context.l10n.planMarkWeekComplete,
                    onPressed: () => _toggleWeekCompleted(week),
                    icon: Icon(
                      completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: completed ? palette.success : palette.muted,
                    ),
                  ),
                  Icon(
                    collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                    color: palette.muted,
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 10),
            ...List.generate(_plan.daysPerWeek, (di) {
              final dayNumber = di + 1;
              final day =
                  _plan.days['$week-$dayNumber'] ??
                  TrainingDay(week: week, day: dayNumber, name: 'D$dayNumber');
              return Padding(
                padding: EdgeInsets.only(bottom: di == _plan.daysPerWeek - 1 ? 0 : 8),
                child: _dayTile(context, day),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _dayTile(BuildContext context, TrainingDay day) {
    final palette = context.yoursPalette;
    final hasActions = day.actions.isNotEmpty;
    final actionPreview = hasActions
        ? day.actionNames.take(3).map((name) => localizedExerciseName(context, name)).join(' · ')
        : context.l10n.planNoActions;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDayEdit(context, day),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasActions ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'D${day.day}',
                style: TextStyle(
                  color: hasActions ? Colors.white : palette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.fg),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    actionPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (hasActions)
              IconButton(
                onPressed: () => _startDay(context, day),
                icon: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 20),
                ),
                style: IconButton.styleFrom(
                  foregroundColor: palette.bg,
                  fixedSize: const Size(44, 44),
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                color: palette.muted,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Edit Page  (full-screen)
// ═══════════════════════════════════════════════════════════════════════════════

class PlanEditPage extends StatefulWidget {
  final AppPlan plan;
  const PlanEditPage({super.key, required this.plan});

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  late TextEditingController _nameCtrl, _weeksCtrl, _daysCtrl;
  late int _totalWeeks, _daysPerWeek;
  late AppPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _nameCtrl = TextEditingController(text: _plan.name);
    _weeksCtrl = TextEditingController(text: _plan.totalWeeks.toString());
    _daysCtrl = TextEditingController(text: _plan.daysPerWeek.toString());
    _totalWeeks = _plan.totalWeeks;
    _daysPerWeek = _plan.daysPerWeek;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weeksCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  void _onWeeksChanged(String v) {
    final w = int.tryParse(v);
    if (w != null && w >= 1 && w <= 12) {
      setState(() => _totalWeeks = w);
      _plan.totalWeeks = w;
    }
  }

  void _onDaysChanged(String v) {
    final d = int.tryParse(v);
    if (d != null && d >= 1 && d <= 7) {
      setState(() => _daysPerWeek = d);
      _plan.daysPerWeek = d;
    }
  }

  void _openDayEdit(int week, int day) async {
    final key = '$week-$day';
    final dayData = _plan.days.containsKey(key)
        ? _plan.days[key]!.copyWith()
        : TrainingDay(week: week, day: day, name: 'D$day');

    final result = await Navigator.of(context).push<TrainingDay>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DayEditPage(
          editDay: dayData,
          week: week,
          day: day,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _plan.days[key] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.planEditTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _plan.name = _nameCtrl.text;
              Navigator.pop(context, _plan);
            },
            child: Text(
              context.l10n.commonSave,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(kGutter, 16, kGutter, 28),
        children: [
          // Plan name
          _label(context.l10n.planName),
          _field(controller: _nameCtrl, onChanged: (v) => _plan.name = v),
          const SizedBox(height: 14),

          // Weeks + days
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context.l10n.planCycle),
                    _field(
                      controller: _weeksCtrl,
                      number: true,
                      onChanged: _onWeeksChanged,
                      suffix: context.l10n.planWeeksSuffix,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context.l10n.planDaysPerWeek),
                    _field(
                      controller: _daysCtrl,
                      number: true,
                      onChanged: _onDaysChanged,
                      suffix: context.l10n.planDaysSuffix,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── 动作安排 ────────────────────────────────────────
          _label(context.l10n.planArrangement),
          const SizedBox(height: 8),

          ...List.generate(_totalWeeks, (wi) {
            final week = wi + 1;
            return EditableWeekBlock(
              week: week,
              daysPerWeek: _daysPerWeek,
              planDays: _plan.days,
              onDayTap: _openDayEdit,
            );
          }),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.yoursPalette.muted,
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    bool number = false,
    ValueChanged<String>? onChanged,
    String? suffix,
  }) {
    final palette = context.yoursPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: number ? TextInputType.number : null,
              onChanged: onChanged,
              cursorColor: palette.accent,
              style: TextStyle(color: palette.fg),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 13),
              child: Text(suffix, style: TextStyle(fontSize: 13, color: palette.muted)),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Editable Week Block — training day cells in 2-column grid
// ═══════════════════════════════════════════════════════════════════════════════

class EditableWeekBlock extends StatefulWidget {
  final int week, daysPerWeek;
  final Map<String, TrainingDay> planDays;
  final void Function(int, int) onDayTap;

  const EditableWeekBlock({
    super.key,
    required this.week,
    required this.daysPerWeek,
    required this.planDays,
    required this.onDayTap,
  });

  @override
  State<EditableWeekBlock> createState() => _EditableWeekBlockState();
}

class _EditableWeekBlockState extends State<EditableWeekBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header (collapsible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.planWeek(widget.week),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.fg),
                  ),
                  Row(
                    children: [
                      Text(
                        'D1–D${widget.daysPerWeek}',
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: palette.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Day cells in 2-column grid
          if (_expanded) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(
                  (widget.daysPerWeek + 1) ~/ 2,
                  (row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: IntrinsicHeight(
                        child: Row(
                          children: List.generate(2, (col) {
                            final day = row * 2 + col + 1;
                            if (day > widget.daysPerWeek) {
                              return const Expanded(child: SizedBox());
                            }
                            final key = '${widget.week}-$day';
                            final td =
                                widget.planDays[key] ??
                                TrainingDay(week: widget.week, day: day, name: 'D$day');
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => widget.onDayTap(widget.week, day),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: col == 0 ? 5 : 0,
                                    left: col == 1 ? 5 : 0,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: palette.surface,
                                    border: Border.all(color: palette.border),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'D$day',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: palette.accent,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        td.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: palette.fg,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        td.actions.isEmpty ? '—' : td.actionNames.take(2).join('、'),
                                        style: TextStyle(fontSize: 11, color: palette.muted),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Day Edit Page  (full sub-page)
// ═══════════════════════════════════════════════════════════════════════════════

class DayEditPage extends StatefulWidget {
  final TrainingDay editDay;
  final int week, day;

  const DayEditPage({super.key, required this.editDay, required this.week, required this.day});

  @override
  State<DayEditPage> createState() => _DayEditPageState();
}

class _DayEditPageState extends State<DayEditPage> {
  late TextEditingController _nameCtrl;
  late TrainingDay _day;

  @override
  void initState() {
    super.initState();
    _day = widget.editDay.copyWith();
    _nameCtrl = TextEditingController(text: _day.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addAction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExercisePickerPage.multi(selectedActions: _day.actions),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _removeAction(int index) {
    setState(() => _day.actions.removeAt(index));
  }

  void _updateActionTarget(
    int index, {
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    String? recordMode,
    String? note,
  }) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(
        targetSets: sets?.clamp(1, 10),
        targetReps: reps?.clamp(1, 50),
        targetWeight: weight,
        targetRestSeconds: restSeconds?.clamp(0, 3600),
        recordMode: recordMode,
        note: note,
      );
    });
  }

  void _clearActionWeight(int index) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(clearTargetWeight: true);
    });
  }

  void _clearActionRestSeconds(int index) {
    setState(() {
      final action = _day.actions[index];
      _day.actions[index] = action.copyWith(clearTargetRestSeconds: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.planDayTitle(widget.week, widget.day),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _day.name = _nameCtrl.text;
              Navigator.pop(context, _day);
            },
            child: Text(
              context.l10n.commonSave,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kGutter),
        children: [
          _label(context.l10n.planDayName),
          _field(controller: _nameCtrl),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: _filled(context.l10n.planAddExercise, _addAction),
          ),
          const SizedBox(height: 14),

          _label(context.l10n.planActionList(_day.actions.length)),
          const SizedBox(height: 8),

          if (_day.actions.isEmpty)
            _hint(context.l10n.planNoExerciseHint)
          else
            ...List.generate(_day.actions.length, (i) {
              final action = _day.actions[i];
              return Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizedExerciseName(context, action.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: palette.fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _removeAction(i),
                          child: Text(
                            context.l10n.planRemove,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: palette.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: _recordModeSwitch(
                        action.recordMode,
                        (mode) => _updateActionTarget(i, recordMode: mode),
                      ),
                    ),
                    if (action.recordMode != localRecordModeFree) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: _targetInputs(
                          action: action,
                          onSetsChanged: (sets) => _updateActionTarget(i, sets: sets),
                          onRepsChanged: (reps) => _updateActionTarget(i, reps: reps),
                          onWeightChanged: (weight) => _updateActionTarget(i, weight: weight),
                          onWeightCleared: () => _clearActionWeight(i),
                          onRestChanged: (seconds) => _updateActionTarget(i, restSeconds: seconds),
                          onRestCleared: () => _clearActionRestSeconds(i),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actionNoteField(
                      initialValue: action.note,
                      onChanged: (note) => _updateActionTarget(i, note: note),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.yoursPalette.muted,
      ),
    ),
  );

  Widget _field({required TextEditingController controller}) {
    final palette = context.yoursPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
        cursorColor: palette.accent,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        ),
      ),
    );
  }

  Widget _hint(String text) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
        color: palette.panel,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 14),
      ),
    );
  }

  Widget _filled(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: context.yoursPalette.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
  );

  Widget _recordModeSwitch(String mode, ValueChanged<String> onChanged) {
    final palette = context.yoursPalette;
    final normalized = normalizeLocalRecordMode(mode);
    Widget segment(String value, String label) {
      final selected = normalized == value;
      return Expanded(
        child: TextButton(
          onPressed: () => onChanged(value),
          style: TextButton.styleFrom(
            backgroundColor: selected ? palette.accentSoft : Colors.transparent,
            foregroundColor: selected ? palette.accent : palette.muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      );
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          segment(localRecordModeStandard, context.l10n.planRecordModeStandard),
          segment(localRecordModeFree, context.l10n.planRecordModeFree),
        ],
      ),
    );
  }

  Widget _targetInputs({
    required LocalTrainingActionModel action,
    required ValueChanged<int> onSetsChanged,
    required ValueChanged<int> onRepsChanged,
    required ValueChanged<double> onWeightChanged,
    required VoidCallback onWeightCleared,
    required ValueChanged<int> onRestChanged,
    required VoidCallback onRestCleared,
  }) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _targetNumberField(
            initialValue: action.targetSets,
            suffix: context.l10n.planSetSuffix,
            onChanged: onSetsChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text('×', style: TextStyle(fontSize: 13, color: palette.muted)),
          ),
          _targetNumberField(
            initialValue: action.targetReps,
            suffix: context.l10n.planRepSuffix,
            onChanged: onRepsChanged,
          ),
          const SizedBox(width: 5),
          _targetWeightField(
            initialValue: action.targetWeight,
            onChanged: onWeightChanged,
            onCleared: onWeightCleared,
          ),
          const SizedBox(width: 5),
          _targetOptionalIntField(
            initialValue: action.targetRestSeconds,
            hint: context.l10n.planRest,
            suffix: 's',
            width: 58,
            onChanged: onRestChanged,
            onCleared: onRestCleared,
          ),
        ],
      ),
    );
  }

  Widget _targetNumberField({
    required int initialValue,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    final palette = context.yoursPalette;
    return SizedBox(
      width: 50,
      child: TextFormField(
        initialValue: initialValue.toString(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.fg),
        decoration: InputDecoration(
          isDense: true,
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 11, color: palette.muted, fontWeight: FontWeight.w700),
          hintStyle: TextStyle(color: palette.muted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.trim().isEmpty) {
            return;
          }
          final parsed = int.tryParse(value.trim());
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }

  Widget _targetOptionalIntField({
    required int? initialValue,
    required String hint,
    required String suffix,
    required double width,
    required ValueChanged<int> onChanged,
    required VoidCallback onCleared,
  }) {
    final palette = context.yoursPalette;
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: initialValue?.toString() ?? '',
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.fg),
        decoration: InputDecoration(
          isDense: true,
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 11, color: palette.muted, fontWeight: FontWeight.w700),
          hintText: hint,
          hintStyle: TextStyle(color: palette.muted, fontSize: 11, fontWeight: FontWeight.w700),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            onCleared();
            return;
          }
          final parsed = int.tryParse(trimmed);
          if (parsed != null) {
            onChanged(parsed.clamp(0, 3600));
          }
        },
      ),
    );
  }

  Widget _targetWeightField({
    required double? initialValue,
    required ValueChanged<double> onChanged,
    required VoidCallback onCleared,
  }) {
    final palette = context.yoursPalette;
    final text = initialValue == null
        ? ''
        : initialValue.toStringAsFixed(initialValue.truncateToDouble() == initialValue ? 0 : 1);
    return SizedBox(
      width: 62,
      child: TextFormField(
        initialValue: text,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.fg),
        decoration: InputDecoration(
          isDense: true,
          suffixText: 'kg',
          suffixStyle: TextStyle(fontSize: 11, color: palette.muted, fontWeight: FontWeight.w700),
          hintText: context.l10n.planWeight,
          hintStyle: TextStyle(color: palette.muted, fontSize: 11, fontWeight: FontWeight.w700),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) {
            onCleared();
            return;
          }
          final parsed = double.tryParse(trimmed);
          if (parsed != null) {
            onChanged(parsed.clamp(0, 9999).toDouble());
          }
        },
      ),
    );
  }

  Widget _actionNoteField({
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    final palette = context.yoursPalette;
    return TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: 3,
      style: TextStyle(fontSize: 12, color: palette.fg, height: 1.35),
      decoration: InputDecoration(
        isDense: true,
        hintText: context.l10n.planNoteHint,
        hintStyle: TextStyle(color: palette.muted),
        filled: true,
        fillColor: palette.panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

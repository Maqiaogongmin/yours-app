part of '../plan_page.dart';

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
          style: context
              .yoursText(YoursTextRole.body)
              .copyWith(
                fontWeight: FontWeight.w700,
              ),
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
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.fg,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.planScheduledDays(
              context.l10n.planSummary(_plan.totalWeeks, _plan.daysPerWeek),
              scheduledDays,
            ),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(
                  fontSize: 14,
                  color: palette.muted,
                ),
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
                      style: context
                          .yoursText(YoursTextRole.body)
                          .copyWith(
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
                style: context
                    .yoursText(YoursTextRole.body)
                    .copyWith(
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
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.fg,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    actionPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(
                          fontSize: 13,
                          color: palette.muted,
                        ),
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

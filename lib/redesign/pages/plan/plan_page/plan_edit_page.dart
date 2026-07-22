part of '../plan_page.dart';

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
    return YoursPageScaffold(
      title: context.l10n.planEditTitle,
      primaryActionLabel: context.l10n.commonSave,
      onPrimaryAction: () {
        _plan.name = _nameCtrl.text;
        Navigator.pop(context, _plan);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursFormField(
            label: context.l10n.planName,
            controller: _nameCtrl,
            onChanged: (v) => _plan.name = v,
          ),
          YoursFieldGroup(
            children: [
              YoursFormField(
                label: context.l10n.planCycle,
                controller: _weeksCtrl,
                keyboardType: TextInputType.number,
                onChanged: _onWeeksChanged,
                suffixText: context.l10n.planWeeksSuffix,
              ),
              YoursFormField(
                label: context.l10n.planDaysPerWeek,
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                onChanged: _onDaysChanged,
                suffixText: context.l10n.planDaysSuffix,
              ),
            ],
          ),
          const SizedBox(height: 6),
          YoursSectionHeader(context.l10n.planArrangement),
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
    return YoursSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      role: YoursSurfaceRole.panel,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.planWeek(widget.week),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.cardTitle).copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'D1–D${widget.daysPerWeek}',
                        style: context.yoursText(YoursTextRole.label),
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

          if (_expanded) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 360 ? 1 : 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(widget.daysPerWeek, (index) {
                      final day = index + 1;
                      final key = '${widget.week}-$day';
                      final td =
                          widget.planDays[key] ??
                          TrainingDay(week: widget.week, day: day, name: 'D$day');
                      return SizedBox(
                        width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                        child: YoursSurfaceCard(
                          onTap: () => widget.onDayTap(widget.week, day),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'D$day',
                                style: context.yoursText(
                                  YoursTextRole.label,
                                  tone: YoursTone.accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                td.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context
                                    .yoursText(YoursTextRole.body)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                td.actions.isEmpty
                                    ? '—'
                                    : td.actionNames
                                          .take(2)
                                          .map((name) => localizedExerciseName(context, name))
                                          .join('、'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.yoursText(YoursTextRole.bodyMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
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

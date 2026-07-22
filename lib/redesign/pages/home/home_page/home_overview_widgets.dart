part of '../home_page.dart';

class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final Map<DateTime, LocalTrainingDailyRecord> records;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDayClick;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.records,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDayClick,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final calendarDays = _buildCalendarDays(visibleMonth);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chevron(Icons.chevron_left_rounded, onPreviousMonth),
              _Chevron(Icons.chevron_right_rounded, onNextMonth),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.homeMonthTitle(visibleMonth.year, visibleMonth.month),
            style: context
                .yoursText(YoursTextRole.body)
                .copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: palette.fg),
          ),
          const SizedBox(height: 16),
          Row(
            children: context.l10n.homeWeekdays
                .split(',')
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: context
                            .yoursText(YoursTextRole.body)
                            .copyWith(fontSize: 14, color: palette.muted),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            (calendarDays.length / 7).ceil(),
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final idx = row * 7 + col;
                  if (idx >= calendarDays.length) {
                    return const Expanded(child: SizedBox());
                  }
                  final date = calendarDays[idx];
                  final dateKey = _dateOnly(date);
                  final isSelected = selectedDate != null && _dateOnly(selectedDate!) == dateKey;
                  final isWeekend =
                      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                  final isMuted = date.month != visibleMonth.month;
                  final hasRecord = records.containsKey(dateKey);

                  Color bg = Colors.transparent;
                  Color fg = isMuted ? palette.subtle : (isWeekend ? palette.danger : palette.fg);
                  if (isSelected) {
                    bg = palette.danger;
                    fg = Colors.white;
                  }

                  return Expanded(
                    child: GestureDetector(
                      key: ValueKey(
                        'home-day-${dateKey.year}-${dateKey.month}-${dateKey.day}',
                      ),
                      onTap: () => onDayClick(dateKey),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: context
                                  .yoursText(YoursTextRole.body)
                                  .copyWith(
                                    fontSize: 17,
                                    color: fg,
                                    fontWeight: isSelected ? FontWeight.w800 : null,
                                  ),
                            ),
                            if (hasRecord && !isSelected)
                              Positioned(
                                bottom: 6,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: palette.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (hasRecord && isSelected)
                              Positioned(
                                bottom: 6,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysBefore = firstDay.weekday - DateTime.monday;
    final start = firstDay.subtract(Duration(days: daysBefore));
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysAfter = DateTime.sunday - lastDay.weekday;
    final totalDays = daysBefore + lastDay.day + daysAfter;
    return List.generate(totalDays, (index) => start.add(Duration(days: index)));
  }
}

class _Chevron extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Chevron(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: palette.panel, shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, color: palette.accent, size: 26),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Record Card
// ═══════════════════════════════════════════════════════════════════════════════

class _RecordCard extends StatelessWidget {
  final DateTime date;
  final LocalTrainingDailyRecord? record;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  const _RecordCard({
    super.key,
    required this.date,
    required this.record,
    this.onTap,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final record = this.record;
    final hasRecord = record != null;
    final minutes = record?.duration.inMinutes ?? 0;
    final volume = record?.totalVolume.round() ?? 0;
    final freeOnly = hasRecord && record.setCount == 0 && record.freeRecordCount > 0;
    final recordName = record == null
        ? context.l10n.homeNoWorkout
        : _localizedWorkoutRecordName(context, record.name);
    final recordNote = record == null
        ? context.l10n.homeEmptyRecordMessage
        : _localizedWorkoutRecordNote(context, record.note);
    final palette = context.yoursPalette;
    return YoursRecordCardPattern(
      onTap: onTap,
      title: context.l10n.homeDateTitle(date.month, date.day, recordName),
      subtitle: hasRecord ? null : context.l10n.homeNoWorkoutRecord,
      preferInlineMetrics: true,
      status: hasRecord
          ? YoursStatusPill(
              label: context.l10n.homeRecorded,
              tone: YoursTone.accent,
            )
          : null,
      trailingAction: hasRecord && onShare != null
          ? Tooltip(
              message: context.l10n.sharePosterCreate,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: palette.muted,
                  minimumSize: const Size.square(36),
                  fixedSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                ),
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_outlined, size: 19),
              ),
            )
          : null,
      metrics: hasRecord
          ? freeOnly
                ? [
                    YoursStatBlock(
                      label: context.l10n.homeFreeRecords,
                      value: '${record.freeRecordCount}',
                    ),
                    YoursStatBlock(label: context.l10n.homeMinutes, value: '$minutes'),
                  ]
                : [
                    YoursStatBlock(label: context.l10n.homeTotalVolume, value: '$volume'),
                    YoursStatBlock(
                      label: context.l10n.homeEffectiveSets,
                      value: '${record.setCount}',
                    ),
                    YoursStatBlock(label: context.l10n.homeMinutes, value: '$minutes'),
                  ]
          : const [],
      note: recordNote,
    );
  }
}

String _localizedWorkoutRecordName(BuildContext context, String name) {
  return switch (name.trim()) {
    '训练记录' => context.l10n.homeDefaultRecordName,
    '未完成训练' => context.l10n.homeDefaultIncompleteRecordName,
    _ => name,
  };
}

String _localizedWorkoutRecordNote(BuildContext context, String note) {
  final text = note
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && line != '未完成训练计划')
      .join('\n')
      .trim();
  if (text.isEmpty) {
    return context.l10n.homeEmptyRecordMessage;
  }
  return text.replaceAll('当天训练已保存到本地数据库。', context.l10n.homeDefaultSavedNote);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Workout Record Detail Page
// ═══════════════════════════════════════════════════════════════════════════════

/// Home page — local-first dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/data/redesign_data_refresh.dart';
import 'package:yours/redesign/localization/built_in_exercise_localizations.dart';
import 'package:yours/redesign/pages/plan/local_gym_session_controller.dart';
import 'package:yours/redesign/pages/plan/exercise_picker_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LocalTrainingRepository _repository;
  late Future<Map<DateTime, LocalTrainingDailyRecord>> _recordsFuture;
  bool _showCalendar = true;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _repository = LocalTrainingRepository(locator<LocalTrainingDatabase>());
    _recordsFuture = _loadMonthlyRecords();
    LocalGymSessionController.instance.addListener(_refreshAfterWorkoutChange);
  }

  Future<Map<DateTime, LocalTrainingDailyRecord>> _loadMonthlyRecords() async {
    await _repository.ensureSeedData();
    return _repository.getDailyRecordsForMonth(_visibleMonth);
  }

  @override
  void dispose() {
    LocalGymSessionController.instance.removeListener(_refreshAfterWorkoutChange);
    super.dispose();
  }

  void _refreshAfterWorkoutChange() {
    final session = LocalGymSessionController.instance;
    if (session.isActive) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _recordsFuture = _loadMonthlyRecords();
    });
  }

  void _showConfigSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfigSheet(
        showCalendar: _showCalendar,
        onChanged: (key, value) {
          setState(() {
            switch (key) {
              case 'calendar':
                _showCalendar = value;
                break;
            }
          });
        },
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      _selectedDate = null;
      _recordsFuture = _loadMonthlyRecords();
    });
  }

  void _handleDayClick(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
  }

  Future<void> _openRecordDetail(DateTime date) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutRecordDetailPage(
          date: date,
          repository: _repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _recordsFuture = _loadMonthlyRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "今日状态" header with gear icon ──────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeTodayStatus,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: palette.fg,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showConfigSheet,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Calendar + Record ─────────────────────────────────────
          if (_showCalendar)
            FutureBuilder<Map<DateTime, LocalTrainingDailyRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                final records = snapshot.data ?? {};
                final selectedRecord = _selectedDate == null ? null : records[_selectedDate];
                return Column(
                  children: [
                    _CalendarCard(
                      visibleMonth: _visibleMonth,
                      selectedDate: _selectedDate,
                      records: records,
                      onPreviousMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                      onDayClick: _handleDayClick,
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator(color: kAccent)),
                      )
                    else if (_selectedDate != null)
                      _RecordCard(
                        date: _selectedDate!,
                        record: selectedRecord,
                        onTap: selectedRecord == null
                            ? null
                            : () => _openRecordDetail(_selectedDate!),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                );
              },
            ),

          if (!_showCalendar) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// ═══════════════════════════════════════════════════════════════════════════════
// Calendar Card
// ═══════════════════════════════════════════════════════════════════════════════

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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: palette.fg),
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
                        style: TextStyle(fontSize: 14, color: palette.muted),
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
                      onTap: () => onDayClick(dateKey),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
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
  const _RecordCard({required this.date, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final record = this.record;
    final hasRecord = record != null;
    final minutes = record?.duration.inMinutes ?? 0;
    final volume = record?.totalVolume.round() ?? 0;
    final recordName = record == null
        ? context.l10n.homeNoWorkout
        : _localizedWorkoutRecordName(context, record.name);
    final recordNote = record == null
        ? context.l10n.homeEmptyRecordMessage
        : _localizedWorkoutRecordNote(context, record.note);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.homeDateTitle(
                          date.month,
                          date.day,
                          recordName,
                        ),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: palette.fg,
                        ),
                      ),
                      if (!hasRecord) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.homeNoWorkoutRecord,
                          style: TextStyle(fontSize: 13, color: palette.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasRecord)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: (record.incomplete ? palette.danger : palette.accent).withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      record.incomplete ? context.l10n.homeIncomplete : context.l10n.homeRecorded,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: record.incomplete ? palette.danger : palette.accent,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasRecord) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  _Metric(
                    label: record.setCount == 0 && record.freeRecordCount > 0
                        ? context.l10n.homeFreeRecords
                        : context.l10n.homeTotalVolume,
                    value: record.setCount == 0 && record.freeRecordCount > 0
                        ? '${record.freeRecordCount}'
                        : '$volume',
                  ),
                  const SizedBox(width: 8),
                  _Metric(label: context.l10n.homeEffectiveSets, value: '${record.setCount}'),
                  const SizedBox(width: 8),
                  _Metric(label: context.l10n.homeMinutes, value: '$minutes'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                recordNote,
                style: TextStyle(fontSize: 14, color: palette.fg, height: 1.45),
              ),
            ),
          ],
        ),
      ),
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
  final text = note.trim();
  if (text.isEmpty) {
    return context.l10n.homeEmptyRecordMessage;
  }
  return text
      .replaceAll('当天训练已保存到本地数据库。', context.l10n.homeDefaultSavedNote)
      .replaceAll('未完成训练计划', context.l10n.homeIncompleteWorkoutMarker);
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                fontFamily: kMono,
                color: palette.fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: palette.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Workout Record Detail Page
// ═══════════════════════════════════════════════════════════════════════════════

class WorkoutRecordDetailPage extends StatefulWidget {
  final DateTime date;
  final LocalTrainingRepository repository;

  const WorkoutRecordDetailPage({
    super.key,
    required this.date,
    required this.repository,
  });

  @override
  State<WorkoutRecordDetailPage> createState() => _WorkoutRecordDetailPageState();
}

class _WorkoutRecordDetailPageState extends State<WorkoutRecordDetailPage> {
  late Future<List<LocalWorkoutSessionEditModel>> _sessionsFuture;
  final Map<int, _EditableLogDraft> _drafts = {};
  final Map<int, _EditableSessionDraft> _sessionDrafts = {};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.repository.getWorkoutSessionsForDate(widget.date);
  }

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    for (final draft in _sessionDrafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  _EditableLogDraft _draftFor(LocalWorkoutLogEditModel log) {
    return _drafts.putIfAbsent(log.id, () => _EditableLogDraft(log));
  }

  _EditableSessionDraft _sessionDraftFor(LocalWorkoutSessionEditModel session) {
    return _sessionDrafts.putIfAbsent(session.id, () => _EditableSessionDraft(session));
  }

  void _clearDrafts() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    _drafts.clear();
    for (final draft in _sessionDrafts.values) {
      draft.dispose();
    }
    _sessionDrafts.clear();
  }

  Future<void> _saveAllLogs() async {
    FocusScope.of(context).unfocus();
    try {
      for (final draft in _sessionDrafts.values) {
        draft.validate();
      }
      for (final draft in _drafts.values) {
        draft.validate();
      }
      setState(() => _saving = true);
      for (final draft in _sessionDrafts.values) {
        if (draft.session.logs.isEmpty) {
          await widget.repository.completeEmptyWorkoutSession(
            sessionId: draft.session.id,
            startedAt: draft.startedAt,
            endedAt: draft.requiredEndedAt,
            sessionNote: draft.note,
            exerciseName: draft.exerciseName,
            recordMode: draft.recordMode,
            setIndex: draft.setIndex,
            weight: draft.weight,
            reps: draft.reps,
            actionNote: draft.actionNote,
          );
        } else {
          await widget.repository.updateWorkoutSession(
            sessionId: draft.session.id,
            startedAt: draft.startedAt,
            endedAt: draft.endedAt,
            note: draft.note,
          );
        }
      }
      for (final draft in _drafts.values) {
        await widget.repository.updateWorkoutLog(
          logId: draft.log.id,
          setIndex: draft.setIndex,
          weight: draft.weight,
          reps: draft.reps,
          note: draft.note,
          durationSeconds: draft.durationSeconds,
        );
      }
      RedesignDataRefresh.instance.notifyRestored();
      if (!mounted) {
        return;
      }
      setState(() {
        _clearDrafts();
        _sessionsFuture = widget.repository.getWorkoutSessionsForDate(widget.date);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeRecordUpdated)),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.homeSaveFailed(localizedErrorDetail(context, error)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteSession(LocalWorkoutSessionEditModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.homeDeleteSessionTitle),
        content: Text(
          context.l10n.homeDeleteSessionMessage(
            _sessionTimeText(context, session),
            session.logs.length,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.deleteWorkoutSession(session.id);
      RedesignDataRefresh.instance.notifyRestored();
      if (!mounted) {
        return;
      }
      setState(() {
        _clearDrafts();
        _sessionsFuture = widget.repository.getWorkoutSessionsForDate(widget.date);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeSessionDeleted)),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.homeDeleteFailed(localizedErrorDetail(context, error)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _selectExerciseForEmptySession(_EditableSessionDraft draft) async {
    final exercise = await Navigator.of(context).push<CustomExerciseModel>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ExercisePickerPage.single(),
      ),
    );
    if (!mounted || exercise == null) {
      return;
    }
    setState(() {
      draft.setExerciseName(exercise.exerciseReference);
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
          context.l10n.homeWorkoutRecordTitle(widget.date.month, widget.date.day),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAllLogs,
            child: Text(
              _saving ? context.l10n.homeSaving : context.l10n.commonSave,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<LocalWorkoutSessionEditModel>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kAccent));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(kGutter),
              child: _emptyDetailState(),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(kGutter, 16, kGutter, 28),
            children: sessions.map((session) {
              final draft = _sessionDraftFor(session);
              return _WorkoutSessionLogSection(
                draft: draft,
                draftFor: _draftFor,
                onEndTimeChanged: () => _syncDurationFromEnd(draft),
                onDurationChanged: (log) => _syncEndFromDuration(draft, log),
                onEmptyDurationChanged: () => _syncEndFromEmptyDuration(draft),
                onModeChanged: () {
                  _syncDurationFromEnd(draft);
                  setState(() {});
                },
                onSelectExercise: () => _selectExerciseForEmptySession(draft),
                onDelete: _saving ? null : () => _deleteSession(session),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _syncDurationFromEnd(_EditableSessionDraft sessionDraft) {
    if (sessionDraft.session.logs.isEmpty) {
      if (sessionDraft.recordModeOrNull != localRecordModeFree) {
        return;
      }
      final endedAt = sessionDraft.tryEndedAt;
      final startedAt = sessionDraft.tryStartedAt;
      if (startedAt == null || endedAt == null || endedAt.isBefore(startedAt)) {
        return;
      }
      sessionDraft.setDurationSeconds(endedAt.difference(startedAt).inSeconds);
      return;
    }
    if (sessionDraft.session.logs.length != 1 ||
        sessionDraft.session.logs.single.recordMode != localRecordModeFree) {
      return;
    }
    final endedAt = sessionDraft.tryEndedAt;
    final startedAt = sessionDraft.tryStartedAt;
    if (startedAt == null || endedAt == null || endedAt.isBefore(startedAt)) {
      return;
    }
    final logDraft = _drafts[sessionDraft.session.logs.single.id];
    logDraft?.setDurationSeconds(endedAt.difference(startedAt).inSeconds);
  }

  void _syncEndFromDuration(_EditableSessionDraft sessionDraft, _EditableLogDraft logDraft) {
    if (sessionDraft.session.logs.length != 1 || logDraft.log.recordMode != localRecordModeFree) {
      return;
    }
    final startedAt = sessionDraft.tryStartedAt;
    final durationSeconds = logDraft.tryDurationSeconds;
    if (startedAt == null || durationSeconds == null) {
      return;
    }
    sessionDraft.setEndedAt(startedAt.add(Duration(seconds: durationSeconds)));
  }

  void _syncEndFromEmptyDuration(_EditableSessionDraft sessionDraft) {
    if (sessionDraft.session.logs.isNotEmpty ||
        sessionDraft.recordModeOrNull != localRecordModeFree) {
      return;
    }
    final startedAt = sessionDraft.tryStartedAt;
    final durationSeconds = sessionDraft.tryDurationSeconds;
    if (startedAt == null || durationSeconds == null) {
      return;
    }
    sessionDraft.setEndedAt(startedAt.add(Duration(seconds: durationSeconds)));
  }

  Widget _emptyDetailState() {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Text(
        context.l10n.homeNoSetRecords,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

class _WorkoutSessionLogSection extends StatelessWidget {
  final _EditableSessionDraft draft;
  final _EditableLogDraft Function(LocalWorkoutLogEditModel log) draftFor;
  final VoidCallback onEndTimeChanged;
  final ValueChanged<_EditableLogDraft> onDurationChanged;
  final VoidCallback onEmptyDurationChanged;
  final VoidCallback onModeChanged;
  final VoidCallback onSelectExercise;
  final VoidCallback? onDelete;

  const _WorkoutSessionLogSection({
    required this.draft,
    required this.draftFor,
    required this.onEndTimeChanged,
    required this.onDurationChanged,
    required this.onEmptyDurationChanged,
    required this.onModeChanged,
    required this.onSelectExercise,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final session = draft.session;
    final groupedLogs = _groupLogs(session.logs);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inlineSplitTimeFields(
                    context,
                    keyPrefix: 'session-${draft.session.id}-start',
                    hourController: draft.startHourController,
                    minuteController: draft.startMinuteController,
                    onChanged: onEndTimeChanged,
                  ),
                  Text(
                    ' - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.fg,
                    ),
                  ),
                  _inlineSplitTimeFields(
                    context,
                    keyPrefix: 'session-${draft.session.id}-end',
                    hourController: draft.endHourController,
                    minuteController: draft.endMinuteController,
                    onChanged: onEndTimeChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.noteController,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(color: palette.muted, height: 1.45),
            decoration: InputDecoration(
              hintText: context.l10n.workoutTrainingNote,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 14),
          if (session.logs.isEmpty)
            _EmptySessionEditor(
              draft: draft,
              onDurationChanged: onEmptyDurationChanged,
              onModeChanged: onModeChanged,
              onSelectExercise: onSelectExercise,
            )
          else
            ...groupedLogs.entries.map(
              (entry) => _ExerciseLogSection(
                exerciseName: entry.key,
                logs: entry.value,
                draftFor: draftFor,
                onDurationChanged: onDurationChanged,
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.homeDeleteSessionTitle.replaceAll('？', '')),
              style: OutlinedButton.styleFrom(
                foregroundColor: kRed,
                side: BorderSide(color: kRed.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineSplitTimeFields(
    BuildContext context, {
    required String keyPrefix,
    required TextEditingController hourController,
    required TextEditingController minuteController,
    required VoidCallback onChanged,
  }) {
    final palette = context.yoursPalette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _timePartField(
          context,
          hourController,
          key: ValueKey('$keyPrefix-hours'),
          maxValue: 23,
          onChanged: onChanged,
        ),
        Text(
          ':',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: palette.fg),
        ),
        _timePartField(
          context,
          minuteController,
          key: ValueKey('$keyPrefix-minutes'),
          maxValue: 59,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _timePartField(
    BuildContext context,
    TextEditingController controller, {
    required Key key,
    required int maxValue,
    required VoidCallback onChanged,
  }) {
    final palette = context.yoursPalette;
    return Container(
      width: 32,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: TextField(
        key: key,
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          _BoundedTwoDigitInputFormatter(maxValue),
        ],
        maxLength: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: palette.fg,
        ),
        decoration: InputDecoration(
          hintText: '00',
          hintStyle: TextStyle(
            color: palette.muted.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Map<String, List<LocalWorkoutLogEditModel>> _groupLogs(List<LocalWorkoutLogEditModel> logs) {
    final grouped = <String, List<LocalWorkoutLogEditModel>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.exerciseName, () => []).add(log);
    }
    for (final logs in grouped.values) {
      logs.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    }
    return grouped;
  }
}

class _ExerciseLogSection extends StatelessWidget {
  final String exerciseName;
  final List<LocalWorkoutLogEditModel> logs;
  final _EditableLogDraft Function(LocalWorkoutLogEditModel log) draftFor;
  final ValueChanged<_EditableLogDraft> onDurationChanged;

  const _ExerciseLogSection({
    required this.exerciseName,
    required this.logs,
    required this.draftFor,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedExerciseName(context, exerciseName),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.fg),
          ),
          const SizedBox(height: 4),
          Text(
            logs.every((log) => log.recordMode == localRecordModeFree)
                ? context.l10n.homeActivityRecordCount(logs.length)
                : context.l10n.homeRecordCount(logs.length),
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 12),
          ...logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogEditCard(
                draft: draftFor(log),
                onDurationChanged: onDurationChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sessionTimeText(BuildContext context, LocalWorkoutSessionEditModel session) {
  final started = _shortTime(session.startedAt);
  final endedAt = session.endedAt;
  if (endedAt == null) {
    return context.l10n.homeStartedAt(started);
  }
  return '$started - ${_shortTime(endedAt)}';
}

String _shortTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _EditableLogDraft {
  final LocalWorkoutLogEditModel log;
  late final TextEditingController _setCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _durationHourCtrl;
  late final TextEditingController _durationMinuteCtrl;
  late final TextEditingController _durationSecondCtrl;
  late final TextEditingController _noteCtrl;

  _EditableLogDraft(this.log) {
    _setCtrl = TextEditingController(text: log.setIndex.toString());
    _weightCtrl = TextEditingController(text: _formatWeight(log.weight));
    _repsCtrl = TextEditingController(text: log.reps.toString());
    _durationHourCtrl = TextEditingController();
    _durationMinuteCtrl = TextEditingController();
    _durationSecondCtrl = TextEditingController();
    _setDurationParts(
      log.durationSeconds,
      _durationHourCtrl,
      _durationMinuteCtrl,
      _durationSecondCtrl,
    );
    _noteCtrl = TextEditingController(text: log.note);
  }

  void dispose() {
    _setCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _durationHourCtrl.dispose();
    _durationMinuteCtrl.dispose();
    _durationSecondCtrl.dispose();
    _noteCtrl.dispose();
  }

  int get setIndex => int.tryParse(_setCtrl.text.trim()) ?? log.setIndex;
  double get weight => double.tryParse(_weightCtrl.text.trim()) ?? log.weight;
  int get reps => int.tryParse(_repsCtrl.text.trim()) ?? log.reps;
  String get note => _noteCtrl.text;
  int? get tryDurationSeconds => _parseDurationParts(
    _durationHourCtrl.text,
    _durationMinuteCtrl.text,
    _durationSecondCtrl.text,
  );
  int get durationSeconds => tryDurationSeconds ?? log.durationSeconds;

  void setDurationSeconds(int seconds) {
    _setDurationParts(
      seconds,
      _durationHourCtrl,
      _durationMinuteCtrl,
      _durationSecondCtrl,
    );
  }

  void validate() {
    if (log.recordMode == localRecordModeFree && tryDurationSeconds == null) {
      throw const FormatException('本项用时格式应为 HH:mm:ss');
    }
  }

  String _formatWeight(double weight) {
    return weight.truncateToDouble() == weight ? weight.toStringAsFixed(0) : weight.toString();
  }
}

class _LogEditCard extends StatelessWidget {
  final _EditableLogDraft draft;
  final ValueChanged<_EditableLogDraft> onDurationChanged;

  const _LogEditCard({
    required this.draft,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: draft.log.recordMode == localRecordModeFree
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.workoutActivityElapsed,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _SplitDurationFields(
                      keyPrefix: 'log-duration-${draft.log.id}',
                      hourController: draft._durationHourCtrl,
                      minuteController: draft._durationMinuteCtrl,
                      secondController: draft._durationSecondCtrl,
                      onChanged: () => onDurationChanged(draft),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _noteField(context),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _miniField(context, context.l10n.homeSets, draft._setCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _miniField(context, context.l10n.homeReps, draft._repsCtrl)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniField(
                        context,
                        context.l10n.homeWeightKg,
                        draft._weightCtrl,
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _noteField(context),
              ],
            ),
    );
  }

  Widget _noteField(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: draft._noteCtrl,
        minLines: 1,
        maxLines: 3,
        style: TextStyle(fontSize: 13, height: 1.45, color: palette.fg),
        decoration: InputDecoration(
          hintText: context.l10n.workoutNote,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _miniField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool decimal = false,
  }) {
    final palette = context.yoursPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: palette.muted, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
            cursorColor: palette.accent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySessionEditor extends StatelessWidget {
  final _EditableSessionDraft draft;
  final VoidCallback onDurationChanged;
  final VoidCallback onModeChanged;
  final VoidCallback onSelectExercise;

  const _EmptySessionEditor({
    required this.draft,
    required this.onDurationChanged,
    required this.onModeChanged,
    required this.onSelectExercise,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onSelectExercise,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      draft.exerciseName.trim().isEmpty
                          ? context.l10n.planAddExercise
                          : localizedExerciseName(context, draft.exerciseName),
                      style: TextStyle(
                        fontSize: draft.exerciseName.trim().isEmpty ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: draft.exerciseName.trim().isEmpty ? palette.accent : palette.fg,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: palette.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: draft.recordModeOrNull,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n.workoutRecordMode,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: localRecordModeStandard,
                child: Text(context.l10n.planRecordModeStandard),
              ),
              DropdownMenuItem(
                value: localRecordModeFree,
                child: Text(context.l10n.planRecordModeFree),
              ),
            ],
            onChanged: (value) {
              draft.recordModeOrNull = value;
              onModeChanged();
            },
          ),
          if (draft.recordModeOrNull == localRecordModeStandard) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallNumberField(context, context.l10n.homeSets, draft.setController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallNumberField(context, context.l10n.homeReps, draft.repsController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallNumberField(
                    context,
                    context.l10n.homeWeightKg,
                    draft.weightController,
                    decimal: true,
                  ),
                ),
              ],
            ),
          ],
          if (draft.recordModeOrNull == localRecordModeFree) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.workoutActivityElapsed,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _SplitDurationFields(
                  keyPrefix: 'session-duration-${draft.session.id}',
                  hourController: draft.durationHourController,
                  minuteController: draft.durationMinuteController,
                  secondController: draft.durationSecondController,
                  onChanged: onDurationChanged,
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: draft.actionNoteController,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(fontSize: 13, height: 1.45, color: palette.fg),
              decoration: InputDecoration(
                hintText: context.l10n.workoutNote,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableSessionDraft {
  final LocalWorkoutSessionEditModel session;
  late final TextEditingController startHourController;
  late final TextEditingController startMinuteController;
  late final TextEditingController endHourController;
  late final TextEditingController endMinuteController;
  late final TextEditingController noteController;
  late final TextEditingController setController;
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final TextEditingController durationHourController;
  late final TextEditingController durationMinuteController;
  late final TextEditingController durationSecondController;
  late final TextEditingController actionNoteController;
  String exerciseName = '';
  String? recordModeOrNull;

  _EditableSessionDraft(this.session) {
    startHourController = TextEditingController(
      text: session.startedAt.hour.toString().padLeft(2, '0'),
    );
    startMinuteController = TextEditingController(
      text: session.startedAt.minute.toString().padLeft(2, '0'),
    );
    endHourController = TextEditingController(
      text: session.endedAt == null ? '' : session.endedAt!.hour.toString().padLeft(2, '0'),
    );
    endMinuteController = TextEditingController(
      text: session.endedAt == null ? '' : session.endedAt!.minute.toString().padLeft(2, '0'),
    );
    noteController = TextEditingController(text: session.note);
    setController = TextEditingController(text: '1');
    weightController = TextEditingController(text: '0');
    repsController = TextEditingController(text: '0');
    final initialDuration = session.endedAt == null
        ? 0
        : session.endedAt!.difference(session.startedAt).inSeconds;
    durationHourController = TextEditingController();
    durationMinuteController = TextEditingController();
    durationSecondController = TextEditingController();
    _setDurationParts(
      initialDuration,
      durationHourController,
      durationMinuteController,
      durationSecondController,
    );
    actionNoteController = TextEditingController();
  }

  DateTime? get tryStartedAt => _parseTimeParts(
    session.startedAt,
    startHourController.text,
    startMinuteController.text,
  );

  DateTime? get tryEndedAt {
    final hour = endHourController.text.trim();
    final minute = endMinuteController.text.trim();
    if (hour.isEmpty && minute.isEmpty) {
      return null;
    }
    return _parseTimeParts(session.startedAt, hour, minute);
  }

  DateTime get startedAt => tryStartedAt ?? (throw const FormatException('开始时间格式应为 HH:mm'));
  DateTime? get endedAt => tryEndedAt;
  DateTime get requiredEndedAt => tryEndedAt ?? (throw const FormatException('请填写结束时间'));
  String get note => noteController.text;
  String get recordMode => recordModeOrNull ?? (throw const FormatException('请选择记录方式'));
  int get setIndex => int.tryParse(setController.text.trim()) ?? 1;
  double get weight => double.tryParse(weightController.text.trim()) ?? 0;
  int get reps => int.tryParse(repsController.text.trim()) ?? 0;
  String get actionNote => actionNoteController.text;
  int? get tryDurationSeconds => _parseDurationParts(
    durationHourController.text,
    durationMinuteController.text,
    durationSecondController.text,
  );

  void setEndedAt(DateTime value) {
    endHourController.text = value.hour.toString().padLeft(2, '0');
    endMinuteController.text = value.minute.toString().padLeft(2, '0');
  }

  void setDurationSeconds(int seconds) {
    _setDurationParts(
      seconds,
      durationHourController,
      durationMinuteController,
      durationSecondController,
    );
  }

  void setExerciseName(String value) {
    exerciseName = value;
  }

  void validate() {
    final start = tryStartedAt;
    if (start == null) {
      throw const FormatException('开始时间格式应为 HH:mm');
    }
    final end = tryEndedAt;
    if ((endHourController.text.trim().isNotEmpty || endMinuteController.text.trim().isNotEmpty) &&
        end == null) {
      throw const FormatException('结束时间格式应为 HH:mm');
    }
    if (end != null && end.isBefore(start)) {
      throw const FormatException('结束时间不能早于开始时间');
    }
    if (session.logs.isEmpty) {
      if (end == null) {
        throw const FormatException('请填写结束时间');
      }
      if (exerciseName.trim().isEmpty) {
        throw const FormatException('请填写动作名称');
      }
      if (recordModeOrNull == null) {
        throw const FormatException('请选择记录方式');
      }
      if (recordModeOrNull == localRecordModeFree && tryDurationSeconds == null) {
        throw const FormatException('本项用时格式应为 HH:mm:ss');
      }
    }
  }

  void dispose() {
    startHourController.dispose();
    startMinuteController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();
    noteController.dispose();
    setController.dispose();
    weightController.dispose();
    repsController.dispose();
    durationHourController.dispose();
    durationMinuteController.dispose();
    durationSecondController.dispose();
    actionNoteController.dispose();
  }
}

class _SplitDurationFields extends StatelessWidget {
  final String keyPrefix;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController secondController;
  final VoidCallback onChanged;

  const _SplitDurationFields({
    required this.keyPrefix,
    required this.hourController,
    required this.minuteController,
    required this.secondController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _durationPartField(
          context,
          key: ValueKey('$keyPrefix-hours'),
          controller: hourController,
          maxValue: 23,
        ),
        _durationSeparator(palette),
        _durationPartField(
          context,
          key: ValueKey('$keyPrefix-minutes'),
          controller: minuteController,
          maxValue: 59,
        ),
        _durationSeparator(palette),
        _durationPartField(
          context,
          key: ValueKey('$keyPrefix-seconds'),
          controller: secondController,
          maxValue: 59,
        ),
      ],
    );
  }

  Widget _durationPartField(
    BuildContext context, {
    required Key key,
    required TextEditingController controller,
    required int maxValue,
  }) {
    final palette = context.yoursPalette;
    return Container(
      width: 32,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: TextField(
        key: key,
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          _BoundedTwoDigitInputFormatter(maxValue),
        ],
        maxLength: 2,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: palette.fg.withValues(alpha: 0.78),
        ),
        decoration: InputDecoration(
          hintText: '00',
          hintStyle: TextStyle(
            color: palette.muted.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _durationSeparator(YoursPalette palette) {
    return Text(
      ':',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: palette.muted,
      ),
    );
  }
}

class _BoundedTwoDigitInputFormatter extends TextInputFormatter {
  final int maxValue;

  const _BoundedTwoDigitInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }
    return newValue;
  }
}

DateTime? _parseClock(DateTime date, String raw) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime? _parseTimeParts(DateTime date, String rawHour, String rawMinute) {
  final hour = rawHour.trim();
  final minute = rawMinute.trim();
  if (hour.length != 2 || minute.length != 2) {
    return null;
  }
  return _parseClock(date, '$hour:$minute');
}

int? _parseDurationParts(String rawHours, String rawMinutes, String rawSeconds) {
  final hoursText = rawHours.trim();
  final minutesText = rawMinutes.trim();
  final secondsText = rawSeconds.trim();
  if (hoursText.length != 2 || minutesText.length != 2 || secondsText.length != 2) {
    return null;
  }
  final hours = int.tryParse(hoursText);
  final minutes = int.tryParse(minutesText);
  final seconds = int.tryParse(secondsText);
  if (hours == null || minutes == null || seconds == null) {
    return null;
  }
  if (hours > 23 || minutes > 59 || seconds > 59) {
    return null;
  }
  return hours * 3600 + minutes * 60 + seconds;
}

void _setDurationParts(
  int seconds,
  TextEditingController hourController,
  TextEditingController minuteController,
  TextEditingController secondController,
) {
  final safe = seconds.clamp(0, 23 * 3600 + 59 * 60 + 59);
  final duration = Duration(seconds: safe);
  hourController.text = duration.inHours.toString().padLeft(2, '0');
  minuteController.text = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  secondController.text = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
}

Widget _smallNumberField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool decimal = false,
}) {
  final palette = context.yoursPalette;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: palette.muted, fontWeight: FontWeight.w700),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
          cursorColor: palette.accent,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Config Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _ConfigSheet extends StatefulWidget {
  final bool showCalendar;
  final void Function(String, bool) onChanged;
  const _ConfigSheet({
    required this.showCalendar,
    required this.onChanged,
  });

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  late bool _calendar;

  @override
  void initState() {
    super.initState();
    _calendar = widget.showCalendar;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.homeDashboardSettings,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: palette.fg),
                  ),
                  _closeBtn(context, () => Navigator.pop(context)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              child: Column(
                children: [
                  _ToggleRow(
                    label: context.l10n.homeCalendar,
                    value: _calendar,
                    onChanged: (v) => setState(() => _calendar = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _outlinedBtn(
                          context,
                          context.l10n.commonClose,
                          () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _filledBtn(context, context.l10n.commonDone, () {
                          widget.onChanged('calendar', _calendar);
                          Navigator.pop(context);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
          color: palette.panel,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: palette.fg)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared mini-widgets
// ═══════════════════════════════════════════════════════════════════════════════

Widget _closeBtn(BuildContext context, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: palette.panel, shape: BoxShape.circle),
      child: Center(
        child: Text('×', style: TextStyle(fontSize: 20, color: palette.fg)),
      ),
    ),
  );
}

Widget _outlinedBtn(BuildContext context, String label, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: palette.panel,
      foregroundColor: palette.fg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

Widget _filledBtn(BuildContext context, String label, VoidCallback onTap) {
  final palette = context.yoursPalette;
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: palette.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

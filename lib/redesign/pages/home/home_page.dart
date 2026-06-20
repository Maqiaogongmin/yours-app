/// Home page — local-first dashboard.
library;

import 'package:flutter/material.dart';
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
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/shareability/yours_workout_share_poster_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
part 'home_page/home_overview_widgets.dart';
part 'home_page/workout_record_detail_page.dart';
part 'home_page/workout_record_sections.dart';
part 'home_page/workout_record_drafts.dart';
part 'home_page/workout_record_editors.dart';
part 'home_page/workout_record_log_edit_card.dart';
part 'home_page/workout_record_empty_session_editor.dart';
part 'home_page/workout_record_editable_session_draft.dart';
part 'home_page/workout_record_split_duration_fields.dart';
part 'home_page/home_config_sheet.dart';

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.repository});

  final LocalTrainingRepository? repository;

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
    _repository = widget.repository ?? LocalTrainingRepository(locator<LocalTrainingDatabase>());
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

  Future<void> _openSharePoster(DateTime date, LocalTrainingDailyRecord record) async {
    await openWorkoutSharePoster(
      context: context,
      repository: _repository,
      date: date,
      record: record,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoursPageHeader(
            title: context.l10n.homeTodayStatus,
            trailing: IconButton(
              key: const ValueKey('home-display-settings'),
              tooltip: context.l10n.settingsTitle,
              onPressed: _showConfigSheet,
              style: IconButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.square(44),
              ),
              icon: const Icon(Icons.settings_outlined, size: 20),
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
                        key: const ValueKey('home-record-card'),
                        date: _selectedDate!,
                        record: selectedRecord,
                        onTap: selectedRecord == null
                            ? null
                            : () => _openRecordDetail(_selectedDate!),
                        onShare: selectedRecord == null
                            ? null
                            : () => _openSharePoster(_selectedDate!, selectedRecord),
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

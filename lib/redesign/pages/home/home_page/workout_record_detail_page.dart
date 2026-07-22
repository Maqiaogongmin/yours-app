part of '../home_page.dart';

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
          actualWeight: draft.actualWeight,
          actualReps: draft.actualReps,
          actualDurationSeconds: draft.actualDurationSeconds,
          restSeconds: draft.actualRestSeconds,
          hasActualValues: true,
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
          style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.sharePosterCreate,
            onPressed: _saving
                ? null
                : () => openWorkoutSharePoster(
                    context: context,
                    repository: widget.repository,
                    date: widget.date,
                  ),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          TextButton(
            onPressed: _saving ? null : _saveAllLogs,
            child: Text(
              _saving ? context.l10n.homeSaving : context.l10n.commonSave,
              style: context
                  .yoursText(YoursTextRole.body)
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
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
        style: context.yoursText(YoursTextRole.body).copyWith(color: palette.muted, fontSize: 14),
      ),
    );
  }
}

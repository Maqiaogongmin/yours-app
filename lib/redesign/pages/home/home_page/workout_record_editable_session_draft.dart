part of '../home_page.dart';

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
        throw const YoursException(YoursErrorCode.workoutEmptySessionActionRequired);
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

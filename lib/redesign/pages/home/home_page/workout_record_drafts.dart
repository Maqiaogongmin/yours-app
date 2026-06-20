part of '../home_page.dart';

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

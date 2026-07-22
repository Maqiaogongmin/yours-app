part of '../home_page.dart';

class _EditableLogDraft {
  final LocalWorkoutLogEditModel log;
  late final TextEditingController _setCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _durationHourCtrl;
  late final TextEditingController _durationMinuteCtrl;
  late final TextEditingController _durationSecondCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _noteCtrl;

  _EditableLogDraft(this.log) {
    _setCtrl = TextEditingController(text: log.setIndex.toString());
    _weightCtrl = TextEditingController(
      text: log.recordedWeight == null ? '' : _formatWeight(log.recordedWeight!),
    );
    _repsCtrl = TextEditingController(text: log.recordedReps?.toString() ?? '');
    _durationHourCtrl = TextEditingController();
    _durationMinuteCtrl = TextEditingController();
    _durationSecondCtrl = TextEditingController();
    _setDurationParts(
      log.recordedDurationSeconds ?? 0,
      _durationHourCtrl,
      _durationMinuteCtrl,
      _durationSecondCtrl,
    );
    if (log.recordedDurationSeconds == null) {
      _durationHourCtrl.clear();
      _durationMinuteCtrl.clear();
      _durationSecondCtrl.clear();
    }
    _restCtrl = TextEditingController(text: log.restSeconds?.toString() ?? '');
    _noteCtrl = TextEditingController(text: log.note);
  }

  void dispose() {
    _setCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _durationHourCtrl.dispose();
    _durationMinuteCtrl.dispose();
    _durationSecondCtrl.dispose();
    _restCtrl.dispose();
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
  double? get actualWeight => double.tryParse(_weightCtrl.text.trim());
  int? get actualReps => int.tryParse(_repsCtrl.text.trim());
  int? get actualRestSeconds => int.tryParse(_restCtrl.text.trim());
  int? get actualDurationSeconds => tryDurationSeconds;

  void setDurationSeconds(int seconds) {
    _setDurationParts(
      seconds,
      _durationHourCtrl,
      _durationMinuteCtrl,
      _durationSecondCtrl,
    );
  }

  void validate() {
    if (actualRestSeconds != null && (actualRestSeconds! < 0 || actualRestSeconds! > 3600)) {
      throw const FormatException('休息时间应在 0 到 3600 秒之间');
    }
  }

  String _formatWeight(double weight) {
    return weight.truncateToDouble() == weight ? weight.toStringAsFixed(0) : weight.toString();
  }
}

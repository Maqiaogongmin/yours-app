import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yours/redesign/data/local_training_models.dart';

enum YoursSharePosterPreset { deepPurple, warmPaper, ember, forest }

@immutable
class YoursSharePosterOptions {
  const YoursSharePosterOptions({
    this.preset = YoursSharePosterPreset.deepPurple,
    this.photoPath,
    this.showWorkoutName = true,
    this.showDate = true,
    this.showDuration = true,
    this.showExerciseCount = true,
    this.showSetCount = true,
    this.showVolume = true,
    this.showNote = true,
    this.showBrand = true,
  });

  final YoursSharePosterPreset preset;
  final String? photoPath;
  final bool showWorkoutName;
  final bool showDate;
  final bool showDuration;
  final bool showExerciseCount;
  final bool showSetCount;
  final bool showVolume;
  final bool showNote;
  final bool showBrand;

  bool get hasPhotoBackground => photoPath != null && photoPath!.trim().isNotEmpty;

  YoursSharePosterOptions copyWith({
    YoursSharePosterPreset? preset,
    String? photoPath,
    bool clearPhotoPath = false,
    bool? showWorkoutName,
    bool? showDate,
    bool? showDuration,
    bool? showExerciseCount,
    bool? showSetCount,
    bool? showVolume,
    bool? showNote,
    bool? showBrand,
  }) {
    return YoursSharePosterOptions(
      preset: preset ?? this.preset,
      photoPath: clearPhotoPath ? null : photoPath ?? this.photoPath,
      showWorkoutName: showWorkoutName ?? this.showWorkoutName,
      showDate: showDate ?? this.showDate,
      showDuration: showDuration ?? this.showDuration,
      showExerciseCount: showExerciseCount ?? this.showExerciseCount,
      showSetCount: showSetCount ?? this.showSetCount,
      showVolume: showVolume ?? this.showVolume,
      showNote: showNote ?? this.showNote,
      showBrand: showBrand ?? this.showBrand,
    );
  }
}

@immutable
class YoursWorkoutShareData {
  const YoursWorkoutShareData({
    required this.workoutName,
    required this.recordLabel,
    required this.date,
    required this.duration,
    required this.exerciseCount,
    required this.setCount,
    required this.totalVolume,
    required this.note,
    this.incomplete = false,
  });

  final String workoutName;
  final String recordLabel;
  final DateTime date;
  final Duration duration;
  final int exerciseCount;
  final int setCount;
  final num totalVolume;
  final String note;
  final bool incomplete;

  factory YoursWorkoutShareData.fromRecord({
    required LocalTrainingDailyRecord record,
    required List<LocalWorkoutSessionEditModel> sessions,
    required String fallbackName,
  }) {
    final exercises = <String>{};
    for (final session in sessions) {
      for (final log in session.logs) {
        final name = log.exerciseName.trim();
        if (name.isNotEmpty) {
          exercises.add(name);
        }
      }
    }
    final recordName = record.name.trim();
    final recordLabel = fallbackName.trim().isEmpty ? recordName : fallbackName.trim();
    final dayName = _firstSessionDayName(sessions);
    final note = _sessionNotes(sessions);
    return YoursWorkoutShareData(
      workoutName: dayName,
      recordLabel: recordLabel.isEmpty ? recordName : recordLabel,
      date: record.date,
      duration: record.duration,
      exerciseCount: exercises.length,
      setCount: record.setCount,
      totalVolume: record.totalVolume,
      note: note.isEmpty ? record.note : note,
      incomplete: record.incomplete,
    );
  }
}

String _firstSessionDayName(List<LocalWorkoutSessionEditModel> sessions) {
  for (final session in sessions) {
    final dayName = session.dayName.trim();
    if (dayName.isNotEmpty) {
      return dayName;
    }
  }
  return '';
}

String _sessionNotes(List<LocalWorkoutSessionEditModel> sessions) {
  final notes = <String>[];
  for (final session in sessions) {
    final note = session.note.trim();
    if (note.isNotEmpty && !notes.contains(note)) {
      notes.add(note);
    }
  }
  return notes.join('\n');
}

@visibleForTesting
File? yoursPosterPhotoFile(YoursSharePosterOptions options) {
  final path = options.photoPath;
  if (path == null || path.trim().isEmpty) {
    return null;
  }
  return File(path);
}

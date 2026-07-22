import 'package:collection/collection.dart';

const localSyncPending = 'pending';
const localSyncSynced = 'synced';
const localSyncFailed = 'failed';

const localRecordModeStandard = 'standard';
const localRecordModeFree = 'free';

String normalizeLocalRecordMode(Object? value) {
  return value == localRecordModeFree ? localRecordModeFree : localRecordModeStandard;
}

int defaultTargetSetsForRecordMode(Object? recordMode) {
  return normalizeLocalRecordMode(recordMode) == localRecordModeFree ? 1 : 3;
}

int normalizeTargetSetsForRecordMode(Object? recordMode, int? targetSets) {
  return (targetSets ?? defaultTargetSetsForRecordMode(recordMode)).clamp(1, 20);
}

class LocalTrainingActionModel {
  String? syncId;
  String name;
  int targetSets;
  int targetReps;
  double? targetWeight;
  int? targetRestSeconds;
  int? targetDurationSeconds;
  String recordMode;
  String note;

  LocalTrainingActionModel({
    this.syncId,
    required this.name,
    int? targetSets,
    this.targetReps = 8,
    this.targetWeight,
    this.targetRestSeconds,
    this.targetDurationSeconds,
    String recordMode = localRecordModeStandard,
    this.note = '',
  }) : targetSets = normalizeTargetSetsForRecordMode(recordMode, targetSets),
       recordMode = normalizeLocalRecordMode(recordMode);

  LocalTrainingActionModel copyWith({
    String? syncId,
    String? name,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    bool clearTargetWeight = false,
    int? targetRestSeconds,
    bool clearTargetRestSeconds = false,
    int? targetDurationSeconds,
    bool clearTargetDurationSeconds = false,
    String? recordMode,
    String? note,
  }) {
    final normalizedRecordMode = normalizeLocalRecordMode(recordMode ?? this.recordMode);
    return LocalTrainingActionModel(
      syncId: syncId ?? this.syncId,
      name: name ?? this.name,
      targetSets: targetSets ?? (recordMode == null ? this.targetSets : null),
      targetReps: targetReps ?? this.targetReps,
      targetWeight: clearTargetWeight ? null : targetWeight ?? this.targetWeight,
      targetRestSeconds: clearTargetRestSeconds
          ? null
          : targetRestSeconds ?? this.targetRestSeconds,
      targetDurationSeconds: clearTargetDurationSeconds
          ? null
          : targetDurationSeconds ?? this.targetDurationSeconds,
      recordMode: normalizedRecordMode,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    if (syncId != null && syncId!.trim().isNotEmpty) 'syncId': syncId,
    'name': name,
    'targetSets': targetSets,
    'targetReps': targetReps,
    if (targetWeight != null) 'targetWeight': targetWeight,
    if (targetRestSeconds != null) 'targetRestSeconds': targetRestSeconds,
    if (targetDurationSeconds != null) 'targetDurationSeconds': targetDurationSeconds,
    if (recordMode != localRecordModeStandard) 'recordMode': recordMode,
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };

  factory LocalTrainingActionModel.fromJson(dynamic json) {
    if (json is LocalTrainingActionModel) {
      return json.copyWith();
    }
    if (json is String) {
      return LocalTrainingActionModel(name: json);
    }
    if (json is Map) {
      final recordMode = normalizeLocalRecordMode(json['recordMode']);
      return LocalTrainingActionModel(
        syncId: json['syncId'] as String?,
        name: json['name'] as String? ?? '未命名动作',
        targetSets: (json['targetSets'] as num?)?.toInt(),
        targetReps: (json['targetReps'] as num?)?.toInt() ?? 8,
        targetWeight: (json['targetWeight'] as num?)?.toDouble(),
        targetRestSeconds: (json['targetRestSeconds'] as num?)?.toInt(),
        targetDurationSeconds: (json['targetDurationSeconds'] as num?)?.toInt(),
        recordMode: recordMode,
        note: json['note'] as String? ?? '',
      );
    }
    return LocalTrainingActionModel(name: '未命名动作');
  }

  @override
  String toString() => name;
}

class LocalTrainingDayModel {
  final int? id;
  final String? syncId;
  final int week;
  final int day;
  String name;
  List<LocalTrainingActionModel> actions;

  LocalTrainingDayModel({
    this.id,
    this.syncId,
    required this.week,
    required this.day,
    required this.name,
    List<dynamic>? actions,
  }) : actions = (actions ?? []).map(LocalTrainingActionModel.fromJson).toList();

  LocalTrainingDayModel copyWith({
    int? id,
    String? syncId,
    int? week,
    int? day,
    String? name,
    List<LocalTrainingActionModel>? actions,
  }) {
    return LocalTrainingDayModel(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      week: week ?? this.week,
      day: day ?? this.day,
      name: name ?? this.name,
      actions: actions ?? this.actions.map((action) => action.copyWith()).toList(),
    );
  }

  List<String> get actionNames => actions.map((action) => action.name).toList();

  int get totalTargetSets => actions.fold(
    0,
    (sum, action) => sum + (action.recordMode == localRecordModeFree ? 1 : action.targetSets),
  );
}

class LocalTrainingPlanModel {
  final int? id;
  final String? syncId;
  String name;
  int totalWeeks;
  int daysPerWeek;
  bool archived;
  Set<int> completedWeeks;
  String syncStatus;
  final Map<String, LocalTrainingDayModel> days;

  LocalTrainingPlanModel({
    this.id,
    this.syncId,
    required this.name,
    this.totalWeeks = 5,
    this.daysPerWeek = 6,
    this.archived = false,
    Set<int>? completedWeeks,
    this.syncStatus = localSyncPending,
    Map<String, LocalTrainingDayModel>? days,
  }) : completedWeeks = completedWeeks ?? <int>{},
       days = days ?? {};

  LocalTrainingPlanModel deepCopy() {
    return LocalTrainingPlanModel(
      id: id,
      syncId: syncId,
      name: name,
      totalWeeks: totalWeeks,
      daysPerWeek: daysPerWeek,
      archived: archived,
      completedWeeks: Set<int>.of(completedWeeks),
      syncStatus: syncStatus,
      days: days.map((key, value) => MapEntry(key, value.copyWith())),
    );
  }

  String get summary => '$totalWeeks 周 · 每周 $daysPerWeek 天';

  bool get hasFullSchedule {
    for (var w = 1; w <= totalWeeks; w++) {
      for (var d = 1; d <= daysPerWeek; d++) {
        final day = days['$w-$d'];
        if (day == null || day.actions.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  LocalTrainingDayModel? get firstWorkoutDay {
    final sorted = days.values.toList()
      ..sort((a, b) {
        final weekCompare = a.week.compareTo(b.week);
        return weekCompare != 0 ? weekCompare : a.day.compareTo(b.day);
      });
    return sorted.firstWhereOrNull((day) => day.actions.isNotEmpty);
  }
}

class LocalTrainingStats {
  final int sessionCount;
  final int setCount;
  final num totalVolume;
  final Duration duration;
  final int freeRecordCount;

  const LocalTrainingStats({
    required this.sessionCount,
    required this.setCount,
    required this.totalVolume,
    required this.duration,
    this.freeRecordCount = 0,
  });
}

class LocalTrainingDailyRecord {
  final DateTime date;
  final String name;
  final int sessionCount;
  final int setCount;
  final num totalVolume;
  final Duration duration;
  final int freeRecordCount;
  final String note;
  final bool incomplete;

  const LocalTrainingDailyRecord({
    required this.date,
    required this.name,
    required this.sessionCount,
    required this.setCount,
    required this.totalVolume,
    required this.duration,
    this.freeRecordCount = 0,
    required this.note,
    this.incomplete = false,
  });
}

class LocalWorkoutLogEditModel {
  final int id;
  final int sessionId;
  final String exerciseName;
  final int setIndex;
  final double weight;
  final int reps;
  final String note;
  final String recordMode;
  final int durationSeconds;
  final double? actualWeight;
  final int? actualReps;
  final int? actualDurationSeconds;
  final int? restSeconds;
  final bool hasActualValues;
  final DateTime createdAt;

  const LocalWorkoutLogEditModel({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.note,
    this.recordMode = localRecordModeStandard,
    this.durationSeconds = 0,
    this.actualWeight,
    this.actualReps,
    this.actualDurationSeconds,
    this.restSeconds,
    this.hasActualValues = false,
    required this.createdAt,
  });

  double? get recordedWeight => hasActualValues ? actualWeight : weight;
  int? get recordedReps => hasActualValues ? actualReps : reps;
  int? get recordedDurationSeconds => hasActualValues ? actualDurationSeconds : durationSeconds;
}

class LocalWorkoutInputDraft {
  final int actionIndex;
  final int setIndex;
  final String weightText;
  final String repsText;
  final String durationText;
  final String restText;
  final String noteText;

  const LocalWorkoutInputDraft({
    required this.actionIndex,
    required this.setIndex,
    this.weightText = '',
    this.repsText = '',
    this.durationText = '',
    this.restText = '',
    this.noteText = '',
  });

  LocalWorkoutInputDraft copyWith({
    String? weightText,
    String? repsText,
    String? durationText,
    String? restText,
    String? noteText,
  }) {
    return LocalWorkoutInputDraft(
      actionIndex: actionIndex,
      setIndex: setIndex,
      weightText: weightText ?? this.weightText,
      repsText: repsText ?? this.repsText,
      durationText: durationText ?? this.durationText,
      restText: restText ?? this.restText,
      noteText: noteText ?? this.noteText,
    );
  }
}

class LocalWorkoutSessionEditModel {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? dayId;
  final String routineName;
  final String routineSyncId;
  final String dayName;
  final int? dayWeek;
  final int? dayIndex;
  final String daySyncId;
  final String note;
  final List<LocalWorkoutLogEditModel> logs;

  const LocalWorkoutSessionEditModel({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    this.dayId,
    this.routineName = '',
    this.routineSyncId = '',
    this.dayName = '',
    this.dayWeek,
    this.dayIndex,
    this.daySyncId = '',
    required this.note,
    required this.logs,
  });
}

class LocalWorkoutSessionResumeModel {
  final int sessionId;
  final DateTime startedAt;
  final List<LocalWorkoutLogEditModel> logs;
  final List<LocalWorkoutInputDraft> drafts;

  const LocalWorkoutSessionResumeModel({
    required this.sessionId,
    required this.startedAt,
    required this.logs,
    this.drafts = const [],
  });
}

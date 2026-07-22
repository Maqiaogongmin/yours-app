part of 'yours_vault_service.dart';

mixin _YoursVaultExportMixin {
  LocalTrainingDatabase get _trainingDb;
  CustomExerciseDatabase get _exerciseDb;
  Future<void> _writeJson(File file, Object? data);
  List<String> _decodeStringList(String value);
  String _slug(String value);
  Future<YoursVaultExportResult> exportVault(Directory directory) async {
    final exportedAt = DateTime.now();
    await _ensureVaultDirectories(directory);

    final planCount = await _exportPlans(directory);
    final workoutCount = await _exportWorkoutLogs(directory);
    final exerciseCount = await _exportExercises(directory);
    await _writeJson(
      File(p.join(directory.path, 'manifest.json')),
      {
        'format': 'yours-vault',
        'formatVersion': 1,
        'appName': 'Yours',
        'exportedAt': exportedAt.toIso8601String(),
        'contains': {
          'plans': planCount,
          'workouts': workoutCount,
          'customExercises': exerciseCount,
          'reports': true,
        },
        'directories': {
          'plans': 'plans',
          'logs': 'logs',
          'exercises': 'exercises',
          'inbox': 'inbox',
          'reports': 'reports',
        },
      },
    );

    return YoursVaultExportResult(
      directory: directory,
      planCount: planCount,
      workoutCount: workoutCount,
      exerciseCount: exerciseCount,
      exportedAt: exportedAt,
    );
  }

  Future<void> _ensureVaultDirectories(Directory directory) async {
    for (final name in ['plans', 'logs', 'exercises', 'inbox', 'reports']) {
      Directory(p.join(directory.path, name)).createSync(recursive: true);
    }
    await File(p.join(directory.path, 'inbox', 'README.txt')).writeAsString(
      'Yours Vault inbox\n\n'
      '将 *.plan.json 或 *.exercise.json 文件放入此目录，然后在有思中选择“导入 inbox”。\n'
      '导入成功的文件会移动到 imported 子目录。\n',
      flush: true,
    );
    await File(p.join(directory.path, 'reports', 'README.txt')).writeAsString(
      'Yours Vault reports\n\n有思生成的报告会保存在此目录。\n',
      flush: true,
    );
  }

  Future<int> _exportPlans(Directory directory) async {
    final repository = LocalTrainingRepository(_trainingDb);
    final plans = await repository.getPlans();
    for (final plan in plans) {
      final idSuffix = plan.id == null ? '' : '-${plan.id}';
      await _writeJson(
        File(p.join(directory.path, 'plans', '${_slug(plan.name)}$idSuffix.plan.json')),
        _planToVaultJson(plan),
      );
    }
    return plans.length;
  }

  Future<int> _exportWorkoutLogs(Directory directory) async {
    final sessions = await (_trainingDb.select(
      _trainingDb.localWorkoutSessions,
    )..orderBy([(row) => OrderingTerm.asc(row.startedAt)])).get();
    final routines = {
      for (final row in await _trainingDb.select(_trainingDb.localRoutines).get()) row.id: row,
    };
    final days = {
      for (final row in await _trainingDb.select(_trainingDb.localTrainingDays).get()) row.id: row,
    };

    var count = 0;
    for (final session in sessions) {
      final logs =
          await (_trainingDb.select(_trainingDb.localWorkoutLogs)
                ..where((log) => log.sessionId.equals(session.id))
                ..orderBy([
                  (log) => OrderingTerm.asc(log.createdAt),
                  (log) => OrderingTerm.asc(log.setIndex),
                ]))
              .get();
      if (logs.isEmpty) {
        continue;
      }

      final year = session.startedAt.year.toString().padLeft(4, '0');
      final month = session.startedAt.month.toString().padLeft(2, '0');
      final day = session.startedAt.day.toString().padLeft(2, '0');
      final logDir = Directory(p.join(directory.path, 'logs', year, month))
        ..createSync(recursive: true);
      await _writeJson(
        File(p.join(logDir.path, '$year-$month-$day-session-${session.id}.workout.json')),
        {
          'format': 'yours-workout',
          'formatVersion': 1,
          'id': session.id,
          'routineId': session.routineId,
          'routineName': routines[session.routineId]?.name ?? '',
          'dayId': session.dayId,
          'dayName': session.dayId == null ? '' : days[session.dayId]?.name ?? '',
          'startedAt': session.startedAt.toIso8601String(),
          'endedAt': session.endedAt?.toIso8601String(),
          'note': session.note,
          'incomplete': session.note.contains('未完成训练计划'),
          'logs': logs
              .map(
                (log) => {
                  'id': log.id,
                  'exercise': log.exerciseName,
                  'setIndex': log.setIndex,
                  'weight': log.weight,
                  'reps': log.reps,
                  'rir': log.rir,
                  'durationSeconds': log.durationSeconds,
                  if (log.hasActualValues) 'hasActualValues': true,
                  if (log.actualWeight != null) 'actualWeight': log.actualWeight,
                  if (log.actualReps != null) 'actualReps': log.actualReps,
                  if (log.actualDurationSeconds != null)
                    'actualDurationSeconds': log.actualDurationSeconds,
                  if (log.restSeconds != null) 'restSeconds': log.restSeconds,
                  if (normalizeLocalRecordMode(log.recordMode) != localRecordModeStandard)
                    'recordMode': normalizeLocalRecordMode(log.recordMode),
                  'note': log.note,
                  'createdAt': log.createdAt.toIso8601String(),
                },
              )
              .toList(),
        },
      );
      count += 1;
    }
    return count;
  }

  Future<int> _exportExercises(Directory directory) async {
    final rows =
        await (_exerciseDb.select(_exerciseDb.customExercises)
              ..where((row) => row.deleted.equals(false))
              ..orderBy([
                (row) => OrderingTerm.asc(row.bodyPart),
                (row) => OrderingTerm.asc(row.chineseName),
              ]))
            .get();
    await _writeJson(
      File(p.join(directory.path, 'exercises', 'custom-exercises.json')),
      {
        'format': 'yours-custom-exercises',
        'formatVersion': 1,
        'exercises': rows
            .map(
              (row) => {
                'id': row.id,
                'remoteId': row.remoteId,
                'chineseName': row.chineseName,
                'englishName': row.englishName,
                'bodyPart': row.bodyPart,
                'equipment': row.equipment,
                'primaryMuscles': row.primaryMuscles,
                'description': row.description,
                'imagePaths': _decodeStringList(row.imagePathsJson),
                'isCustom': row.isCustom,
                'syncStatus': row.syncStatus,
                'deleted': row.deleted,
                'createdAt': row.createdAt.toIso8601String(),
                'updatedAt': row.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      },
    );
    return rows.length;
  }

  Map<String, Object?> _planToVaultJson(LocalTrainingPlanModel plan) {
    final days = plan.days.values.toList()
      ..sort((a, b) {
        final weekCompare = a.week.compareTo(b.week);
        return weekCompare != 0 ? weekCompare : a.day.compareTo(b.day);
      });
    final weeks = <int, List<LocalTrainingDayModel>>{};
    for (final day in days) {
      weeks.putIfAbsent(day.week, () => []).add(day);
    }
    return {
      'format': 'yours-plan',
      'formatVersion': 1,
      'id': plan.id,
      'name': plan.name,
      'totalWeeks': plan.totalWeeks,
      'daysPerWeek': plan.daysPerWeek,
      'archived': plan.archived,
      'completedWeeks': plan.completedWeeks.toList()..sort(),
      'syncStatus': plan.syncStatus,
      'weeks': weeks.entries
          .map(
            (entry) => {
              'week': entry.key,
              'days': entry.value
                  .map(
                    (day) => {
                      'id': day.id,
                      'day': day.day,
                      'name': day.name,
                      'actions': day.actions
                          .map(
                            (action) => {
                              'exercise': action.name,
                              'sets': action.targetSets,
                              'reps': action.targetReps,
                              'weight': action.targetWeight,
                              'restSeconds': action.targetRestSeconds,
                              'durationSeconds': action.targetDurationSeconds,
                              if (action.recordMode != localRecordModeStandard)
                                'recordMode': action.recordMode,
                              'note': action.note,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }
}

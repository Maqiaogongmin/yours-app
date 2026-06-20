import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';

class YoursVaultExportResult {
  final Directory directory;
  final int planCount;
  final int workoutCount;
  final int exerciseCount;
  final DateTime exportedAt;

  const YoursVaultExportResult({
    required this.directory,
    required this.planCount,
    required this.workoutCount,
    required this.exerciseCount,
    required this.exportedAt,
  });
}

class YoursVaultImportResult {
  final int importedPlans;
  final int importedExercises;
  final List<String> importedFiles;
  final List<String> skippedFiles;
  final List<YoursVaultImportFileResult> fileResults;

  const YoursVaultImportResult({
    required this.importedPlans,
    required this.importedExercises,
    required this.importedFiles,
    required this.skippedFiles,
    this.fileResults = const [],
  });

  List<YoursVaultImportFileResult> get failedFiles =>
      fileResults.where((result) => result.status == 'failed').toList();
}

class YoursVaultImportFileResult {
  final String fileName;
  final String type;
  final String status;
  final String message;
  final List<String> missingExercises;

  const YoursVaultImportFileResult({
    required this.fileName,
    required this.type,
    required this.status,
    required this.message,
    this.missingExercises = const [],
  });
}

class YoursVaultService {
  static const _visibleFilesChannel = MethodChannel('yours/files');

  final LocalTrainingDatabase? _trainingDbOverride;
  final CustomExerciseDatabase? _exerciseDbOverride;

  YoursVaultService({
    LocalTrainingDatabase? trainingDb,
    CustomExerciseDatabase? exerciseDb,
  }) : _trainingDbOverride = trainingDb,
       _exerciseDbOverride = exerciseDb;

  LocalTrainingDatabase get _trainingDb =>
      _trainingDbOverride ??
      (locator.isRegistered<LocalTrainingDatabase>()
          ? locator<LocalTrainingDatabase>()
          : throw StateError('训练数据库尚未就绪，请稍后再试。'));

  CustomExerciseDatabase get _exerciseDb =>
      _exerciseDbOverride ??
      (locator.isRegistered<CustomExerciseDatabase>()
          ? locator<CustomExerciseDatabase>()
          : throw StateError('动作数据库尚未就绪，请稍后再试。'));

  Future<Directory> defaultVaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'YoursVault'));
  }

  Future<YoursVaultExportResult> exportDefaultVault() async {
    final result = await exportVault(await defaultVaultDirectory());
    if (Platform.isAndroid) {
      unawaited(_syncVaultToVisibleDocuments(result.directory));
    } else {
      await _syncVaultToVisibleDocuments(result.directory);
    }
    return result;
  }

  Future<YoursVaultImportResult> importDefaultInbox() async {
    return importInbox(await defaultVaultDirectory());
  }

  Future<void> _syncVaultToVisibleDocuments(Directory directory) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      if (Platform.isIOS) {
        await _visibleFilesChannel.invokeMethod<String>(
          'exportVaultToICloudDrive',
          {'path': directory.path},
        );
      } else {
        await _visibleFilesChannel.invokeMethod<int>(
          'syncVaultToPublicDocuments',
          {'path': directory.path},
        );
      }
    } on MissingPluginException {
      if (Platform.isIOS) {
        throw StateError('当前安装包缺少 iCloud Drive 文件通道。');
      }
      return;
    } on PlatformException catch (error) {
      if (Platform.isIOS) {
        final message = error.message?.trim();
        throw StateError(
          message == null || message.isEmpty ? 'iCloud Drive 导出失败。' : message,
        );
      }
      return;
    }
  }

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

  Future<YoursVaultImportResult> importInbox(Directory vaultDirectory) async {
    final inbox = Directory(p.join(vaultDirectory.path, 'inbox'));
    if (!inbox.existsSync()) {
      return const YoursVaultImportResult(
        importedPlans: 0,
        importedExercises: 0,
        importedFiles: [],
        skippedFiles: [],
      );
    }

    final exerciseFiles =
        await inbox
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.exercise.json'))
              .cast<File>()
              .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final planFiles =
        await inbox
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.plan.json'))
              .cast<File>()
              .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final repository = LocalTrainingRepository(_trainingDb);
    final exerciseRepository = CustomExerciseRepository(_exerciseDb);
    final imported = <String>[];
    final skipped = <String>[];
    final fileResults = <YoursVaultImportFileResult>[];
    var importedExercises = 0;
    var importedPlans = 0;
    for (final file in exerciseFiles) {
      final fileName = p.basename(file.path);
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        final result = await _importExerciseInboxFile(decoded, exerciseRepository);
        importedExercises += result;
        await _archiveInboxFile(file, 'imported');
        imported.add(fileName);
        fileResults.add(
          YoursVaultImportFileResult(
            fileName: fileName,
            type: 'exercise',
            status: 'imported',
            message: '已导入 $result 个动作',
          ),
        );
      } on Object catch (error) {
        skipped.add(fileName);
        fileResults.add(
          YoursVaultImportFileResult(
            fileName: fileName,
            type: 'exercise',
            status: 'failed',
            message: _friendlyImportError(error),
          ),
        );
      }
    }

    final exerciseKeys = await _exerciseKeys();
    for (final file in planFiles) {
      final fileName = p.basename(file.path);
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        final plan = _planFromVaultJson(decoded);
        final missingExercises = _missingExercises(plan, exerciseKeys);
        if (missingExercises.isNotEmpty) {
          skipped.add(fileName);
          fileResults.add(
            YoursVaultImportFileResult(
              fileName: fileName,
              type: 'plan',
              status: 'failed',
              message: '缺少动作：${missingExercises.join('、')}',
              missingExercises: missingExercises,
            ),
          );
          continue;
        }
        final targetPlan = await _resolvePlanImportTarget(decoded, plan);
        final importPlan = targetPlan == null ? plan : _mergePlanForUpdate(targetPlan, plan);
        await repository.savePlan(importPlan);
        await _archiveInboxFile(file, 'imported');
        imported.add(fileName);
        importedPlans += 1;
        fileResults.add(
          YoursVaultImportFileResult(
            fileName: fileName,
            type: 'plan',
            status: 'imported',
            message: targetPlan == null ? '已新建计划「${plan.name}」' : '已更新计划「${targetPlan.name}」',
          ),
        );
      } on Object catch (error) {
        skipped.add(fileName);
        fileResults.add(
          YoursVaultImportFileResult(
            fileName: fileName,
            type: 'plan',
            status: 'failed',
            message: _friendlyImportError(error),
          ),
        );
      }
    }

    return YoursVaultImportResult(
      importedPlans: importedPlans,
      importedExercises: importedExercises,
      importedFiles: imported,
      skippedFiles: skipped,
      fileResults: fileResults,
    );
  }

  Future<void> _ensureVaultDirectories(Directory directory) async {
    for (final name in ['plans', 'logs', 'exercises', 'inbox', 'reports']) {
      Directory(p.join(directory.path, name)).createSync(recursive: true);
    }
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

  LocalTrainingPlanModel _planFromVaultJson(Object? decoded) {
    if (decoded is! Map) {
      throw const FormatException('Plan JSON must be an object.');
    }
    final format = decoded['format'] as String?;
    if (format != null && format != 'yours-plan') {
      throw FormatException('Unsupported plan format: $format.');
    }
    final formatVersion = decoded['formatVersion'];
    if (formatVersion != null && formatVersion != 1) {
      throw FormatException('Unsupported plan formatVersion: $formatVersion.');
    }
    final name = (decoded['name'] as String? ?? '').trim();
    final weeks = decoded['weeks'];
    if (name.isEmpty || weeks is! List || weeks.isEmpty) {
      throw const FormatException('Plan JSON is missing name or weeks.');
    }

    final plan = LocalTrainingPlanModel(
      name: name,
      totalWeeks: (decoded['totalWeeks'] as num?)?.toInt() ?? weeks.length,
      daysPerWeek: (decoded['daysPerWeek'] as num?)?.toInt() ?? 7,
      archived: decoded['archived'] as bool? ?? false,
      completedWeeks: (decoded['completedWeeks'] as List? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .where((value) => value > 0)
          .toSet(),
    );
    for (final weekData in weeks.whereType<Map>()) {
      final week = (weekData['week'] as num?)?.toInt() ?? 1;
      final days = weekData['days'];
      if (days is! List) {
        continue;
      }
      for (final dayData in days.whereType<Map>()) {
        final day = (dayData['day'] as num?)?.toInt() ?? 1;
        final rawActions = dayData['actions'];
        if (rawActions is! List) {
          throw FormatException('Plan JSON day W$week-D$day is missing actions.');
        }
        final actions = <LocalTrainingActionModel>[];
        for (var index = 0; index < rawActions.length; index++) {
          final action = rawActions[index];
          if (action is! Map) {
            throw FormatException('Plan JSON action W$week-D$day #${index + 1} must be an object.');
          }
          final actionName = canonicalExerciseReference(
            action['exercise'] as String? ?? action['name'] as String? ?? '',
          );
          if (actionName.isEmpty) {
            throw FormatException(
              'Plan JSON action W$week-D$day #${index + 1} is missing exercise.',
            );
          }
          actions.add(
            LocalTrainingActionModel(
              name: actionName,
              targetSets: (action['sets'] as num?)?.toInt() ?? 3,
              targetReps: _parseTargetReps(action['reps']),
              targetWeight: (action['weight'] as num?)?.toDouble(),
              targetRestSeconds: (action['restSeconds'] as num?)?.toInt(),
              targetDurationSeconds: (action['durationSeconds'] as num?)?.toInt(),
              recordMode: normalizeLocalRecordMode(action['recordMode']),
              note: action['note'] as String? ?? '',
            ),
          );
        }
        plan.days['$week-$day'] = LocalTrainingDayModel(
          week: week,
          day: day,
          name: dayData['name'] as String? ?? 'D$day',
          actions: actions,
        );
      }
    }
    return plan;
  }

  int _parseTargetReps(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final match = RegExp(r'\d+').firstMatch(value);
      if (match != null) {
        return int.parse(match.group(0)!);
      }
    }
    return 8;
  }

  Future<LocalTrainingPlanModel?> _resolvePlanImportTarget(
    Object? decoded,
    LocalTrainingPlanModel plan,
  ) async {
    if (decoded is! Map) {
      return null;
    }
    final action = (decoded['action'] as String? ?? 'upsert').trim().toLowerCase();
    if (!const {'create', 'update', 'upsert'}.contains(action)) {
      throw FormatException('Unsupported plan action: $action.');
    }
    if (action == 'create') {
      return null;
    }

    final plans = await LocalTrainingRepository(_trainingDb).getPlans();
    LocalTrainingPlanModel? match;
    final syncId = (decoded['syncId'] as String? ?? '').trim();
    if (syncId.isNotEmpty) {
      match = _singlePlanMatch(
        plans.where((candidate) => candidate.syncId == syncId).toList(),
        'syncId',
        syncId,
      );
      if (match != null) {
        return match;
      }
    }

    final id = (decoded['id'] as num?)?.toInt();
    if (id != null) {
      match = _singlePlanMatch(
        plans.where((candidate) => candidate.id == id).toList(),
        'id',
        '$id',
      );
      if (match != null) {
        return match;
      }
    }

    final matchName = (decoded['matchName'] as String? ?? '').trim();
    if (matchName.isNotEmpty) {
      match = _singlePlanMatch(
        plans.where((candidate) => candidate.name == matchName).toList(),
        'matchName',
        matchName,
      );
      if (match != null) {
        return match;
      }
      if (action == 'update') {
        throw FormatException('No existing plan matches "$matchName".');
      }
    }

    match = _singlePlanMatch(
      plans.where((candidate) => candidate.name == plan.name).toList(),
      'name',
      plan.name,
    );
    if (match != null) {
      return match;
    }
    if (action == 'update') {
      throw FormatException('No existing plan matches "${plan.name}".');
    }
    return null;
  }

  LocalTrainingPlanModel? _singlePlanMatch(
    List<LocalTrainingPlanModel> matches,
    String field,
    String value,
  ) {
    if (matches.length > 1) {
      throw FormatException('Multiple existing plans match $field "$value".');
    }
    return matches.isEmpty ? null : matches.single;
  }

  LocalTrainingPlanModel _mergePlanForUpdate(
    LocalTrainingPlanModel existing,
    LocalTrainingPlanModel incoming,
  ) {
    return LocalTrainingPlanModel(
      id: existing.id,
      syncId: existing.syncId,
      name: incoming.name,
      totalWeeks: incoming.totalWeeks,
      daysPerWeek: incoming.daysPerWeek,
      archived: existing.archived,
      completedWeeks: Set<int>.of(existing.completedWeeks),
      syncStatus: existing.syncStatus,
      days: incoming.days.map((key, value) => MapEntry(key, value.copyWith())),
    );
  }

  Future<int> _importExerciseInboxFile(
    Object? decoded,
    CustomExerciseRepository repository,
  ) async {
    final operations = _exerciseOperationsFromVaultJson(decoded);
    var count = 0;
    for (final operation in operations) {
      final action = (operation['action'] as String? ?? 'upsert').trim().toLowerCase();
      if (action == 'delete') {
        final existing = await _findExerciseForOperation(operation);
        if (existing == null) {
          continue;
        }
        await repository.deleteExercise(existing);
        count += 1;
        continue;
      }

      final name = (operation['chineseName'] as String? ?? operation['name'] as String? ?? '')
          .trim();
      if (name.isEmpty) {
        throw const FormatException('Exercise JSON is missing name.');
      }
      final existing = await _findExerciseForOperation(operation);
      await repository.saveExercise(
        CustomExerciseModel(
          id: existing?.id,
          remoteId: existing?.remoteId,
          chineseName: name,
          englishName: (operation['englishName'] as String? ?? existing?.englishName ?? '').trim(),
          bodyPart: (operation['category1'] as String? ?? operation['bodyPart'] as String? ?? '')
              .trim(),
          equipment: (operation['category2'] as String? ?? operation['equipment'] as String? ?? '')
              .trim(),
          primaryMuscles: (operation['primaryMuscles'] as String? ?? existing?.primaryMuscles ?? '')
              .trim(),
          description: (operation['description'] as String? ?? existing?.description ?? '').trim(),
          imagePaths: (operation['imagePaths'] as List? ?? existing?.imagePaths ?? const [])
              .whereType<String>()
              .toList(),
          isCustom: true,
          createdAt: existing?.createdAt,
        ),
      );
      count += 1;
    }
    return count;
  }

  List<Map<String, Object?>> _exerciseOperationsFromVaultJson(Object? decoded) {
    if (decoded is! Map) {
      throw const FormatException('Exercise JSON must be an object.');
    }
    final exercises = decoded['exercises'];
    if (exercises is List) {
      return exercises.whereType<Map>().map((item) => Map<String, Object?>.from(item)).toList();
    }
    return [Map<String, Object?>.from(decoded)];
  }

  Future<CustomExerciseModel?> _findExerciseForOperation(Map<String, Object?> operation) async {
    final id = (operation['id'] as num?)?.toInt();
    final names = [
      operation['matchName'],
      operation['oldName'],
      operation['chineseName'],
      operation['name'],
      operation['englishName'],
    ].whereType<String>().map(_normalizeExerciseKey).where((value) => value.isNotEmpty).toSet();
    final rows = await (_exerciseDb.select(
      _exerciseDb.customExercises,
    )..where((row) => row.deleted.equals(false))).get();
    for (final row in rows) {
      if (id != null && row.id == id) {
        return _exerciseFromRow(row);
      }
      final rowKeys = {
        _normalizeExerciseKey(row.chineseName),
        _normalizeExerciseKey(row.englishName),
      };
      if (names.any(rowKeys.contains)) {
        return _exerciseFromRow(row);
      }
    }
    return null;
  }

  CustomExerciseModel _exerciseFromRow(CustomExercise row) {
    return CustomExerciseModel(
      id: row.id,
      remoteId: row.remoteId,
      chineseName: row.chineseName,
      englishName: row.englishName,
      bodyPart: row.bodyPart,
      equipment: row.equipment,
      primaryMuscles: row.primaryMuscles,
      description: row.description,
      imagePaths: _decodeStringList(row.imagePathsJson),
      isCustom: row.isCustom,
      syncStatus: row.syncStatus,
      deleted: row.deleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> _writeJson(File file, Object? data) async {
    file.parent.createSync(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }

  Future<void> _archiveInboxFile(File file, String folderName) async {
    final destinationDir = Directory(p.join(file.parent.path, folderName))
      ..createSync(recursive: true);
    final destination = File(p.join(destinationDir.path, p.basename(file.path)));
    if (destination.existsSync()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await file.rename(p.join(destinationDir.path, '$timestamp-${p.basename(file.path)}'));
      return;
    }
    await file.rename(destination.path);
  }

  List<String> _decodeStringList(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<Set<String>> _exerciseKeys() async {
    final rows = await (_exerciseDb.select(
      _exerciseDb.customExercises,
    )..where((row) => row.deleted.equals(false))).get();
    final keys = <String>{};
    for (final row in rows) {
      keys.add(_normalizeExerciseKey(row.chineseName));
      keys.add(
        _normalizeExerciseKey(canonicalExerciseReference(row.chineseName)),
      );
      if (row.englishName.trim().isNotEmpty) {
        keys.add(_normalizeExerciseKey(row.englishName));
        keys.add(
          _normalizeExerciseKey(
            canonicalExerciseReference(row.englishName),
          ),
        );
      }
      final reference = builtInExerciseReferenceForRemoteId(row.remoteId);
      if (reference != null) {
        keys.add(_normalizeExerciseKey(reference));
      }
    }
    return keys;
  }

  List<String> _missingExercises(LocalTrainingPlanModel plan, Set<String> exerciseKeys) {
    final missing = <String>[];
    final seen = <String>{};
    for (final day in plan.days.values) {
      for (final action in day.actions) {
        final key = _normalizeExerciseKey(
          canonicalExerciseReference(action.name),
        );
        if (!exerciseKeys.contains(key) && seen.add(key)) {
          missing.add(action.name);
        }
      }
    }
    return missing;
  }

  String _normalizeExerciseKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  String _friendlyImportError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    final message = '$error'.trim();
    return message.isEmpty ? '导入失败。' : message;
  }

  String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'untitled-plan' : slug;
  }
}

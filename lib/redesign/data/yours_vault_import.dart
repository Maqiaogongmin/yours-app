part of 'yours_vault_service.dart';

mixin _YoursVaultImportMixin {
  LocalTrainingDatabase get _trainingDb;
  CustomExerciseDatabase get _exerciseDb;
  Future<int> Function(Object?, CustomExerciseRepository) get _exerciseInboxImporter;
  Future<void> _archiveInboxFile(File file, String folderName);
  Future<Set<String>> _exerciseKeys();
  List<String> _missingExercises(
    LocalTrainingPlanModel plan,
    Set<String> exerciseKeys,
  );
  String _friendlyImportError(Object error);
  Future<YoursVaultImportResult> importInbox(
    Directory vaultDirectory, {
    bool archiveImportedFiles = true,
  }) async {
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
        final result = await _exerciseInboxImporter(decoded, exerciseRepository);
        importedExercises += result;
        if (archiveImportedFiles) {
          await _archiveInboxFile(file, 'imported');
        }
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
        if (archiveImportedFiles) {
          await _archiveInboxFile(file, 'imported');
        }
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
          final recordMode = normalizeLocalRecordMode(action['recordMode']);
          actions.add(
            LocalTrainingActionModel(
              name: actionName,
              targetSets: (action['sets'] as num?)?.toInt(),
              targetReps: _parseTargetReps(action['reps']),
              targetWeight: (action['weight'] as num?)?.toDouble(),
              targetRestSeconds: (action['restSeconds'] as num?)?.toInt(),
              targetDurationSeconds: (action['durationSeconds'] as num?)?.toInt(),
              recordMode: recordMode,
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
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/exercise_standardization.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';

class CustomExerciseRepository {
  final CustomExerciseDatabase _initialDatabase;

  CustomExerciseRepository(this._initialDatabase);

  CustomExerciseDatabase get database => locator.isRegistered<CustomExerciseDatabase>()
      ? locator<CustomExerciseDatabase>()
      : _initialDatabase;

  LocalSyncQueueRepository? get _syncQueue => locator.isRegistered<LocalTrainingDatabase>()
      ? LocalSyncQueueRepository(locator<LocalTrainingDatabase>())
      : null;

  Future<void> ensureSeedData() async {
    final existing = await (database.select(
      database.customExercises,
    )..where((exercise) => exercise.deleted.equals(false))).get();

    if (existing.isEmpty) {
      await _insertSeedExercises();
      return;
    }

    await _ensureStandardCatalog();
  }

  Future<void> _insertSeedExercises() async {
    if (await _tryImportSeedAsset()) {
      return;
    }

    final now = DateTime.now();
    await database.batch((batch) {
      batch.insertAll(
        database.customExercises,
        standardExerciseCatalog.map((exercise) {
          return CustomExercisesCompanion.insert(
            chineseName: exercise.chineseName,
            englishName: Value(exercise.englishName),
            bodyPart: exercise.bodyPart,
            equipment: exercise.equipment,
            primaryMuscles: exercise.primaryMuscles,
            description: exercise.description,
            imagePathsJson: Value(exercise.imagePathsJson),
            isCustom: Value(exercise.builtInKey == null),
            syncStatus: const Value(localSyncSynced),
            createdAt: now,
            updatedAt: now,
          );
        }).toList(),
      );
    });
  }

  Future<bool> _tryImportSeedAsset() async {
    List<dynamic> rows;
    try {
      final raw = await rootBundle.loadString('assets/data/custom_exercises_seed.json');
      final decoded = jsonDecode(raw);
      rows = decoded is List ? decoded : decoded['exercises'] as List<dynamic>? ?? const [];
    } on Object {
      return false;
    }

    final exercises = rows
        .whereType<Map>()
        .map((row) => CustomExerciseModel.fromJson(Map<String, dynamic>.from(row)))
        .where((exercise) => exercise.chineseName.trim().isNotEmpty)
        .toList();
    if (exercises.isEmpty) {
      return false;
    }

    await database.batch((batch) {
      batch.insertAll(
        database.customExercises,
        exercises.map((exercise) {
          return CustomExercisesCompanion.insert(
            remoteId: Value(exercise.remoteId),
            chineseName: exercise.chineseName,
            englishName: Value(exercise.englishName),
            bodyPart: exercise.bodyPart,
            equipment: exercise.equipment,
            primaryMuscles: exercise.primaryMuscles,
            description: exercise.description,
            imagePathsJson: Value(jsonEncode(exercise.imagePaths)),
            isCustom: Value(exercise.builtInKey == null),
            syncStatus: const Value(localSyncSynced),
            deleted: Value(exercise.deleted),
            createdAt: exercise.createdAt,
            updatedAt: exercise.updatedAt,
          );
        }).toList(),
      );
    });
    return true;
  }

  Future<void> _ensureStandardCatalog() async {
    final rows = await database.select(database.customExercises).get();
    final knownKeys = <String, CustomExercise>{};
    for (final row in rows) {
      knownKeys[normalizeExerciseKey(row.chineseName)] = row;
      if (row.englishName.trim().isNotEmpty) {
        knownKeys[normalizeExerciseKey(row.englishName)] = row;
      }
      final standardChineseName = standardExerciseNameFor(row.chineseName);
      if (standardChineseName != row.chineseName) {
        knownKeys[normalizeExerciseKey(standardChineseName)] = row;
      }
      final standardEnglishName = standardExerciseNameFor(row.englishName);
      if (standardEnglishName != row.englishName) {
        knownKeys[normalizeExerciseKey(standardEnglishName)] = row;
      }
    }

    final now = DateTime.now();
    for (final exercise in standardExerciseCatalog) {
      final existing =
          knownKeys[normalizeExerciseKey(exercise.chineseName)] ??
          knownKeys[normalizeExerciseKey(exercise.englishName)];
      if (existing != null) {
        if (existing.remoteId != exercise.remoteId || existing.isCustom) {
          await (database.update(
            database.customExercises,
          )..where((row) => row.id.equals(existing.id))).write(
            CustomExercisesCompanion(
              remoteId: Value(exercise.remoteId),
              isCustom: const Value(false),
            ),
          );
        }
      } else {
        await database
            .into(database.customExercises)
            .insert(
              CustomExercisesCompanion.insert(
                chineseName: exercise.chineseName,
                englishName: Value(exercise.englishName),
                bodyPart: exercise.bodyPart,
                equipment: exercise.equipment,
                primaryMuscles: exercise.primaryMuscles,
                description: exercise.description,
                imagePathsJson: Value(exercise.imagePathsJson),
                isCustom: Value(exercise.builtInKey == null),
                syncStatus: const Value(localSyncSynced),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }
  }

  Future<List<CustomExerciseModel>> listExercises() async {
    final rows =
        await (database.select(database.customExercises)
              ..where((exercise) => exercise.deleted.equals(false))
              ..orderBy([
                (exercise) => OrderingTerm(expression: exercise.bodyPart),
                (exercise) => OrderingTerm(expression: exercise.chineseName),
              ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  Future<List<CustomExerciseModel>> searchExercises({
    String query = '',
    String filter = '全部',
  }) async {
    final q = query.trim().toLowerCase();
    final exercises = await listExercises();
    return exercises.where((exercise) {
      final passFilter =
          filter == '全部' || exercise.bodyPart == filter || exercise.equipment == filter;
      final passSearch = q.isEmpty || exercise.searchableText.contains(q);
      return passFilter && passSearch;
    }).toList();
  }

  Future<int> saveExercise(CustomExerciseModel exercise) async {
    final now = DateTime.now();
    if (exercise.id == null) {
      final exerciseId = await database
          .into(database.customExercises)
          .insert(
            CustomExercisesCompanion.insert(
              syncId: Value(exercise.syncId),
              remoteId: Value(exercise.remoteId),
              chineseName: exercise.chineseName,
              englishName: Value(exercise.englishName),
              bodyPart: exercise.bodyPart,
              equipment: exercise.equipment,
              primaryMuscles: exercise.primaryMuscles,
              description: exercise.description,
              imagePathsJson: Value(jsonEncode(exercise.imagePaths)),
              isCustom: Value(exercise.isCustom),
              syncStatus: const Value(localSyncPending),
              deleted: Value(exercise.deleted),
              createdAt: exercise.createdAt,
              updatedAt: now,
            ),
          );
      await _safeEnqueueExerciseChange(exerciseId, 'create', exercise);
      return exerciseId;
    }

    await (database.update(
      database.customExercises,
    )..where((row) => row.id.equals(exercise.id!))).write(
      CustomExercisesCompanion(
        syncId: Value(exercise.syncId),
        remoteId: Value(exercise.remoteId),
        chineseName: Value(exercise.chineseName),
        englishName: Value(exercise.englishName),
        bodyPart: Value(exercise.bodyPart),
        equipment: Value(exercise.equipment),
        primaryMuscles: Value(exercise.primaryMuscles),
        description: Value(exercise.description),
        imagePathsJson: Value(jsonEncode(exercise.imagePaths)),
        isCustom: Value(exercise.isCustom),
        syncStatus: const Value(localSyncPending),
        deleted: Value(exercise.deleted),
        updatedAt: Value(now),
      ),
    );
    await _safeEnqueueExerciseChange(exercise.id!, 'update', exercise);
    return exercise.id!;
  }

  Future<void> deleteExercise(CustomExerciseModel exercise) async {
    if (exercise.id == null) {
      return;
    }
    await (database.update(
      database.customExercises,
    )..where((row) => row.id.equals(exercise.id!))).write(
      CustomExercisesCompanion(
        deleted: const Value(true),
        syncStatus: const Value(localSyncPending),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _safeEnqueueExerciseDelete(exercise);
  }

  Future<int> importJsonList(List<Map<String, dynamic>> rows) async {
    var count = 0;
    for (final row in rows) {
      final exercise = CustomExerciseModel.fromJson(row);
      if (exercise.chineseName.trim().isEmpty) {
        continue;
      }
      await saveExercise(exercise);
      count += 1;
    }
    return count;
  }

  CustomExerciseModel _fromRow(CustomExercise row) {
    List<String> imagePaths;
    try {
      imagePaths = (jsonDecode(row.imagePathsJson) as List<dynamic>).whereType<String>().toList();
    } catch (_) {
      imagePaths = [];
    }

    return CustomExerciseModel(
      id: row.id,
      syncId: row.syncId,
      remoteId: row.remoteId,
      chineseName: row.chineseName,
      englishName: row.englishName,
      bodyPart: row.bodyPart,
      equipment: row.equipment,
      primaryMuscles: row.primaryMuscles,
      description: row.description,
      imagePaths: imagePaths,
      isCustom: row.isCustom,
      syncStatus: row.syncStatus,
      deleted: row.deleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> _safeEnqueueExerciseChange(
    int id,
    String action,
    CustomExerciseModel exercise,
  ) async {
    try {
      await _syncQueue?.enqueue(
        'custom_exercise',
        id,
        action,
        entitySyncId: 'custom_exercise:${exercise.syncId}',
        payload: {
          'chineseName': exercise.chineseName,
          'englishName': exercise.englishName,
          'bodyPart': exercise.bodyPart,
          'equipment': exercise.equipment,
          'primaryMuscles': exercise.primaryMuscles,
          'isCustom': exercise.isCustom,
        },
      );
    } on Object {
      // 动作库自身仍有 syncStatus=pending，可作为后续补队列的兜底。
    }
  }

  Future<void> _safeEnqueueExerciseDelete(CustomExerciseModel exercise) async {
    final id = exercise.id;
    if (id == null) {
      return;
    }
    try {
      await _syncQueue?.enqueue(
        'custom_exercise',
        id,
        'delete',
        entitySyncId: 'custom_exercise:${exercise.syncId}',
        payload: {'chineseName': exercise.chineseName},
      );
    } on Object {
      // 不让同步队列写入失败影响用户删除动作。
    }
  }
}

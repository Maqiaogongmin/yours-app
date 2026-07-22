part of 'yours_vault_service.dart';

mixin _YoursVaultExerciseImportMixin {
  CustomExerciseDatabase get _exerciseDb;
  List<String> _decodeStringList(String value);
  String _normalizeExerciseKey(String value);
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
}

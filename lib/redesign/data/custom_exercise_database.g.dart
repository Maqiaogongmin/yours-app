// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_exercise_database.dart';

// ignore_for_file: type=lint
class $CustomExercisesTable extends CustomExercises
    with TableInfo<$CustomExercisesTable, CustomExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chineseNameMeta = const VerificationMeta(
    'chineseName',
  );
  @override
  late final GeneratedColumn<String> chineseName = GeneratedColumn<String>(
    'chinese_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishNameMeta = const VerificationMeta(
    'englishName',
  );
  @override
  late final GeneratedColumn<String> englishName = GeneratedColumn<String>(
    'english_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyPartMeta = const VerificationMeta(
    'bodyPart',
  );
  @override
  late final GeneratedColumn<String> bodyPart = GeneratedColumn<String>(
    'body_part',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryMusclesMeta = const VerificationMeta(
    'primaryMuscles',
  );
  @override
  late final GeneratedColumn<String> primaryMuscles = GeneratedColumn<String>(
    'primary_muscles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathsJsonMeta = const VerificationMeta(
    'imagePathsJson',
  );
  @override
  late final GeneratedColumn<String> imagePathsJson = GeneratedColumn<String>(
    'image_paths_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    remoteId,
    chineseName,
    englishName,
    bodyPart,
    equipment,
    primaryMuscles,
    description,
    imagePathsJson,
    isCustom,
    syncStatus,
    deleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('chinese_name')) {
      context.handle(
        _chineseNameMeta,
        chineseName.isAcceptableOrUnknown(
          data['chinese_name']!,
          _chineseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chineseNameMeta);
    }
    if (data.containsKey('english_name')) {
      context.handle(
        _englishNameMeta,
        englishName.isAcceptableOrUnknown(
          data['english_name']!,
          _englishNameMeta,
        ),
      );
    }
    if (data.containsKey('body_part')) {
      context.handle(
        _bodyPartMeta,
        bodyPart.isAcceptableOrUnknown(data['body_part']!, _bodyPartMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyPartMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('primary_muscles')) {
      context.handle(
        _primaryMusclesMeta,
        primaryMuscles.isAcceptableOrUnknown(
          data['primary_muscles']!,
          _primaryMusclesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryMusclesMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('image_paths_json')) {
      context.handle(
        _imagePathsJsonMeta,
        imagePathsJson.isAcceptableOrUnknown(
          data['image_paths_json']!,
          _imagePathsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      chineseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chinese_name'],
      )!,
      englishName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_name'],
      )!,
      bodyPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_part'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      primaryMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscles'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imagePathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths_json'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomExercisesTable createAlias(String alias) {
    return $CustomExercisesTable(attachedDatabase, alias);
  }
}

class CustomExercise extends DataClass implements Insertable<CustomExercise> {
  final int id;
  final String syncId;
  final int? remoteId;
  final String chineseName;
  final String englishName;
  final String bodyPart;
  final String equipment;
  final String primaryMuscles;
  final String description;
  final String imagePathsJson;
  final bool isCustom;
  final String syncStatus;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomExercise({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.chineseName,
    required this.englishName,
    required this.bodyPart,
    required this.equipment,
    required this.primaryMuscles,
    required this.description,
    required this.imagePathsJson,
    required this.isCustom,
    required this.syncStatus,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['chinese_name'] = Variable<String>(chineseName);
    map['english_name'] = Variable<String>(englishName);
    map['body_part'] = Variable<String>(bodyPart);
    map['equipment'] = Variable<String>(equipment);
    map['primary_muscles'] = Variable<String>(primaryMuscles);
    map['description'] = Variable<String>(description);
    map['image_paths_json'] = Variable<String>(imagePathsJson);
    map['is_custom'] = Variable<bool>(isCustom);
    map['sync_status'] = Variable<String>(syncStatus);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomExercisesCompanion toCompanion(bool nullToAbsent) {
    return CustomExercisesCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      chineseName: Value(chineseName),
      englishName: Value(englishName),
      bodyPart: Value(bodyPart),
      equipment: Value(equipment),
      primaryMuscles: Value(primaryMuscles),
      description: Value(description),
      imagePathsJson: Value(imagePathsJson),
      isCustom: Value(isCustom),
      syncStatus: Value(syncStatus),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomExercise(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      chineseName: serializer.fromJson<String>(json['chineseName']),
      englishName: serializer.fromJson<String>(json['englishName']),
      bodyPart: serializer.fromJson<String>(json['bodyPart']),
      equipment: serializer.fromJson<String>(json['equipment']),
      primaryMuscles: serializer.fromJson<String>(json['primaryMuscles']),
      description: serializer.fromJson<String>(json['description']),
      imagePathsJson: serializer.fromJson<String>(json['imagePathsJson']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'chineseName': serializer.toJson<String>(chineseName),
      'englishName': serializer.toJson<String>(englishName),
      'bodyPart': serializer.toJson<String>(bodyPart),
      'equipment': serializer.toJson<String>(equipment),
      'primaryMuscles': serializer.toJson<String>(primaryMuscles),
      'description': serializer.toJson<String>(description),
      'imagePathsJson': serializer.toJson<String>(imagePathsJson),
      'isCustom': serializer.toJson<bool>(isCustom),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomExercise copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    String? chineseName,
    String? englishName,
    String? bodyPart,
    String? equipment,
    String? primaryMuscles,
    String? description,
    String? imagePathsJson,
    bool? isCustom,
    String? syncStatus,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomExercise(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    chineseName: chineseName ?? this.chineseName,
    englishName: englishName ?? this.englishName,
    bodyPart: bodyPart ?? this.bodyPart,
    equipment: equipment ?? this.equipment,
    primaryMuscles: primaryMuscles ?? this.primaryMuscles,
    description: description ?? this.description,
    imagePathsJson: imagePathsJson ?? this.imagePathsJson,
    isCustom: isCustom ?? this.isCustom,
    syncStatus: syncStatus ?? this.syncStatus,
    deleted: deleted ?? this.deleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomExercise copyWithCompanion(CustomExercisesCompanion data) {
    return CustomExercise(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      chineseName: data.chineseName.present ? data.chineseName.value : this.chineseName,
      englishName: data.englishName.present ? data.englishName.value : this.englishName,
      bodyPart: data.bodyPart.present ? data.bodyPart.value : this.bodyPart,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      primaryMuscles: data.primaryMuscles.present ? data.primaryMuscles.value : this.primaryMuscles,
      description: data.description.present ? data.description.value : this.description,
      imagePathsJson: data.imagePathsJson.present ? data.imagePathsJson.value : this.imagePathsJson,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomExercise(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('chineseName: $chineseName, ')
          ..write('englishName: $englishName, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('primaryMuscles: $primaryMuscles, ')
          ..write('description: $description, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('isCustom: $isCustom, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    remoteId,
    chineseName,
    englishName,
    bodyPart,
    equipment,
    primaryMuscles,
    description,
    imagePathsJson,
    isCustom,
    syncStatus,
    deleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomExercise &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.chineseName == this.chineseName &&
          other.englishName == this.englishName &&
          other.bodyPart == this.bodyPart &&
          other.equipment == this.equipment &&
          other.primaryMuscles == this.primaryMuscles &&
          other.description == this.description &&
          other.imagePathsJson == this.imagePathsJson &&
          other.isCustom == this.isCustom &&
          other.syncStatus == this.syncStatus &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomExercisesCompanion extends UpdateCompanion<CustomExercise> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<String> chineseName;
  final Value<String> englishName;
  final Value<String> bodyPart;
  final Value<String> equipment;
  final Value<String> primaryMuscles;
  final Value<String> description;
  final Value<String> imagePathsJson;
  final Value<bool> isCustom;
  final Value<String> syncStatus;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomExercisesCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.chineseName = const Value.absent(),
    this.englishName = const Value.absent(),
    this.bodyPart = const Value.absent(),
    this.equipment = const Value.absent(),
    this.primaryMuscles = const Value.absent(),
    this.description = const Value.absent(),
    this.imagePathsJson = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String chineseName,
    this.englishName = const Value.absent(),
    required String bodyPart,
    required String equipment,
    required String primaryMuscles,
    required String description,
    this.imagePathsJson = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : chineseName = Value(chineseName),
       bodyPart = Value(bodyPart),
       equipment = Value(equipment),
       primaryMuscles = Value(primaryMuscles),
       description = Value(description),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomExercise> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<String>? chineseName,
    Expression<String>? englishName,
    Expression<String>? bodyPart,
    Expression<String>? equipment,
    Expression<String>? primaryMuscles,
    Expression<String>? description,
    Expression<String>? imagePathsJson,
    Expression<bool>? isCustom,
    Expression<String>? syncStatus,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (chineseName != null) 'chinese_name': chineseName,
      if (englishName != null) 'english_name': englishName,
      if (bodyPart != null) 'body_part': bodyPart,
      if (equipment != null) 'equipment': equipment,
      if (primaryMuscles != null) 'primary_muscles': primaryMuscles,
      if (description != null) 'description': description,
      if (imagePathsJson != null) 'image_paths_json': imagePathsJson,
      if (isCustom != null) 'is_custom': isCustom,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<String>? chineseName,
    Value<String>? englishName,
    Value<String>? bodyPart,
    Value<String>? equipment,
    Value<String>? primaryMuscles,
    Value<String>? description,
    Value<String>? imagePathsJson,
    Value<bool>? isCustom,
    Value<String>? syncStatus,
    Value<bool>? deleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CustomExercisesCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      chineseName: chineseName ?? this.chineseName,
      englishName: englishName ?? this.englishName,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      description: description ?? this.description,
      imagePathsJson: imagePathsJson ?? this.imagePathsJson,
      isCustom: isCustom ?? this.isCustom,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (chineseName.present) {
      map['chinese_name'] = Variable<String>(chineseName.value);
    }
    if (englishName.present) {
      map['english_name'] = Variable<String>(englishName.value);
    }
    if (bodyPart.present) {
      map['body_part'] = Variable<String>(bodyPart.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (primaryMuscles.present) {
      map['primary_muscles'] = Variable<String>(primaryMuscles.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imagePathsJson.present) {
      map['image_paths_json'] = Variable<String>(imagePathsJson.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomExercisesCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('chineseName: $chineseName, ')
          ..write('englishName: $englishName, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('equipment: $equipment, ')
          ..write('primaryMuscles: $primaryMuscles, ')
          ..write('description: $description, ')
          ..write('imagePathsJson: $imagePathsJson, ')
          ..write('isCustom: $isCustom, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomExerciseImagesTable extends CustomExerciseImages
    with TableInfo<$CustomExerciseImagesTable, CustomExerciseImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomExerciseImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_exercises (id)',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    path,
    sortOrder,
    caption,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_exercise_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomExerciseImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomExerciseImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomExerciseImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomExerciseImagesTable createAlias(String alias) {
    return $CustomExerciseImagesTable(attachedDatabase, alias);
  }
}

class CustomExerciseImage extends DataClass implements Insertable<CustomExerciseImage> {
  final int id;
  final int exerciseId;
  final String path;
  final int sortOrder;
  final String? caption;
  final DateTime createdAt;
  const CustomExerciseImage({
    required this.id,
    required this.exerciseId,
    required this.path,
    required this.sortOrder,
    this.caption,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['path'] = Variable<String>(path);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomExerciseImagesCompanion toCompanion(bool nullToAbsent) {
    return CustomExerciseImagesCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      path: Value(path),
      sortOrder: Value(sortOrder),
      caption: caption == null && nullToAbsent ? const Value.absent() : Value(caption),
      createdAt: Value(createdAt),
    );
  }

  factory CustomExerciseImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomExerciseImage(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      path: serializer.fromJson<String>(json['path']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'path': serializer.toJson<String>(path),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'caption': serializer.toJson<String?>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomExerciseImage copyWith({
    int? id,
    int? exerciseId,
    String? path,
    int? sortOrder,
    Value<String?> caption = const Value.absent(),
    DateTime? createdAt,
  }) => CustomExerciseImage(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    path: path ?? this.path,
    sortOrder: sortOrder ?? this.sortOrder,
    caption: caption.present ? caption.value : this.caption,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomExerciseImage copyWithCompanion(CustomExerciseImagesCompanion data) {
    return CustomExerciseImage(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      path: data.path.present ? data.path.value : this.path,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomExerciseImage(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('path: $path, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, path, sortOrder, caption, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomExerciseImage &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.path == this.path &&
          other.sortOrder == this.sortOrder &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt);
}

class CustomExerciseImagesCompanion extends UpdateCompanion<CustomExerciseImage> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<String> path;
  final Value<int> sortOrder;
  final Value<String?> caption;
  final Value<DateTime> createdAt;
  const CustomExerciseImagesCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.path = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomExerciseImagesCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required String path,
    this.sortOrder = const Value.absent(),
    this.caption = const Value.absent(),
    required DateTime createdAt,
  }) : exerciseId = Value(exerciseId),
       path = Value(path),
       createdAt = Value(createdAt);
  static Insertable<CustomExerciseImage> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? path,
    Expression<int>? sortOrder,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (path != null) 'path': path,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomExerciseImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<String>? path,
    Value<int>? sortOrder,
    Value<String?>? caption,
    Value<DateTime>? createdAt,
  }) {
    return CustomExerciseImagesCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      path: path ?? this.path,
      sortOrder: sortOrder ?? this.sortOrder,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomExerciseImagesCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('path: $path, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$CustomExerciseDatabase extends GeneratedDatabase {
  _$CustomExerciseDatabase(QueryExecutor e) : super(e);
  $CustomExerciseDatabaseManager get managers => $CustomExerciseDatabaseManager(this);
  late final $CustomExercisesTable customExercises = $CustomExercisesTable(
    this,
  );
  late final $CustomExerciseImagesTable customExerciseImages = $CustomExerciseImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customExercises,
    customExerciseImages,
  ];
}

typedef $$CustomExercisesTableCreateCompanionBuilder =
    CustomExercisesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required String chineseName,
      Value<String> englishName,
      required String bodyPart,
      required String equipment,
      required String primaryMuscles,
      required String description,
      Value<String> imagePathsJson,
      Value<bool> isCustom,
      Value<String> syncStatus,
      Value<bool> deleted,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$CustomExercisesTableUpdateCompanionBuilder =
    CustomExercisesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<String> chineseName,
      Value<String> englishName,
      Value<String> bodyPart,
      Value<String> equipment,
      Value<String> primaryMuscles,
      Value<String> description,
      Value<String> imagePathsJson,
      Value<bool> isCustom,
      Value<String> syncStatus,
      Value<bool> deleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CustomExercisesTableReferences
    extends BaseReferences<_$CustomExerciseDatabase, $CustomExercisesTable, CustomExercise> {
  $$CustomExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CustomExerciseImagesTable, List<CustomExerciseImage>>
  _customExerciseImagesRefsTable(_$CustomExerciseDatabase db) => MultiTypedResultKey.fromTable(
    db.customExerciseImages,
    aliasName: $_aliasNameGenerator(
      db.customExercises.id,
      db.customExerciseImages.exerciseId,
    ),
  );

  $$CustomExerciseImagesTableProcessedTableManager get customExerciseImagesRefs {
    final manager = $$CustomExerciseImagesTableTableManager(
      $_db,
      $_db.customExerciseImages,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customExerciseImagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomExercisesTableFilterComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExercisesTable> {
  $$CustomExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chineseName => $composableBuilder(
    column: $table.chineseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMuscles => $composableBuilder(
    column: $table.primaryMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePathsJson => $composableBuilder(
    column: $table.imagePathsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customExerciseImagesRefs(
    Expression<bool> Function($$CustomExerciseImagesTableFilterComposer f) f,
  ) {
    final $$CustomExerciseImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customExerciseImages,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomExerciseImagesTableFilterComposer(
            $db: $db,
            $table: $db.customExerciseImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomExercisesTableOrderingComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExercisesTable> {
  $$CustomExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chineseName => $composableBuilder(
    column: $table.chineseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMuscles => $composableBuilder(
    column: $table.primaryMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePathsJson => $composableBuilder(
    column: $table.imagePathsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomExercisesTableAnnotationComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExercisesTable> {
  $$CustomExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get chineseName => $composableBuilder(
    column: $table.chineseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishName => $composableBuilder(
    column: $table.englishName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bodyPart =>
      $composableBuilder(column: $table.bodyPart, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get primaryMuscles => $composableBuilder(
    column: $table.primaryMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePathsJson => $composableBuilder(
    column: $table.imagePathsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> customExerciseImagesRefs<T extends Object>(
    Expression<T> Function($$CustomExerciseImagesTableAnnotationComposer a) f,
  ) {
    final $$CustomExerciseImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customExerciseImages,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomExerciseImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.customExerciseImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomExercisesTableTableManager
    extends
        RootTableManager<
          _$CustomExerciseDatabase,
          $CustomExercisesTable,
          CustomExercise,
          $$CustomExercisesTableFilterComposer,
          $$CustomExercisesTableOrderingComposer,
          $$CustomExercisesTableAnnotationComposer,
          $$CustomExercisesTableCreateCompanionBuilder,
          $$CustomExercisesTableUpdateCompanionBuilder,
          (CustomExercise, $$CustomExercisesTableReferences),
          CustomExercise,
          PrefetchHooks Function({bool customExerciseImagesRefs})
        > {
  $$CustomExercisesTableTableManager(
    _$CustomExerciseDatabase db,
    $CustomExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> chineseName = const Value.absent(),
                Value<String> englishName = const Value.absent(),
                Value<String> bodyPart = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> primaryMuscles = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imagePathsJson = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CustomExercisesCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                chineseName: chineseName,
                englishName: englishName,
                bodyPart: bodyPart,
                equipment: equipment,
                primaryMuscles: primaryMuscles,
                description: description,
                imagePathsJson: imagePathsJson,
                isCustom: isCustom,
                syncStatus: syncStatus,
                deleted: deleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required String chineseName,
                Value<String> englishName = const Value.absent(),
                required String bodyPart,
                required String equipment,
                required String primaryMuscles,
                required String description,
                Value<String> imagePathsJson = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CustomExercisesCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                chineseName: chineseName,
                englishName: englishName,
                bodyPart: bodyPart,
                equipment: equipment,
                primaryMuscles: primaryMuscles,
                description: description,
                imagePathsJson: imagePathsJson,
                isCustom: isCustom,
                syncStatus: syncStatus,
                deleted: deleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customExerciseImagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (customExerciseImagesRefs) db.customExerciseImages,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (customExerciseImagesRefs)
                    await $_getPrefetchedData<
                      CustomExercise,
                      $CustomExercisesTable,
                      CustomExerciseImage
                    >(
                      currentTable: table,
                      referencedTable: $$CustomExercisesTableReferences
                          ._customExerciseImagesRefsTable(db),
                      managerFromTypedResult: (p0) => $$CustomExercisesTableReferences(
                        db,
                        table,
                        p0,
                      ).customExerciseImagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.exerciseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$CustomExerciseDatabase,
      $CustomExercisesTable,
      CustomExercise,
      $$CustomExercisesTableFilterComposer,
      $$CustomExercisesTableOrderingComposer,
      $$CustomExercisesTableAnnotationComposer,
      $$CustomExercisesTableCreateCompanionBuilder,
      $$CustomExercisesTableUpdateCompanionBuilder,
      (CustomExercise, $$CustomExercisesTableReferences),
      CustomExercise,
      PrefetchHooks Function({bool customExerciseImagesRefs})
    >;
typedef $$CustomExerciseImagesTableCreateCompanionBuilder =
    CustomExerciseImagesCompanion Function({
      Value<int> id,
      required int exerciseId,
      required String path,
      Value<int> sortOrder,
      Value<String?> caption,
      required DateTime createdAt,
    });
typedef $$CustomExerciseImagesTableUpdateCompanionBuilder =
    CustomExerciseImagesCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<String> path,
      Value<int> sortOrder,
      Value<String?> caption,
      Value<DateTime> createdAt,
    });

final class $$CustomExerciseImagesTableReferences
    extends
        BaseReferences<_$CustomExerciseDatabase, $CustomExerciseImagesTable, CustomExerciseImage> {
  $$CustomExerciseImagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomExercisesTable _exerciseIdTable(_$CustomExerciseDatabase db) =>
      db.customExercises.createAlias(
        $_aliasNameGenerator(
          db.customExerciseImages.exerciseId,
          db.customExercises.id,
        ),
      );

  $$CustomExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$CustomExercisesTableTableManager(
      $_db,
      $_db.customExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomExerciseImagesTableFilterComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExerciseImagesTable> {
  $$CustomExerciseImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomExercisesTableFilterComposer get exerciseId {
    final $$CustomExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.customExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomExercisesTableFilterComposer(
            $db: $db,
            $table: $db.customExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomExerciseImagesTableOrderingComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExerciseImagesTable> {
  $$CustomExerciseImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomExercisesTableOrderingComposer get exerciseId {
    final $$CustomExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.customExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.customExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomExerciseImagesTableAnnotationComposer
    extends Composer<_$CustomExerciseDatabase, $CustomExerciseImagesTable> {
  $$CustomExerciseImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CustomExercisesTableAnnotationComposer get exerciseId {
    final $$CustomExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.customExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.customExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomExerciseImagesTableTableManager
    extends
        RootTableManager<
          _$CustomExerciseDatabase,
          $CustomExerciseImagesTable,
          CustomExerciseImage,
          $$CustomExerciseImagesTableFilterComposer,
          $$CustomExerciseImagesTableOrderingComposer,
          $$CustomExerciseImagesTableAnnotationComposer,
          $$CustomExerciseImagesTableCreateCompanionBuilder,
          $$CustomExerciseImagesTableUpdateCompanionBuilder,
          (CustomExerciseImage, $$CustomExerciseImagesTableReferences),
          CustomExerciseImage,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$CustomExerciseImagesTableTableManager(
    _$CustomExerciseDatabase db,
    $CustomExerciseImagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomExerciseImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CustomExerciseImagesTableOrderingComposer(
            $db: db,
            $table: table,
          ),
          createComputedFieldComposer: () => $$CustomExerciseImagesTableAnnotationComposer(
            $db: db,
            $table: table,
          ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomExerciseImagesCompanion(
                id: id,
                exerciseId: exerciseId,
                path: path,
                sortOrder: sortOrder,
                caption: caption,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required String path,
                Value<int> sortOrder = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                required DateTime createdAt,
              }) => CustomExerciseImagesCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                path: path,
                sortOrder: sortOrder,
                caption: caption,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomExerciseImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$CustomExerciseImagesTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$CustomExerciseImagesTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomExerciseImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$CustomExerciseDatabase,
      $CustomExerciseImagesTable,
      CustomExerciseImage,
      $$CustomExerciseImagesTableFilterComposer,
      $$CustomExerciseImagesTableOrderingComposer,
      $$CustomExerciseImagesTableAnnotationComposer,
      $$CustomExerciseImagesTableCreateCompanionBuilder,
      $$CustomExerciseImagesTableUpdateCompanionBuilder,
      (CustomExerciseImage, $$CustomExerciseImagesTableReferences),
      CustomExerciseImage,
      PrefetchHooks Function({bool exerciseId})
    >;

class $CustomExerciseDatabaseManager {
  final _$CustomExerciseDatabase _db;
  $CustomExerciseDatabaseManager(this._db);
  $$CustomExercisesTableTableManager get customExercises =>
      $$CustomExercisesTableTableManager(_db, _db.customExercises);
  $$CustomExerciseImagesTableTableManager get customExerciseImages =>
      $$CustomExerciseImagesTableTableManager(_db, _db.customExerciseImages);
}

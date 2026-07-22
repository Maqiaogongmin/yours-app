// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_training_database.dart';

// ignore_for_file: type=lint
class $LocalRoutinesTable extends LocalRoutines
    with TableInfo<$LocalRoutinesTable, LocalRoutine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRoutinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _daysPerWeekMeta = const VerificationMeta(
    'daysPerWeek',
  );
  @override
  late final GeneratedColumn<int> daysPerWeek = GeneratedColumn<int>(
    'days_per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedWeeksJsonMeta =
      const VerificationMeta('completedWeeksJson');
  @override
  late final GeneratedColumn<String> completedWeeksJson =
      GeneratedColumn<String>(
        'completed_weeks_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
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
    name,
    totalWeeks,
    daysPerWeek,
    archived,
    completedWeeksJson,
    syncStatus,
    deleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRoutine> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    }
    if (data.containsKey('days_per_week')) {
      context.handle(
        _daysPerWeekMeta,
        daysPerWeek.isAcceptableOrUnknown(
          data['days_per_week']!,
          _daysPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('completed_weeks_json')) {
      context.handle(
        _completedWeeksJsonMeta,
        completedWeeksJson.isAcceptableOrUnknown(
          data['completed_weeks_json']!,
          _completedWeeksJsonMeta,
        ),
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
  LocalRoutine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRoutine(
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      )!,
      daysPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_per_week'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      completedWeeksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_weeks_json'],
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
  $LocalRoutinesTable createAlias(String alias) {
    return $LocalRoutinesTable(attachedDatabase, alias);
  }
}

class LocalRoutine extends DataClass implements Insertable<LocalRoutine> {
  final int id;
  final String syncId;
  final int? remoteId;
  final String name;
  final int totalWeeks;
  final int daysPerWeek;
  final bool archived;
  final String completedWeeksJson;
  final String syncStatus;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalRoutine({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.name,
    required this.totalWeeks,
    required this.daysPerWeek,
    required this.archived,
    required this.completedWeeksJson,
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
    map['name'] = Variable<String>(name);
    map['total_weeks'] = Variable<int>(totalWeeks);
    map['days_per_week'] = Variable<int>(daysPerWeek);
    map['archived'] = Variable<bool>(archived);
    map['completed_weeks_json'] = Variable<String>(completedWeeksJson);
    map['sync_status'] = Variable<String>(syncStatus);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalRoutinesCompanion toCompanion(bool nullToAbsent) {
    return LocalRoutinesCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      totalWeeks: Value(totalWeeks),
      daysPerWeek: Value(daysPerWeek),
      archived: Value(archived),
      completedWeeksJson: Value(completedWeeksJson),
      syncStatus: Value(syncStatus),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalRoutine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRoutine(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      totalWeeks: serializer.fromJson<int>(json['totalWeeks']),
      daysPerWeek: serializer.fromJson<int>(json['daysPerWeek']),
      archived: serializer.fromJson<bool>(json['archived']),
      completedWeeksJson: serializer.fromJson<String>(
        json['completedWeeksJson'],
      ),
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
      'name': serializer.toJson<String>(name),
      'totalWeeks': serializer.toJson<int>(totalWeeks),
      'daysPerWeek': serializer.toJson<int>(daysPerWeek),
      'archived': serializer.toJson<bool>(archived),
      'completedWeeksJson': serializer.toJson<String>(completedWeeksJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalRoutine copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    String? name,
    int? totalWeeks,
    int? daysPerWeek,
    bool? archived,
    String? completedWeeksJson,
    String? syncStatus,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalRoutine(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    totalWeeks: totalWeeks ?? this.totalWeeks,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    archived: archived ?? this.archived,
    completedWeeksJson: completedWeeksJson ?? this.completedWeeksJson,
    syncStatus: syncStatus ?? this.syncStatus,
    deleted: deleted ?? this.deleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalRoutine copyWithCompanion(LocalRoutinesCompanion data) {
    return LocalRoutine(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
      daysPerWeek: data.daysPerWeek.present
          ? data.daysPerWeek.value
          : this.daysPerWeek,
      archived: data.archived.present ? data.archived.value : this.archived,
      completedWeeksJson: data.completedWeeksJson.present
          ? data.completedWeeksJson.value
          : this.completedWeeksJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRoutine(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('archived: $archived, ')
          ..write('completedWeeksJson: $completedWeeksJson, ')
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
    name,
    totalWeeks,
    daysPerWeek,
    archived,
    completedWeeksJson,
    syncStatus,
    deleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRoutine &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.totalWeeks == this.totalWeeks &&
          other.daysPerWeek == this.daysPerWeek &&
          other.archived == this.archived &&
          other.completedWeeksJson == this.completedWeeksJson &&
          other.syncStatus == this.syncStatus &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalRoutinesCompanion extends UpdateCompanion<LocalRoutine> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<String> name;
  final Value<int> totalWeeks;
  final Value<int> daysPerWeek;
  final Value<bool> archived;
  final Value<String> completedWeeksJson;
  final Value<String> syncStatus;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LocalRoutinesCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.archived = const Value.absent(),
    this.completedWeeksJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalRoutinesCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    this.totalWeeks = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.archived = const Value.absent(),
    this.completedWeeksJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalRoutine> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<String>? name,
    Expression<int>? totalWeeks,
    Expression<int>? daysPerWeek,
    Expression<bool>? archived,
    Expression<String>? completedWeeksJson,
    Expression<String>? syncStatus,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (daysPerWeek != null) 'days_per_week': daysPerWeek,
      if (archived != null) 'archived': archived,
      if (completedWeeksJson != null)
        'completed_weeks_json': completedWeeksJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalRoutinesCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<String>? name,
    Value<int>? totalWeeks,
    Value<int>? daysPerWeek,
    Value<bool>? archived,
    Value<String>? completedWeeksJson,
    Value<String>? syncStatus,
    Value<bool>? deleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LocalRoutinesCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      archived: archived ?? this.archived,
      completedWeeksJson: completedWeeksJson ?? this.completedWeeksJson,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (daysPerWeek.present) {
      map['days_per_week'] = Variable<int>(daysPerWeek.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (completedWeeksJson.present) {
      map['completed_weeks_json'] = Variable<String>(completedWeeksJson.value);
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
    return (StringBuffer('LocalRoutinesCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('archived: $archived, ')
          ..write('completedWeeksJson: $completedWeeksJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalTrainingDaysTable extends LocalTrainingDays
    with TableInfo<$LocalTrainingDaysTable, LocalTrainingDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTrainingDaysTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_routines (id)',
    ),
  );
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionsJsonMeta = const VerificationMeta(
    'actionsJson',
  );
  @override
  late final GeneratedColumn<String> actionsJson = GeneratedColumn<String>(
    'actions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
    routineId,
    week,
    day,
    name,
    actionsJson,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_training_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrainingDay> instance, {
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
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('actions_json')) {
      context.handle(
        _actionsJsonMeta,
        actionsJson.isAcceptableOrUnknown(
          data['actions_json']!,
          _actionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
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
  LocalTrainingDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrainingDay(
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
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      actionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actions_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalTrainingDaysTable createAlias(String alias) {
    return $LocalTrainingDaysTable(attachedDatabase, alias);
  }
}

class LocalTrainingDay extends DataClass
    implements Insertable<LocalTrainingDay> {
  final int id;
  final String syncId;
  final int? remoteId;
  final int routineId;
  final int week;
  final int day;
  final String name;
  final String actionsJson;
  final String syncStatus;
  final DateTime updatedAt;
  const LocalTrainingDay({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.routineId,
    required this.week,
    required this.day,
    required this.name,
    required this.actionsJson,
    required this.syncStatus,
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
    map['routine_id'] = Variable<int>(routineId);
    map['week'] = Variable<int>(week);
    map['day'] = Variable<int>(day);
    map['name'] = Variable<String>(name);
    map['actions_json'] = Variable<String>(actionsJson);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalTrainingDaysCompanion toCompanion(bool nullToAbsent) {
    return LocalTrainingDaysCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      routineId: Value(routineId),
      week: Value(week),
      day: Value(day),
      name: Value(name),
      actionsJson: Value(actionsJson),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalTrainingDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrainingDay(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      routineId: serializer.fromJson<int>(json['routineId']),
      week: serializer.fromJson<int>(json['week']),
      day: serializer.fromJson<int>(json['day']),
      name: serializer.fromJson<String>(json['name']),
      actionsJson: serializer.fromJson<String>(json['actionsJson']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
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
      'routineId': serializer.toJson<int>(routineId),
      'week': serializer.toJson<int>(week),
      'day': serializer.toJson<int>(day),
      'name': serializer.toJson<String>(name),
      'actionsJson': serializer.toJson<String>(actionsJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalTrainingDay copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    int? routineId,
    int? week,
    int? day,
    String? name,
    String? actionsJson,
    String? syncStatus,
    DateTime? updatedAt,
  }) => LocalTrainingDay(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    routineId: routineId ?? this.routineId,
    week: week ?? this.week,
    day: day ?? this.day,
    name: name ?? this.name,
    actionsJson: actionsJson ?? this.actionsJson,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalTrainingDay copyWithCompanion(LocalTrainingDaysCompanion data) {
    return LocalTrainingDay(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      week: data.week.present ? data.week.value : this.week,
      day: data.day.present ? data.day.value : this.day,
      name: data.name.present ? data.name.value : this.name,
      actionsJson: data.actionsJson.present
          ? data.actionsJson.value
          : this.actionsJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrainingDay(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('routineId: $routineId, ')
          ..write('week: $week, ')
          ..write('day: $day, ')
          ..write('name: $name, ')
          ..write('actionsJson: $actionsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    remoteId,
    routineId,
    week,
    day,
    name,
    actionsJson,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrainingDay &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.routineId == this.routineId &&
          other.week == this.week &&
          other.day == this.day &&
          other.name == this.name &&
          other.actionsJson == this.actionsJson &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class LocalTrainingDaysCompanion extends UpdateCompanion<LocalTrainingDay> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<int> routineId;
  final Value<int> week;
  final Value<int> day;
  final Value<String> name;
  final Value<String> actionsJson;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  const LocalTrainingDaysCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.week = const Value.absent(),
    this.day = const Value.absent(),
    this.name = const Value.absent(),
    this.actionsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalTrainingDaysCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int routineId,
    required int week,
    required int day,
    required String name,
    this.actionsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime updatedAt,
  }) : routineId = Value(routineId),
       week = Value(week),
       day = Value(day),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalTrainingDay> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<int>? routineId,
    Expression<int>? week,
    Expression<int>? day,
    Expression<String>? name,
    Expression<String>? actionsJson,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (routineId != null) 'routine_id': routineId,
      if (week != null) 'week': week,
      if (day != null) 'day': day,
      if (name != null) 'name': name,
      if (actionsJson != null) 'actions_json': actionsJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalTrainingDaysCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<int>? routineId,
    Value<int>? week,
    Value<int>? day,
    Value<String>? name,
    Value<String>? actionsJson,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
  }) {
    return LocalTrainingDaysCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      routineId: routineId ?? this.routineId,
      week: week ?? this.week,
      day: day ?? this.day,
      name: name ?? this.name,
      actionsJson: actionsJson ?? this.actionsJson,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (actionsJson.present) {
      map['actions_json'] = Variable<String>(actionsJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrainingDaysCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('routineId: $routineId, ')
          ..write('week: $week, ')
          ..write('day: $day, ')
          ..write('name: $name, ')
          ..write('actionsJson: $actionsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSlotsTable extends LocalSlots
    with TableInfo<$LocalSlotsTable, LocalSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSlotsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_training_days (id)',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    remoteId,
    dayId,
    order,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSlot> instance, {
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
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSlot(
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
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalSlotsTable createAlias(String alias) {
    return $LocalSlotsTable(attachedDatabase, alias);
  }
}

class LocalSlot extends DataClass implements Insertable<LocalSlot> {
  final int id;
  final String syncId;
  final int? remoteId;
  final int dayId;
  final int order;
  final String syncStatus;
  const LocalSlot({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.dayId,
    required this.order,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['day_id'] = Variable<int>(dayId);
    map['order'] = Variable<int>(order);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalSlotsCompanion toCompanion(bool nullToAbsent) {
    return LocalSlotsCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      dayId: Value(dayId),
      order: Value(order),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSlot(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      dayId: serializer.fromJson<int>(json['dayId']),
      order: serializer.fromJson<int>(json['order']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'dayId': serializer.toJson<int>(dayId),
      'order': serializer.toJson<int>(order),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalSlot copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    int? dayId,
    int? order,
    String? syncStatus,
  }) => LocalSlot(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    dayId: dayId ?? this.dayId,
    order: order ?? this.order,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalSlot copyWithCompanion(LocalSlotsCompanion data) {
    return LocalSlot(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      order: data.order.present ? data.order.value : this.order,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSlot(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('dayId: $dayId, ')
          ..write('order: $order, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, syncId, remoteId, dayId, order, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSlot &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.dayId == this.dayId &&
          other.order == this.order &&
          other.syncStatus == this.syncStatus);
}

class LocalSlotsCompanion extends UpdateCompanion<LocalSlot> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<int> dayId;
  final Value<int> order;
  final Value<String> syncStatus;
  const LocalSlotsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.dayId = const Value.absent(),
    this.order = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  LocalSlotsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int dayId,
    required int order,
    this.syncStatus = const Value.absent(),
  }) : dayId = Value(dayId),
       order = Value(order);
  static Insertable<LocalSlot> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<int>? dayId,
    Expression<int>? order,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (dayId != null) 'day_id': dayId,
      if (order != null) 'order': order,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  LocalSlotsCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<int>? dayId,
    Value<int>? order,
    Value<String>? syncStatus,
  }) {
    return LocalSlotsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      dayId: dayId ?? this.dayId,
      order: order ?? this.order,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSlotsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('dayId: $dayId, ')
          ..write('order: $order, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $LocalSlotEntriesTable extends LocalSlotEntries
    with TableInfo<$LocalSlotEntriesTable, LocalSlotEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSlotEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<int> slotId = GeneratedColumn<int>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_slots (id)',
    ),
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightMeta = const VerificationMeta(
    'targetWeight',
  );
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
    'target_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordModeMeta = const VerificationMeta(
    'recordMode',
  );
  @override
  late final GeneratedColumn<String> recordMode = GeneratedColumn<String>(
    'record_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncId,
    remoteId,
    slotId,
    exerciseName,
    exerciseId,
    targetSets,
    targetReps,
    targetWeight,
    recordMode,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_slot_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSlotEntry> instance, {
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
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    if (data.containsKey('target_weight')) {
      context.handle(
        _targetWeightMeta,
        targetWeight.isAcceptableOrUnknown(
          data['target_weight']!,
          _targetWeightMeta,
        ),
      );
    }
    if (data.containsKey('record_mode')) {
      context.handle(
        _recordModeMeta,
        recordMode.isAcceptableOrUnknown(data['record_mode']!, _recordModeMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSlotEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSlotEntry(
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
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot_id'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      ),
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      ),
      targetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight'],
      ),
      recordMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_mode'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $LocalSlotEntriesTable createAlias(String alias) {
    return $LocalSlotEntriesTable(attachedDatabase, alias);
  }
}

class LocalSlotEntry extends DataClass implements Insertable<LocalSlotEntry> {
  final int id;
  final String syncId;
  final int? remoteId;
  final int slotId;
  final String exerciseName;
  final int? exerciseId;
  final int targetSets;
  final int? targetReps;
  final double? targetWeight;
  final String recordMode;
  final String syncStatus;
  const LocalSlotEntry({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.slotId,
    required this.exerciseName,
    this.exerciseId,
    required this.targetSets,
    this.targetReps,
    this.targetWeight,
    required this.recordMode,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['slot_id'] = Variable<int>(slotId);
    map['exercise_name'] = Variable<String>(exerciseName);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<int>(exerciseId);
    }
    map['target_sets'] = Variable<int>(targetSets);
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<int>(targetReps);
    }
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<double>(targetWeight);
    }
    map['record_mode'] = Variable<String>(recordMode);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalSlotEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalSlotEntriesCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      slotId: Value(slotId),
      exerciseName: Value(exerciseName),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      targetSets: Value(targetSets),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      recordMode: Value(recordMode),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalSlotEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSlotEntry(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      slotId: serializer.fromJson<int>(json['slotId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      exerciseId: serializer.fromJson<int?>(json['exerciseId']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int?>(json['targetReps']),
      targetWeight: serializer.fromJson<double?>(json['targetWeight']),
      recordMode: serializer.fromJson<String>(json['recordMode']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'slotId': serializer.toJson<int>(slotId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'exerciseId': serializer.toJson<int?>(exerciseId),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int?>(targetReps),
      'targetWeight': serializer.toJson<double?>(targetWeight),
      'recordMode': serializer.toJson<String>(recordMode),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalSlotEntry copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    int? slotId,
    String? exerciseName,
    Value<int?> exerciseId = const Value.absent(),
    int? targetSets,
    Value<int?> targetReps = const Value.absent(),
    Value<double?> targetWeight = const Value.absent(),
    String? recordMode,
    String? syncStatus,
  }) => LocalSlotEntry(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    slotId: slotId ?? this.slotId,
    exerciseName: exerciseName ?? this.exerciseName,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps.present ? targetReps.value : this.targetReps,
    targetWeight: targetWeight.present ? targetWeight.value : this.targetWeight,
    recordMode: recordMode ?? this.recordMode,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  LocalSlotEntry copyWithCompanion(LocalSlotEntriesCompanion data) {
    return LocalSlotEntry(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      recordMode: data.recordMode.present
          ? data.recordMode.value
          : this.recordMode,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSlotEntry(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('slotId: $slotId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('recordMode: $recordMode, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    remoteId,
    slotId,
    exerciseName,
    exerciseId,
    targetSets,
    targetReps,
    targetWeight,
    recordMode,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSlotEntry &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.slotId == this.slotId &&
          other.exerciseName == this.exerciseName &&
          other.exerciseId == this.exerciseId &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.targetWeight == this.targetWeight &&
          other.recordMode == this.recordMode &&
          other.syncStatus == this.syncStatus);
}

class LocalSlotEntriesCompanion extends UpdateCompanion<LocalSlotEntry> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<int> slotId;
  final Value<String> exerciseName;
  final Value<int?> exerciseId;
  final Value<int> targetSets;
  final Value<int?> targetReps;
  final Value<double?> targetWeight;
  final Value<String> recordMode;
  final Value<String> syncStatus;
  const LocalSlotEntriesCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.slotId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.recordMode = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  LocalSlotEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int slotId,
    required String exerciseName,
    this.exerciseId = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.recordMode = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : slotId = Value(slotId),
       exerciseName = Value(exerciseName);
  static Insertable<LocalSlotEntry> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<int>? slotId,
    Expression<String>? exerciseName,
    Expression<int>? exerciseId,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<double>? targetWeight,
    Expression<String>? recordMode,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (slotId != null) 'slot_id': slotId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (recordMode != null) 'record_mode': recordMode,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  LocalSlotEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<int>? slotId,
    Value<String>? exerciseName,
    Value<int?>? exerciseId,
    Value<int>? targetSets,
    Value<int?>? targetReps,
    Value<double?>? targetWeight,
    Value<String>? recordMode,
    Value<String>? syncStatus,
  }) {
    return LocalSlotEntriesCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      slotId: slotId ?? this.slotId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseId: exerciseId ?? this.exerciseId,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      recordMode: recordMode ?? this.recordMode,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (slotId.present) {
      map['slot_id'] = Variable<int>(slotId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (recordMode.present) {
      map['record_mode'] = Variable<String>(recordMode.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSlotEntriesCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('slotId: $slotId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('recordMode: $recordMode, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutSessionsTable extends LocalWorkoutSessions
    with TableInfo<$LocalWorkoutSessionsTable, LocalWorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_routines (id)',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_training_days (id)',
    ),
  );
  static const VerificationMeta _routineNameSnapshotMeta =
      const VerificationMeta('routineNameSnapshot');
  @override
  late final GeneratedColumn<String> routineNameSnapshot =
      GeneratedColumn<String>(
        'routine_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _routineSyncIdSnapshotMeta =
      const VerificationMeta('routineSyncIdSnapshot');
  @override
  late final GeneratedColumn<String> routineSyncIdSnapshot =
      GeneratedColumn<String>(
        'routine_sync_id_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _dayNameSnapshotMeta = const VerificationMeta(
    'dayNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> dayNameSnapshot = GeneratedColumn<String>(
    'day_name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dayWeekSnapshotMeta = const VerificationMeta(
    'dayWeekSnapshot',
  );
  @override
  late final GeneratedColumn<int> dayWeekSnapshot = GeneratedColumn<int>(
    'day_week_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayIndexSnapshotMeta = const VerificationMeta(
    'dayIndexSnapshot',
  );
  @override
  late final GeneratedColumn<int> dayIndexSnapshot = GeneratedColumn<int>(
    'day_index_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _daySyncIdSnapshotMeta = const VerificationMeta(
    'daySyncIdSnapshot',
  );
  @override
  late final GeneratedColumn<String> daySyncIdSnapshot =
      GeneratedColumn<String>(
        'day_sync_id_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    routineId,
    dayId,
    routineNameSnapshot,
    routineSyncIdSnapshot,
    dayNameSnapshot,
    dayWeekSnapshot,
    dayIndexSnapshot,
    daySyncIdSnapshot,
    startedAt,
    endedAt,
    note,
    syncStatus,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutSession> instance, {
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
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    }
    if (data.containsKey('routine_name_snapshot')) {
      context.handle(
        _routineNameSnapshotMeta,
        routineNameSnapshot.isAcceptableOrUnknown(
          data['routine_name_snapshot']!,
          _routineNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('routine_sync_id_snapshot')) {
      context.handle(
        _routineSyncIdSnapshotMeta,
        routineSyncIdSnapshot.isAcceptableOrUnknown(
          data['routine_sync_id_snapshot']!,
          _routineSyncIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('day_name_snapshot')) {
      context.handle(
        _dayNameSnapshotMeta,
        dayNameSnapshot.isAcceptableOrUnknown(
          data['day_name_snapshot']!,
          _dayNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('day_week_snapshot')) {
      context.handle(
        _dayWeekSnapshotMeta,
        dayWeekSnapshot.isAcceptableOrUnknown(
          data['day_week_snapshot']!,
          _dayWeekSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('day_index_snapshot')) {
      context.handle(
        _dayIndexSnapshotMeta,
        dayIndexSnapshot.isAcceptableOrUnknown(
          data['day_index_snapshot']!,
          _dayIndexSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('day_sync_id_snapshot')) {
      context.handle(
        _daySyncIdSnapshotMeta,
        daySyncIdSnapshot.isAcceptableOrUnknown(
          data['day_sync_id_snapshot']!,
          _daySyncIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
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
  LocalWorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutSession(
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
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      ),
      routineNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_name_snapshot'],
      )!,
      routineSyncIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_sync_id_snapshot'],
      )!,
      dayNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_name_snapshot'],
      )!,
      dayWeekSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_week_snapshot'],
      ),
      dayIndexSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index_snapshot'],
      ),
      daySyncIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_sync_id_snapshot'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalWorkoutSessionsTable createAlias(String alias) {
    return $LocalWorkoutSessionsTable(attachedDatabase, alias);
  }
}

class LocalWorkoutSession extends DataClass
    implements Insertable<LocalWorkoutSession> {
  final int id;
  final String syncId;
  final int? remoteId;
  final int routineId;
  final int? dayId;
  final String routineNameSnapshot;
  final String routineSyncIdSnapshot;
  final String dayNameSnapshot;
  final int? dayWeekSnapshot;
  final int? dayIndexSnapshot;
  final String daySyncIdSnapshot;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String note;
  final String syncStatus;
  final DateTime updatedAt;
  const LocalWorkoutSession({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.routineId,
    this.dayId,
    required this.routineNameSnapshot,
    required this.routineSyncIdSnapshot,
    required this.dayNameSnapshot,
    this.dayWeekSnapshot,
    this.dayIndexSnapshot,
    required this.daySyncIdSnapshot,
    required this.startedAt,
    this.endedAt,
    required this.note,
    required this.syncStatus,
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
    map['routine_id'] = Variable<int>(routineId);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    map['routine_name_snapshot'] = Variable<String>(routineNameSnapshot);
    map['routine_sync_id_snapshot'] = Variable<String>(routineSyncIdSnapshot);
    map['day_name_snapshot'] = Variable<String>(dayNameSnapshot);
    if (!nullToAbsent || dayWeekSnapshot != null) {
      map['day_week_snapshot'] = Variable<int>(dayWeekSnapshot);
    }
    if (!nullToAbsent || dayIndexSnapshot != null) {
      map['day_index_snapshot'] = Variable<int>(dayIndexSnapshot);
    }
    map['day_sync_id_snapshot'] = Variable<String>(daySyncIdSnapshot);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['note'] = Variable<String>(note);
    map['sync_status'] = Variable<String>(syncStatus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalWorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutSessionsCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      routineId: Value(routineId),
      dayId: dayId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayId),
      routineNameSnapshot: Value(routineNameSnapshot),
      routineSyncIdSnapshot: Value(routineSyncIdSnapshot),
      dayNameSnapshot: Value(dayNameSnapshot),
      dayWeekSnapshot: dayWeekSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(dayWeekSnapshot),
      dayIndexSnapshot: dayIndexSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(dayIndexSnapshot),
      daySyncIdSnapshot: Value(daySyncIdSnapshot),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      note: Value(note),
      syncStatus: Value(syncStatus),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalWorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      routineId: serializer.fromJson<int>(json['routineId']),
      dayId: serializer.fromJson<int?>(json['dayId']),
      routineNameSnapshot: serializer.fromJson<String>(
        json['routineNameSnapshot'],
      ),
      routineSyncIdSnapshot: serializer.fromJson<String>(
        json['routineSyncIdSnapshot'],
      ),
      dayNameSnapshot: serializer.fromJson<String>(json['dayNameSnapshot']),
      dayWeekSnapshot: serializer.fromJson<int?>(json['dayWeekSnapshot']),
      dayIndexSnapshot: serializer.fromJson<int?>(json['dayIndexSnapshot']),
      daySyncIdSnapshot: serializer.fromJson<String>(json['daySyncIdSnapshot']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      note: serializer.fromJson<String>(json['note']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
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
      'routineId': serializer.toJson<int>(routineId),
      'dayId': serializer.toJson<int?>(dayId),
      'routineNameSnapshot': serializer.toJson<String>(routineNameSnapshot),
      'routineSyncIdSnapshot': serializer.toJson<String>(routineSyncIdSnapshot),
      'dayNameSnapshot': serializer.toJson<String>(dayNameSnapshot),
      'dayWeekSnapshot': serializer.toJson<int?>(dayWeekSnapshot),
      'dayIndexSnapshot': serializer.toJson<int?>(dayIndexSnapshot),
      'daySyncIdSnapshot': serializer.toJson<String>(daySyncIdSnapshot),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'note': serializer.toJson<String>(note),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalWorkoutSession copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    int? routineId,
    Value<int?> dayId = const Value.absent(),
    String? routineNameSnapshot,
    String? routineSyncIdSnapshot,
    String? dayNameSnapshot,
    Value<int?> dayWeekSnapshot = const Value.absent(),
    Value<int?> dayIndexSnapshot = const Value.absent(),
    String? daySyncIdSnapshot,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? note,
    String? syncStatus,
    DateTime? updatedAt,
  }) => LocalWorkoutSession(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    routineId: routineId ?? this.routineId,
    dayId: dayId.present ? dayId.value : this.dayId,
    routineNameSnapshot: routineNameSnapshot ?? this.routineNameSnapshot,
    routineSyncIdSnapshot: routineSyncIdSnapshot ?? this.routineSyncIdSnapshot,
    dayNameSnapshot: dayNameSnapshot ?? this.dayNameSnapshot,
    dayWeekSnapshot: dayWeekSnapshot.present
        ? dayWeekSnapshot.value
        : this.dayWeekSnapshot,
    dayIndexSnapshot: dayIndexSnapshot.present
        ? dayIndexSnapshot.value
        : this.dayIndexSnapshot,
    daySyncIdSnapshot: daySyncIdSnapshot ?? this.daySyncIdSnapshot,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    note: note ?? this.note,
    syncStatus: syncStatus ?? this.syncStatus,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalWorkoutSession copyWithCompanion(LocalWorkoutSessionsCompanion data) {
    return LocalWorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      routineNameSnapshot: data.routineNameSnapshot.present
          ? data.routineNameSnapshot.value
          : this.routineNameSnapshot,
      routineSyncIdSnapshot: data.routineSyncIdSnapshot.present
          ? data.routineSyncIdSnapshot.value
          : this.routineSyncIdSnapshot,
      dayNameSnapshot: data.dayNameSnapshot.present
          ? data.dayNameSnapshot.value
          : this.dayNameSnapshot,
      dayWeekSnapshot: data.dayWeekSnapshot.present
          ? data.dayWeekSnapshot.value
          : this.dayWeekSnapshot,
      dayIndexSnapshot: data.dayIndexSnapshot.present
          ? data.dayIndexSnapshot.value
          : this.dayIndexSnapshot,
      daySyncIdSnapshot: data.daySyncIdSnapshot.present
          ? data.daySyncIdSnapshot.value
          : this.daySyncIdSnapshot,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      note: data.note.present ? data.note.value : this.note,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSession(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('routineId: $routineId, ')
          ..write('dayId: $dayId, ')
          ..write('routineNameSnapshot: $routineNameSnapshot, ')
          ..write('routineSyncIdSnapshot: $routineSyncIdSnapshot, ')
          ..write('dayNameSnapshot: $dayNameSnapshot, ')
          ..write('dayWeekSnapshot: $dayWeekSnapshot, ')
          ..write('dayIndexSnapshot: $dayIndexSnapshot, ')
          ..write('daySyncIdSnapshot: $daySyncIdSnapshot, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('note: $note, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncId,
    remoteId,
    routineId,
    dayId,
    routineNameSnapshot,
    routineSyncIdSnapshot,
    dayNameSnapshot,
    dayWeekSnapshot,
    dayIndexSnapshot,
    daySyncIdSnapshot,
    startedAt,
    endedAt,
    note,
    syncStatus,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutSession &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.routineId == this.routineId &&
          other.dayId == this.dayId &&
          other.routineNameSnapshot == this.routineNameSnapshot &&
          other.routineSyncIdSnapshot == this.routineSyncIdSnapshot &&
          other.dayNameSnapshot == this.dayNameSnapshot &&
          other.dayWeekSnapshot == this.dayWeekSnapshot &&
          other.dayIndexSnapshot == this.dayIndexSnapshot &&
          other.daySyncIdSnapshot == this.daySyncIdSnapshot &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.note == this.note &&
          other.syncStatus == this.syncStatus &&
          other.updatedAt == this.updatedAt);
}

class LocalWorkoutSessionsCompanion
    extends UpdateCompanion<LocalWorkoutSession> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<int> routineId;
  final Value<int?> dayId;
  final Value<String> routineNameSnapshot;
  final Value<String> routineSyncIdSnapshot;
  final Value<String> dayNameSnapshot;
  final Value<int?> dayWeekSnapshot;
  final Value<int?> dayIndexSnapshot;
  final Value<String> daySyncIdSnapshot;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> note;
  final Value<String> syncStatus;
  final Value<DateTime> updatedAt;
  const LocalWorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.dayId = const Value.absent(),
    this.routineNameSnapshot = const Value.absent(),
    this.routineSyncIdSnapshot = const Value.absent(),
    this.dayNameSnapshot = const Value.absent(),
    this.dayWeekSnapshot = const Value.absent(),
    this.dayIndexSnapshot = const Value.absent(),
    this.daySyncIdSnapshot = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalWorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int routineId,
    this.dayId = const Value.absent(),
    this.routineNameSnapshot = const Value.absent(),
    this.routineSyncIdSnapshot = const Value.absent(),
    this.dayNameSnapshot = const Value.absent(),
    this.dayWeekSnapshot = const Value.absent(),
    this.dayIndexSnapshot = const Value.absent(),
    this.daySyncIdSnapshot = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime updatedAt,
  }) : routineId = Value(routineId),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalWorkoutSession> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<int>? routineId,
    Expression<int>? dayId,
    Expression<String>? routineNameSnapshot,
    Expression<String>? routineSyncIdSnapshot,
    Expression<String>? dayNameSnapshot,
    Expression<int>? dayWeekSnapshot,
    Expression<int>? dayIndexSnapshot,
    Expression<String>? daySyncIdSnapshot,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? note,
    Expression<String>? syncStatus,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (routineId != null) 'routine_id': routineId,
      if (dayId != null) 'day_id': dayId,
      if (routineNameSnapshot != null)
        'routine_name_snapshot': routineNameSnapshot,
      if (routineSyncIdSnapshot != null)
        'routine_sync_id_snapshot': routineSyncIdSnapshot,
      if (dayNameSnapshot != null) 'day_name_snapshot': dayNameSnapshot,
      if (dayWeekSnapshot != null) 'day_week_snapshot': dayWeekSnapshot,
      if (dayIndexSnapshot != null) 'day_index_snapshot': dayIndexSnapshot,
      if (daySyncIdSnapshot != null) 'day_sync_id_snapshot': daySyncIdSnapshot,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (note != null) 'note': note,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalWorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<int>? routineId,
    Value<int?>? dayId,
    Value<String>? routineNameSnapshot,
    Value<String>? routineSyncIdSnapshot,
    Value<String>? dayNameSnapshot,
    Value<int?>? dayWeekSnapshot,
    Value<int?>? dayIndexSnapshot,
    Value<String>? daySyncIdSnapshot,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? note,
    Value<String>? syncStatus,
    Value<DateTime>? updatedAt,
  }) {
    return LocalWorkoutSessionsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      routineId: routineId ?? this.routineId,
      dayId: dayId ?? this.dayId,
      routineNameSnapshot: routineNameSnapshot ?? this.routineNameSnapshot,
      routineSyncIdSnapshot:
          routineSyncIdSnapshot ?? this.routineSyncIdSnapshot,
      dayNameSnapshot: dayNameSnapshot ?? this.dayNameSnapshot,
      dayWeekSnapshot: dayWeekSnapshot ?? this.dayWeekSnapshot,
      dayIndexSnapshot: dayIndexSnapshot ?? this.dayIndexSnapshot,
      daySyncIdSnapshot: daySyncIdSnapshot ?? this.daySyncIdSnapshot,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      note: note ?? this.note,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (routineNameSnapshot.present) {
      map['routine_name_snapshot'] = Variable<String>(
        routineNameSnapshot.value,
      );
    }
    if (routineSyncIdSnapshot.present) {
      map['routine_sync_id_snapshot'] = Variable<String>(
        routineSyncIdSnapshot.value,
      );
    }
    if (dayNameSnapshot.present) {
      map['day_name_snapshot'] = Variable<String>(dayNameSnapshot.value);
    }
    if (dayWeekSnapshot.present) {
      map['day_week_snapshot'] = Variable<int>(dayWeekSnapshot.value);
    }
    if (dayIndexSnapshot.present) {
      map['day_index_snapshot'] = Variable<int>(dayIndexSnapshot.value);
    }
    if (daySyncIdSnapshot.present) {
      map['day_sync_id_snapshot'] = Variable<String>(daySyncIdSnapshot.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('routineId: $routineId, ')
          ..write('dayId: $dayId, ')
          ..write('routineNameSnapshot: $routineNameSnapshot, ')
          ..write('routineSyncIdSnapshot: $routineSyncIdSnapshot, ')
          ..write('dayNameSnapshot: $dayNameSnapshot, ')
          ..write('dayWeekSnapshot: $dayWeekSnapshot, ')
          ..write('dayIndexSnapshot: $dayIndexSnapshot, ')
          ..write('daySyncIdSnapshot: $daySyncIdSnapshot, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('note: $note, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutLogsTable extends LocalWorkoutLogs
    with TableInfo<$LocalWorkoutLogsTable, LocalWorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_workout_sessions (id)',
    ),
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_routines (id)',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_training_days (id)',
    ),
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<double> rir = GeneratedColumn<double>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _actualWeightMeta = const VerificationMeta(
    'actualWeight',
  );
  @override
  late final GeneratedColumn<double> actualWeight = GeneratedColumn<double>(
    'actual_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualRepsMeta = const VerificationMeta(
    'actualReps',
  );
  @override
  late final GeneratedColumn<int> actualReps = GeneratedColumn<int>(
    'actual_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualDurationSecondsMeta =
      const VerificationMeta('actualDurationSeconds');
  @override
  late final GeneratedColumn<int> actualDurationSeconds = GeneratedColumn<int>(
    'actual_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasActualValuesMeta = const VerificationMeta(
    'hasActualValues',
  );
  @override
  late final GeneratedColumn<bool> hasActualValues = GeneratedColumn<bool>(
    'has_actual_values',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_actual_values" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recordModeMeta = const VerificationMeta(
    'recordMode',
  );
  @override
  late final GeneratedColumn<String> recordMode = GeneratedColumn<String>(
    'record_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    syncId,
    remoteId,
    sessionId,
    routineId,
    dayId,
    exerciseName,
    setIndex,
    weight,
    reps,
    rir,
    durationSeconds,
    actualWeight,
    actualReps,
    actualDurationSeconds,
    restSeconds,
    hasActualValues,
    recordMode,
    note,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workout_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutLog> instance, {
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
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('actual_weight')) {
      context.handle(
        _actualWeightMeta,
        actualWeight.isAcceptableOrUnknown(
          data['actual_weight']!,
          _actualWeightMeta,
        ),
      );
    }
    if (data.containsKey('actual_reps')) {
      context.handle(
        _actualRepsMeta,
        actualReps.isAcceptableOrUnknown(data['actual_reps']!, _actualRepsMeta),
      );
    }
    if (data.containsKey('actual_duration_seconds')) {
      context.handle(
        _actualDurationSecondsMeta,
        actualDurationSeconds.isAcceptableOrUnknown(
          data['actual_duration_seconds']!,
          _actualDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('has_actual_values')) {
      context.handle(
        _hasActualValuesMeta,
        hasActualValues.isAcceptableOrUnknown(
          data['has_actual_values']!,
          _hasActualValuesMeta,
        ),
      );
    }
    if (data.containsKey('record_mode')) {
      context.handle(
        _recordModeMeta,
        recordMode.isAcceptableOrUnknown(data['record_mode']!, _recordModeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
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
  LocalWorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutLog(
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
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      ),
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rir'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      actualWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_weight'],
      ),
      actualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_reps'],
      ),
      actualDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration_seconds'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      hasActualValues: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_actual_values'],
      )!,
      recordMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_mode'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalWorkoutLogsTable createAlias(String alias) {
    return $LocalWorkoutLogsTable(attachedDatabase, alias);
  }
}

class LocalWorkoutLog extends DataClass implements Insertable<LocalWorkoutLog> {
  final int id;
  final String syncId;
  final int? remoteId;
  final int sessionId;
  final int routineId;
  final int? dayId;
  final String exerciseName;
  final int setIndex;
  final double weight;
  final int reps;
  final double? rir;
  final int durationSeconds;
  final double? actualWeight;
  final int? actualReps;
  final int? actualDurationSeconds;
  final int? restSeconds;
  final bool hasActualValues;
  final String recordMode;
  final String note;
  final String syncStatus;
  final DateTime createdAt;
  const LocalWorkoutLog({
    required this.id,
    required this.syncId,
    this.remoteId,
    required this.sessionId,
    required this.routineId,
    this.dayId,
    required this.exerciseName,
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.rir,
    required this.durationSeconds,
    this.actualWeight,
    this.actualReps,
    this.actualDurationSeconds,
    this.restSeconds,
    required this.hasActualValues,
    required this.recordMode,
    required this.note,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_id'] = Variable<String>(syncId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['session_id'] = Variable<int>(sessionId);
    map['routine_id'] = Variable<int>(routineId);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    map['exercise_name'] = Variable<String>(exerciseName);
    map['set_index'] = Variable<int>(setIndex);
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<double>(rir);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || actualWeight != null) {
      map['actual_weight'] = Variable<double>(actualWeight);
    }
    if (!nullToAbsent || actualReps != null) {
      map['actual_reps'] = Variable<int>(actualReps);
    }
    if (!nullToAbsent || actualDurationSeconds != null) {
      map['actual_duration_seconds'] = Variable<int>(actualDurationSeconds);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['has_actual_values'] = Variable<bool>(hasActualValues);
    map['record_mode'] = Variable<String>(recordMode);
    map['note'] = Variable<String>(note);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalWorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutLogsCompanion(
      id: Value(id),
      syncId: Value(syncId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      sessionId: Value(sessionId),
      routineId: Value(routineId),
      dayId: dayId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayId),
      exerciseName: Value(exerciseName),
      setIndex: Value(setIndex),
      weight: Value(weight),
      reps: Value(reps),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      durationSeconds: Value(durationSeconds),
      actualWeight: actualWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(actualWeight),
      actualReps: actualReps == null && nullToAbsent
          ? const Value.absent()
          : Value(actualReps),
      actualDurationSeconds: actualDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDurationSeconds),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      hasActualValues: Value(hasActualValues),
      recordMode: Value(recordMode),
      note: Value(note),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalWorkoutLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutLog(
      id: serializer.fromJson<int>(json['id']),
      syncId: serializer.fromJson<String>(json['syncId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      routineId: serializer.fromJson<int>(json['routineId']),
      dayId: serializer.fromJson<int?>(json['dayId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<int>(json['reps']),
      rir: serializer.fromJson<double?>(json['rir']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      actualWeight: serializer.fromJson<double?>(json['actualWeight']),
      actualReps: serializer.fromJson<int?>(json['actualReps']),
      actualDurationSeconds: serializer.fromJson<int?>(
        json['actualDurationSeconds'],
      ),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      hasActualValues: serializer.fromJson<bool>(json['hasActualValues']),
      recordMode: serializer.fromJson<String>(json['recordMode']),
      note: serializer.fromJson<String>(json['note']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncId': serializer.toJson<String>(syncId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'sessionId': serializer.toJson<int>(sessionId),
      'routineId': serializer.toJson<int>(routineId),
      'dayId': serializer.toJson<int?>(dayId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'setIndex': serializer.toJson<int>(setIndex),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<int>(reps),
      'rir': serializer.toJson<double?>(rir),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'actualWeight': serializer.toJson<double?>(actualWeight),
      'actualReps': serializer.toJson<int?>(actualReps),
      'actualDurationSeconds': serializer.toJson<int?>(actualDurationSeconds),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'hasActualValues': serializer.toJson<bool>(hasActualValues),
      'recordMode': serializer.toJson<String>(recordMode),
      'note': serializer.toJson<String>(note),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalWorkoutLog copyWith({
    int? id,
    String? syncId,
    Value<int?> remoteId = const Value.absent(),
    int? sessionId,
    int? routineId,
    Value<int?> dayId = const Value.absent(),
    String? exerciseName,
    int? setIndex,
    double? weight,
    int? reps,
    Value<double?> rir = const Value.absent(),
    int? durationSeconds,
    Value<double?> actualWeight = const Value.absent(),
    Value<int?> actualReps = const Value.absent(),
    Value<int?> actualDurationSeconds = const Value.absent(),
    Value<int?> restSeconds = const Value.absent(),
    bool? hasActualValues,
    String? recordMode,
    String? note,
    String? syncStatus,
    DateTime? createdAt,
  }) => LocalWorkoutLog(
    id: id ?? this.id,
    syncId: syncId ?? this.syncId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    sessionId: sessionId ?? this.sessionId,
    routineId: routineId ?? this.routineId,
    dayId: dayId.present ? dayId.value : this.dayId,
    exerciseName: exerciseName ?? this.exerciseName,
    setIndex: setIndex ?? this.setIndex,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    rir: rir.present ? rir.value : this.rir,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    actualWeight: actualWeight.present ? actualWeight.value : this.actualWeight,
    actualReps: actualReps.present ? actualReps.value : this.actualReps,
    actualDurationSeconds: actualDurationSeconds.present
        ? actualDurationSeconds.value
        : this.actualDurationSeconds,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    hasActualValues: hasActualValues ?? this.hasActualValues,
    recordMode: recordMode ?? this.recordMode,
    note: note ?? this.note,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalWorkoutLog copyWithCompanion(LocalWorkoutLogsCompanion data) {
    return LocalWorkoutLog(
      id: data.id.present ? data.id.value : this.id,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rir: data.rir.present ? data.rir.value : this.rir,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      actualWeight: data.actualWeight.present
          ? data.actualWeight.value
          : this.actualWeight,
      actualReps: data.actualReps.present
          ? data.actualReps.value
          : this.actualReps,
      actualDurationSeconds: data.actualDurationSeconds.present
          ? data.actualDurationSeconds.value
          : this.actualDurationSeconds,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      hasActualValues: data.hasActualValues.present
          ? data.hasActualValues.value
          : this.hasActualValues,
      recordMode: data.recordMode.present
          ? data.recordMode.value
          : this.recordMode,
      note: data.note.present ? data.note.value : this.note,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutLog(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('sessionId: $sessionId, ')
          ..write('routineId: $routineId, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('hasActualValues: $hasActualValues, ')
          ..write('recordMode: $recordMode, ')
          ..write('note: $note, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    syncId,
    remoteId,
    sessionId,
    routineId,
    dayId,
    exerciseName,
    setIndex,
    weight,
    reps,
    rir,
    durationSeconds,
    actualWeight,
    actualReps,
    actualDurationSeconds,
    restSeconds,
    hasActualValues,
    recordMode,
    note,
    syncStatus,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutLog &&
          other.id == this.id &&
          other.syncId == this.syncId &&
          other.remoteId == this.remoteId &&
          other.sessionId == this.sessionId &&
          other.routineId == this.routineId &&
          other.dayId == this.dayId &&
          other.exerciseName == this.exerciseName &&
          other.setIndex == this.setIndex &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rir == this.rir &&
          other.durationSeconds == this.durationSeconds &&
          other.actualWeight == this.actualWeight &&
          other.actualReps == this.actualReps &&
          other.actualDurationSeconds == this.actualDurationSeconds &&
          other.restSeconds == this.restSeconds &&
          other.hasActualValues == this.hasActualValues &&
          other.recordMode == this.recordMode &&
          other.note == this.note &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalWorkoutLogsCompanion extends UpdateCompanion<LocalWorkoutLog> {
  final Value<int> id;
  final Value<String> syncId;
  final Value<int?> remoteId;
  final Value<int> sessionId;
  final Value<int> routineId;
  final Value<int?> dayId;
  final Value<String> exerciseName;
  final Value<int> setIndex;
  final Value<double> weight;
  final Value<int> reps;
  final Value<double?> rir;
  final Value<int> durationSeconds;
  final Value<double?> actualWeight;
  final Value<int?> actualReps;
  final Value<int?> actualDurationSeconds;
  final Value<int?> restSeconds;
  final Value<bool> hasActualValues;
  final Value<String> recordMode;
  final Value<String> note;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  const LocalWorkoutLogsCompanion({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.actualDurationSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.hasActualValues = const Value.absent(),
    this.recordMode = const Value.absent(),
    this.note = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalWorkoutLogsCompanion.insert({
    this.id = const Value.absent(),
    this.syncId = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int sessionId,
    required int routineId,
    this.dayId = const Value.absent(),
    required String exerciseName,
    required int setIndex,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.actualDurationSeconds = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.hasActualValues = const Value.absent(),
    this.recordMode = const Value.absent(),
    this.note = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       routineId = Value(routineId),
       exerciseName = Value(exerciseName),
       setIndex = Value(setIndex),
       createdAt = Value(createdAt);
  static Insertable<LocalWorkoutLog> custom({
    Expression<int>? id,
    Expression<String>? syncId,
    Expression<int>? remoteId,
    Expression<int>? sessionId,
    Expression<int>? routineId,
    Expression<int>? dayId,
    Expression<String>? exerciseName,
    Expression<int>? setIndex,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<double>? rir,
    Expression<int>? durationSeconds,
    Expression<double>? actualWeight,
    Expression<int>? actualReps,
    Expression<int>? actualDurationSeconds,
    Expression<int>? restSeconds,
    Expression<bool>? hasActualValues,
    Expression<String>? recordMode,
    Expression<String>? note,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncId != null) 'sync_id': syncId,
      if (remoteId != null) 'remote_id': remoteId,
      if (sessionId != null) 'session_id': sessionId,
      if (routineId != null) 'routine_id': routineId,
      if (dayId != null) 'day_id': dayId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (setIndex != null) 'set_index': setIndex,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rir != null) 'rir': rir,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (actualWeight != null) 'actual_weight': actualWeight,
      if (actualReps != null) 'actual_reps': actualReps,
      if (actualDurationSeconds != null)
        'actual_duration_seconds': actualDurationSeconds,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (hasActualValues != null) 'has_actual_values': hasActualValues,
      if (recordMode != null) 'record_mode': recordMode,
      if (note != null) 'note': note,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalWorkoutLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? syncId,
    Value<int?>? remoteId,
    Value<int>? sessionId,
    Value<int>? routineId,
    Value<int?>? dayId,
    Value<String>? exerciseName,
    Value<int>? setIndex,
    Value<double>? weight,
    Value<int>? reps,
    Value<double?>? rir,
    Value<int>? durationSeconds,
    Value<double?>? actualWeight,
    Value<int?>? actualReps,
    Value<int?>? actualDurationSeconds,
    Value<int?>? restSeconds,
    Value<bool>? hasActualValues,
    Value<String>? recordMode,
    Value<String>? note,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
  }) {
    return LocalWorkoutLogsCompanion(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      sessionId: sessionId ?? this.sessionId,
      routineId: routineId ?? this.routineId,
      dayId: dayId ?? this.dayId,
      exerciseName: exerciseName ?? this.exerciseName,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      actualWeight: actualWeight ?? this.actualWeight,
      actualReps: actualReps ?? this.actualReps,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      hasActualValues: hasActualValues ?? this.hasActualValues,
      recordMode: recordMode ?? this.recordMode,
      note: note ?? this.note,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
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
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rir.present) {
      map['rir'] = Variable<double>(rir.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (actualWeight.present) {
      map['actual_weight'] = Variable<double>(actualWeight.value);
    }
    if (actualReps.present) {
      map['actual_reps'] = Variable<int>(actualReps.value);
    }
    if (actualDurationSeconds.present) {
      map['actual_duration_seconds'] = Variable<int>(
        actualDurationSeconds.value,
      );
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (hasActualValues.present) {
      map['has_actual_values'] = Variable<bool>(hasActualValues.value);
    }
    if (recordMode.present) {
      map['record_mode'] = Variable<String>(recordMode.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutLogsCompanion(')
          ..write('id: $id, ')
          ..write('syncId: $syncId, ')
          ..write('remoteId: $remoteId, ')
          ..write('sessionId: $sessionId, ')
          ..write('routineId: $routineId, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualReps: $actualReps, ')
          ..write('actualDurationSeconds: $actualDurationSeconds, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('hasActualValues: $hasActualValues, ')
          ..write('recordMode: $recordMode, ')
          ..write('note: $note, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalWorkoutSetDraftsTable extends LocalWorkoutSetDrafts
    with TableInfo<$LocalWorkoutSetDraftsTable, LocalWorkoutSetDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutSetDraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_workout_sessions (id)',
    ),
  );
  static const VerificationMeta _actionIndexMeta = const VerificationMeta(
    'actionIndex',
  );
  @override
  late final GeneratedColumn<int> actionIndex = GeneratedColumn<int>(
    'action_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightTextMeta = const VerificationMeta(
    'weightText',
  );
  @override
  late final GeneratedColumn<String> weightText = GeneratedColumn<String>(
    'weight_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _repsTextMeta = const VerificationMeta(
    'repsText',
  );
  @override
  late final GeneratedColumn<String> repsText = GeneratedColumn<String>(
    'reps_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationTextMeta = const VerificationMeta(
    'durationText',
  );
  @override
  late final GeneratedColumn<String> durationText = GeneratedColumn<String>(
    'duration_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _restTextMeta = const VerificationMeta(
    'restText',
  );
  @override
  late final GeneratedColumn<String> restText = GeneratedColumn<String>(
    'rest_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteTextMeta = const VerificationMeta(
    'noteText',
  );
  @override
  late final GeneratedColumn<String> noteText = GeneratedColumn<String>(
    'note_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    sessionId,
    actionIndex,
    setIndex,
    weightText,
    repsText,
    durationText,
    restText,
    noteText,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workout_set_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkoutSetDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('action_index')) {
      context.handle(
        _actionIndexMeta,
        actionIndex.isAcceptableOrUnknown(
          data['action_index']!,
          _actionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actionIndexMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight_text')) {
      context.handle(
        _weightTextMeta,
        weightText.isAcceptableOrUnknown(data['weight_text']!, _weightTextMeta),
      );
    }
    if (data.containsKey('reps_text')) {
      context.handle(
        _repsTextMeta,
        repsText.isAcceptableOrUnknown(data['reps_text']!, _repsTextMeta),
      );
    }
    if (data.containsKey('duration_text')) {
      context.handle(
        _durationTextMeta,
        durationText.isAcceptableOrUnknown(
          data['duration_text']!,
          _durationTextMeta,
        ),
      );
    }
    if (data.containsKey('rest_text')) {
      context.handle(
        _restTextMeta,
        restText.isAcceptableOrUnknown(data['rest_text']!, _restTextMeta),
      );
    }
    if (data.containsKey('note_text')) {
      context.handle(
        _noteTextMeta,
        noteText.isAcceptableOrUnknown(data['note_text']!, _noteTextMeta),
      );
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, actionIndex, setIndex},
  ];
  @override
  LocalWorkoutSetDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkoutSetDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      actionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_index'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      weightText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_text'],
      )!,
      repsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reps_text'],
      )!,
      durationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration_text'],
      )!,
      restText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rest_text'],
      )!,
      noteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_text'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalWorkoutSetDraftsTable createAlias(String alias) {
    return $LocalWorkoutSetDraftsTable(attachedDatabase, alias);
  }
}

class LocalWorkoutSetDraft extends DataClass
    implements Insertable<LocalWorkoutSetDraft> {
  final int id;
  final int sessionId;
  final int actionIndex;
  final int setIndex;
  final String weightText;
  final String repsText;
  final String durationText;
  final String restText;
  final String noteText;
  final DateTime updatedAt;
  const LocalWorkoutSetDraft({
    required this.id,
    required this.sessionId,
    required this.actionIndex,
    required this.setIndex,
    required this.weightText,
    required this.repsText,
    required this.durationText,
    required this.restText,
    required this.noteText,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['action_index'] = Variable<int>(actionIndex);
    map['set_index'] = Variable<int>(setIndex);
    map['weight_text'] = Variable<String>(weightText);
    map['reps_text'] = Variable<String>(repsText);
    map['duration_text'] = Variable<String>(durationText);
    map['rest_text'] = Variable<String>(restText);
    map['note_text'] = Variable<String>(noteText);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalWorkoutSetDraftsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutSetDraftsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      actionIndex: Value(actionIndex),
      setIndex: Value(setIndex),
      weightText: Value(weightText),
      repsText: Value(repsText),
      durationText: Value(durationText),
      restText: Value(restText),
      noteText: Value(noteText),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalWorkoutSetDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkoutSetDraft(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      actionIndex: serializer.fromJson<int>(json['actionIndex']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weightText: serializer.fromJson<String>(json['weightText']),
      repsText: serializer.fromJson<String>(json['repsText']),
      durationText: serializer.fromJson<String>(json['durationText']),
      restText: serializer.fromJson<String>(json['restText']),
      noteText: serializer.fromJson<String>(json['noteText']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'actionIndex': serializer.toJson<int>(actionIndex),
      'setIndex': serializer.toJson<int>(setIndex),
      'weightText': serializer.toJson<String>(weightText),
      'repsText': serializer.toJson<String>(repsText),
      'durationText': serializer.toJson<String>(durationText),
      'restText': serializer.toJson<String>(restText),
      'noteText': serializer.toJson<String>(noteText),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalWorkoutSetDraft copyWith({
    int? id,
    int? sessionId,
    int? actionIndex,
    int? setIndex,
    String? weightText,
    String? repsText,
    String? durationText,
    String? restText,
    String? noteText,
    DateTime? updatedAt,
  }) => LocalWorkoutSetDraft(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    actionIndex: actionIndex ?? this.actionIndex,
    setIndex: setIndex ?? this.setIndex,
    weightText: weightText ?? this.weightText,
    repsText: repsText ?? this.repsText,
    durationText: durationText ?? this.durationText,
    restText: restText ?? this.restText,
    noteText: noteText ?? this.noteText,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalWorkoutSetDraft copyWithCompanion(LocalWorkoutSetDraftsCompanion data) {
    return LocalWorkoutSetDraft(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      actionIndex: data.actionIndex.present
          ? data.actionIndex.value
          : this.actionIndex,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weightText: data.weightText.present
          ? data.weightText.value
          : this.weightText,
      repsText: data.repsText.present ? data.repsText.value : this.repsText,
      durationText: data.durationText.present
          ? data.durationText.value
          : this.durationText,
      restText: data.restText.present ? data.restText.value : this.restText,
      noteText: data.noteText.present ? data.noteText.value : this.noteText,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSetDraft(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('actionIndex: $actionIndex, ')
          ..write('setIndex: $setIndex, ')
          ..write('weightText: $weightText, ')
          ..write('repsText: $repsText, ')
          ..write('durationText: $durationText, ')
          ..write('restText: $restText, ')
          ..write('noteText: $noteText, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    actionIndex,
    setIndex,
    weightText,
    repsText,
    durationText,
    restText,
    noteText,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkoutSetDraft &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.actionIndex == this.actionIndex &&
          other.setIndex == this.setIndex &&
          other.weightText == this.weightText &&
          other.repsText == this.repsText &&
          other.durationText == this.durationText &&
          other.restText == this.restText &&
          other.noteText == this.noteText &&
          other.updatedAt == this.updatedAt);
}

class LocalWorkoutSetDraftsCompanion
    extends UpdateCompanion<LocalWorkoutSetDraft> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> actionIndex;
  final Value<int> setIndex;
  final Value<String> weightText;
  final Value<String> repsText;
  final Value<String> durationText;
  final Value<String> restText;
  final Value<String> noteText;
  final Value<DateTime> updatedAt;
  const LocalWorkoutSetDraftsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.actionIndex = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weightText = const Value.absent(),
    this.repsText = const Value.absent(),
    this.durationText = const Value.absent(),
    this.restText = const Value.absent(),
    this.noteText = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalWorkoutSetDraftsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int actionIndex,
    required int setIndex,
    this.weightText = const Value.absent(),
    this.repsText = const Value.absent(),
    this.durationText = const Value.absent(),
    this.restText = const Value.absent(),
    this.noteText = const Value.absent(),
    required DateTime updatedAt,
  }) : sessionId = Value(sessionId),
       actionIndex = Value(actionIndex),
       setIndex = Value(setIndex),
       updatedAt = Value(updatedAt);
  static Insertable<LocalWorkoutSetDraft> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? actionIndex,
    Expression<int>? setIndex,
    Expression<String>? weightText,
    Expression<String>? repsText,
    Expression<String>? durationText,
    Expression<String>? restText,
    Expression<String>? noteText,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (actionIndex != null) 'action_index': actionIndex,
      if (setIndex != null) 'set_index': setIndex,
      if (weightText != null) 'weight_text': weightText,
      if (repsText != null) 'reps_text': repsText,
      if (durationText != null) 'duration_text': durationText,
      if (restText != null) 'rest_text': restText,
      if (noteText != null) 'note_text': noteText,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalWorkoutSetDraftsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? actionIndex,
    Value<int>? setIndex,
    Value<String>? weightText,
    Value<String>? repsText,
    Value<String>? durationText,
    Value<String>? restText,
    Value<String>? noteText,
    Value<DateTime>? updatedAt,
  }) {
    return LocalWorkoutSetDraftsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      actionIndex: actionIndex ?? this.actionIndex,
      setIndex: setIndex ?? this.setIndex,
      weightText: weightText ?? this.weightText,
      repsText: repsText ?? this.repsText,
      durationText: durationText ?? this.durationText,
      restText: restText ?? this.restText,
      noteText: noteText ?? this.noteText,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (actionIndex.present) {
      map['action_index'] = Variable<int>(actionIndex.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weightText.present) {
      map['weight_text'] = Variable<String>(weightText.value);
    }
    if (repsText.present) {
      map['reps_text'] = Variable<String>(repsText.value);
    }
    if (durationText.present) {
      map['duration_text'] = Variable<String>(durationText.value);
    }
    if (restText.present) {
      map['rest_text'] = Variable<String>(restText.value);
    }
    if (noteText.present) {
      map['note_text'] = Variable<String>(noteText.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutSetDraftsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('actionIndex: $actionIndex, ')
          ..write('setIndex: $setIndex, ')
          ..write('weightText: $weightText, ')
          ..write('repsText: $repsText, ')
          ..write('durationText: $durationText, ')
          ..write('restText: $restText, ')
          ..write('noteText: $noteText, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncQueueTable extends LocalSyncQueue
    with TableInfo<$LocalSyncQueueTable, LocalSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entitySyncIdMeta = const VerificationMeta(
    'entitySyncId',
  );
  @override
  late final GeneratedColumn<String> entitySyncId = GeneratedColumn<String>(
    'entity_sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    eventId,
    deviceId,
    entityType,
    entityId,
    entitySyncId,
    action,
    payload,
    status,
    serverSeq,
    attempts,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_sync_id')) {
      context.handle(
        _entitySyncIdMeta,
        entitySyncId.isAcceptableOrUnknown(
          data['entity_sync_id']!,
          _entitySyncIdMeta,
        ),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
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
  LocalSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      entitySyncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_sync_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
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
  $LocalSyncQueueTable createAlias(String alias) {
    return $LocalSyncQueueTable(attachedDatabase, alias);
  }
}

class LocalSyncQueueData extends DataClass
    implements Insertable<LocalSyncQueueData> {
  final int id;
  final String eventId;
  final String deviceId;
  final String entityType;
  final int entityId;
  final String entitySyncId;
  final String action;
  final String payload;
  final String status;
  final int? serverSeq;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalSyncQueueData({
    required this.id,
    required this.eventId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.entitySyncId,
    required this.action,
    required this.payload,
    required this.status,
    this.serverSeq,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['device_id'] = Variable<String>(deviceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['entity_sync_id'] = Variable<String>(entitySyncId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncQueueCompanion(
      id: Value(id),
      eventId: Value(eventId),
      deviceId: Value(deviceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      entitySyncId: Value(entitySyncId),
      action: Value(action),
      payload: Value(payload),
      status: Value(status),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      entitySyncId: serializer.fromJson<String>(json['entitySyncId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'deviceId': serializer.toJson<String>(deviceId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'entitySyncId': serializer.toJson<String>(entitySyncId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncQueueData copyWith({
    int? id,
    String? eventId,
    String? deviceId,
    String? entityType,
    int? entityId,
    String? entitySyncId,
    String? action,
    String? payload,
    String? status,
    Value<int?> serverSeq = const Value.absent(),
    int? attempts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalSyncQueueData(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    deviceId: deviceId ?? this.deviceId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    entitySyncId: entitySyncId ?? this.entitySyncId,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSyncQueueData copyWithCompanion(LocalSyncQueueCompanion data) {
    return LocalSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entitySyncId: data.entitySyncId.present
          ? data.entitySyncId.value
          : this.entitySyncId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueData(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    deviceId,
    entityType,
    entityId,
    entitySyncId,
    action,
    payload,
    status,
    serverSeq,
    attempts,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncQueueData &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.deviceId == this.deviceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.entitySyncId == this.entitySyncId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.serverSeq == this.serverSeq &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncQueueCompanion extends UpdateCompanion<LocalSyncQueueData> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> deviceId;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> entitySyncId;
  final Value<String> action;
  final Value<String> payload;
  final Value<String> status;
  final Value<int?> serverSeq;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LocalSyncQueueCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entitySyncId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalSyncQueueCompanion.insert({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.deviceId = const Value.absent(),
    required String entityType,
    required int entityId,
    this.entitySyncId = const Value.absent(),
    required String action,
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? deviceId,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? entitySyncId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? serverSeq,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (deviceId != null) 'device_id': deviceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (entitySyncId != null) 'entity_sync_id': entitySyncId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalSyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? deviceId,
    Value<String>? entityType,
    Value<int>? entityId,
    Value<String>? entitySyncId,
    Value<String>? action,
    Value<String>? payload,
    Value<String>? status,
    Value<int?>? serverSeq,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LocalSyncQueueCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entitySyncId: entitySyncId ?? this.entitySyncId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      serverSeq: serverSeq ?? this.serverSeq,
      attempts: attempts ?? this.attempts,
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
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (entitySyncId.present) {
      map['entity_sync_id'] = Variable<String>(entitySyncId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
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
    return (StringBuffer('LocalSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalTrainingDatabase extends GeneratedDatabase {
  _$LocalTrainingDatabase(QueryExecutor e) : super(e);
  $LocalTrainingDatabaseManager get managers =>
      $LocalTrainingDatabaseManager(this);
  late final $LocalRoutinesTable localRoutines = $LocalRoutinesTable(this);
  late final $LocalTrainingDaysTable localTrainingDays =
      $LocalTrainingDaysTable(this);
  late final $LocalSlotsTable localSlots = $LocalSlotsTable(this);
  late final $LocalSlotEntriesTable localSlotEntries = $LocalSlotEntriesTable(
    this,
  );
  late final $LocalWorkoutSessionsTable localWorkoutSessions =
      $LocalWorkoutSessionsTable(this);
  late final $LocalWorkoutLogsTable localWorkoutLogs = $LocalWorkoutLogsTable(
    this,
  );
  late final $LocalWorkoutSetDraftsTable localWorkoutSetDrafts =
      $LocalWorkoutSetDraftsTable(this);
  late final $LocalSyncQueueTable localSyncQueue = $LocalSyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localRoutines,
    localTrainingDays,
    localSlots,
    localSlotEntries,
    localWorkoutSessions,
    localWorkoutLogs,
    localWorkoutSetDrafts,
    localSyncQueue,
  ];
}

typedef $$LocalRoutinesTableCreateCompanionBuilder =
    LocalRoutinesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required String name,
      Value<int> totalWeeks,
      Value<int> daysPerWeek,
      Value<bool> archived,
      Value<String> completedWeeksJson,
      Value<String> syncStatus,
      Value<bool> deleted,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$LocalRoutinesTableUpdateCompanionBuilder =
    LocalRoutinesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<String> name,
      Value<int> totalWeeks,
      Value<int> daysPerWeek,
      Value<bool> archived,
      Value<String> completedWeeksJson,
      Value<String> syncStatus,
      Value<bool> deleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$LocalRoutinesTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalRoutinesTable,
          LocalRoutine
        > {
  $$LocalRoutinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocalTrainingDaysTable, List<LocalTrainingDay>>
  _localTrainingDaysRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localTrainingDays,
        aliasName: $_aliasNameGenerator(
          db.localRoutines.id,
          db.localTrainingDays.routineId,
        ),
      );

  $$LocalTrainingDaysTableProcessedTableManager get localTrainingDaysRefs {
    final manager = $$LocalTrainingDaysTableTableManager(
      $_db,
      $_db.localTrainingDays,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localTrainingDaysRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalWorkoutSessionsTable,
    List<LocalWorkoutSession>
  >
  _localWorkoutSessionsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutSessions,
        aliasName: $_aliasNameGenerator(
          db.localRoutines.id,
          db.localWorkoutSessions.routineId,
        ),
      );

  $$LocalWorkoutSessionsTableProcessedTableManager
  get localWorkoutSessionsRefs {
    final manager = $$LocalWorkoutSessionsTableTableManager(
      $_db,
      $_db.localWorkoutSessions,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalWorkoutLogsTable, List<LocalWorkoutLog>>
  _localWorkoutLogsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutLogs,
        aliasName: $_aliasNameGenerator(
          db.localRoutines.id,
          db.localWorkoutLogs.routineId,
        ),
      );

  $$LocalWorkoutLogsTableProcessedTableManager get localWorkoutLogsRefs {
    final manager = $$LocalWorkoutLogsTableTableManager(
      $_db,
      $_db.localWorkoutLogs,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalRoutinesTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalRoutinesTable> {
  $$LocalRoutinesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedWeeksJson => $composableBuilder(
    column: $table.completedWeeksJson,
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

  Expression<bool> localTrainingDaysRefs(
    Expression<bool> Function($$LocalTrainingDaysTableFilterComposer f) f,
  ) {
    final $$LocalTrainingDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableFilterComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localWorkoutSessionsRefs(
    Expression<bool> Function($$LocalWorkoutSessionsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutSessions,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localWorkoutLogsRefs(
    Expression<bool> Function($$LocalWorkoutLogsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalRoutinesTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalRoutinesTable> {
  $$LocalRoutinesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedWeeksJson => $composableBuilder(
    column: $table.completedWeeksJson,
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

class $$LocalRoutinesTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalRoutinesTable> {
  $$LocalRoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get completedWeeksJson => $composableBuilder(
    column: $table.completedWeeksJson,
    builder: (column) => column,
  );

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

  Expression<T> localTrainingDaysRefs<T extends Object>(
    Expression<T> Function($$LocalTrainingDaysTableAnnotationComposer a) f,
  ) {
    final $$LocalTrainingDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localTrainingDays,
          getReferencedColumn: (t) => t.routineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalTrainingDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.localTrainingDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localWorkoutSessionsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutSessionsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.routineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localWorkoutLogsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutLogsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalRoutinesTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalRoutinesTable,
          LocalRoutine,
          $$LocalRoutinesTableFilterComposer,
          $$LocalRoutinesTableOrderingComposer,
          $$LocalRoutinesTableAnnotationComposer,
          $$LocalRoutinesTableCreateCompanionBuilder,
          $$LocalRoutinesTableUpdateCompanionBuilder,
          (LocalRoutine, $$LocalRoutinesTableReferences),
          LocalRoutine,
          PrefetchHooks Function({
            bool localTrainingDaysRefs,
            bool localWorkoutSessionsRefs,
            bool localWorkoutLogsRefs,
          })
        > {
  $$LocalRoutinesTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalRoutinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> totalWeeks = const Value.absent(),
                Value<int> daysPerWeek = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> completedWeeksJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalRoutinesCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                name: name,
                totalWeeks: totalWeeks,
                daysPerWeek: daysPerWeek,
                archived: archived,
                completedWeeksJson: completedWeeksJson,
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
                required String name,
                Value<int> totalWeeks = const Value.absent(),
                Value<int> daysPerWeek = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> completedWeeksJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => LocalRoutinesCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                name: name,
                totalWeeks: totalWeeks,
                daysPerWeek: daysPerWeek,
                archived: archived,
                completedWeeksJson: completedWeeksJson,
                syncStatus: syncStatus,
                deleted: deleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalRoutinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                localTrainingDaysRefs = false,
                localWorkoutSessionsRefs = false,
                localWorkoutLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localTrainingDaysRefs) db.localTrainingDays,
                    if (localWorkoutSessionsRefs) db.localWorkoutSessions,
                    if (localWorkoutLogsRefs) db.localWorkoutLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localTrainingDaysRefs)
                        await $_getPrefetchedData<
                          LocalRoutine,
                          $LocalRoutinesTable,
                          LocalTrainingDay
                        >(
                          currentTable: table,
                          referencedTable: $$LocalRoutinesTableReferences
                              ._localTrainingDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalRoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).localTrainingDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localWorkoutSessionsRefs)
                        await $_getPrefetchedData<
                          LocalRoutine,
                          $LocalRoutinesTable,
                          LocalWorkoutSession
                        >(
                          currentTable: table,
                          referencedTable: $$LocalRoutinesTableReferences
                              ._localWorkoutSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalRoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localWorkoutLogsRefs)
                        await $_getPrefetchedData<
                          LocalRoutine,
                          $LocalRoutinesTable,
                          LocalWorkoutLog
                        >(
                          currentTable: table,
                          referencedTable: $$LocalRoutinesTableReferences
                              ._localWorkoutLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalRoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalRoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalRoutinesTable,
      LocalRoutine,
      $$LocalRoutinesTableFilterComposer,
      $$LocalRoutinesTableOrderingComposer,
      $$LocalRoutinesTableAnnotationComposer,
      $$LocalRoutinesTableCreateCompanionBuilder,
      $$LocalRoutinesTableUpdateCompanionBuilder,
      (LocalRoutine, $$LocalRoutinesTableReferences),
      LocalRoutine,
      PrefetchHooks Function({
        bool localTrainingDaysRefs,
        bool localWorkoutSessionsRefs,
        bool localWorkoutLogsRefs,
      })
    >;
typedef $$LocalTrainingDaysTableCreateCompanionBuilder =
    LocalTrainingDaysCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required int routineId,
      required int week,
      required int day,
      required String name,
      Value<String> actionsJson,
      Value<String> syncStatus,
      required DateTime updatedAt,
    });
typedef $$LocalTrainingDaysTableUpdateCompanionBuilder =
    LocalTrainingDaysCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<int> routineId,
      Value<int> week,
      Value<int> day,
      Value<String> name,
      Value<String> actionsJson,
      Value<String> syncStatus,
      Value<DateTime> updatedAt,
    });

final class $$LocalTrainingDaysTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalTrainingDaysTable,
          LocalTrainingDay
        > {
  $$LocalTrainingDaysTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalRoutinesTable _routineIdTable(_$LocalTrainingDatabase db) =>
      db.localRoutines.createAlias(
        $_aliasNameGenerator(
          db.localTrainingDays.routineId,
          db.localRoutines.id,
        ),
      );

  $$LocalRoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$LocalRoutinesTableTableManager(
      $_db,
      $_db.localRoutines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LocalSlotsTable, List<LocalSlot>>
  _localSlotsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localSlots,
        aliasName: $_aliasNameGenerator(
          db.localTrainingDays.id,
          db.localSlots.dayId,
        ),
      );

  $$LocalSlotsTableProcessedTableManager get localSlotsRefs {
    final manager = $$LocalSlotsTableTableManager(
      $_db,
      $_db.localSlots,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_localSlotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalWorkoutSessionsTable,
    List<LocalWorkoutSession>
  >
  _localWorkoutSessionsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutSessions,
        aliasName: $_aliasNameGenerator(
          db.localTrainingDays.id,
          db.localWorkoutSessions.dayId,
        ),
      );

  $$LocalWorkoutSessionsTableProcessedTableManager
  get localWorkoutSessionsRefs {
    final manager = $$LocalWorkoutSessionsTableTableManager(
      $_db,
      $_db.localWorkoutSessions,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalWorkoutLogsTable, List<LocalWorkoutLog>>
  _localWorkoutLogsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutLogs,
        aliasName: $_aliasNameGenerator(
          db.localTrainingDays.id,
          db.localWorkoutLogs.dayId,
        ),
      );

  $$LocalWorkoutLogsTableProcessedTableManager get localWorkoutLogsRefs {
    final manager = $$LocalWorkoutLogsTableTableManager(
      $_db,
      $_db.localWorkoutLogs,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalTrainingDaysTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalTrainingDaysTable> {
  $$LocalTrainingDaysTableFilterComposer({
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

  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalRoutinesTableFilterComposer get routineId {
    final $$LocalRoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableFilterComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> localSlotsRefs(
    Expression<bool> Function($$LocalSlotsTableFilterComposer f) f,
  ) {
    final $$LocalSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSlots,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotsTableFilterComposer(
            $db: $db,
            $table: $db.localSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localWorkoutSessionsRefs(
    Expression<bool> Function($$LocalWorkoutSessionsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutSessions,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localWorkoutLogsRefs(
    Expression<bool> Function($$LocalWorkoutLogsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTrainingDaysTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalTrainingDaysTable> {
  $$LocalTrainingDaysTableOrderingComposer({
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

  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalRoutinesTableOrderingComposer get routineId {
    final $$LocalRoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrainingDaysTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalTrainingDaysTable> {
  $$LocalTrainingDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get actionsJson => $composableBuilder(
    column: $table.actionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalRoutinesTableAnnotationComposer get routineId {
    final $$LocalRoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> localSlotsRefs<T extends Object>(
    Expression<T> Function($$LocalSlotsTableAnnotationComposer a) f,
  ) {
    final $$LocalSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSlots,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.localSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localWorkoutSessionsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutSessionsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.dayId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> localWorkoutLogsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutLogsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTrainingDaysTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalTrainingDaysTable,
          LocalTrainingDay,
          $$LocalTrainingDaysTableFilterComposer,
          $$LocalTrainingDaysTableOrderingComposer,
          $$LocalTrainingDaysTableAnnotationComposer,
          $$LocalTrainingDaysTableCreateCompanionBuilder,
          $$LocalTrainingDaysTableUpdateCompanionBuilder,
          (LocalTrainingDay, $$LocalTrainingDaysTableReferences),
          LocalTrainingDay,
          PrefetchHooks Function({
            bool routineId,
            bool localSlotsRefs,
            bool localWorkoutSessionsRefs,
            bool localWorkoutLogsRefs,
          })
        > {
  $$LocalTrainingDaysTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalTrainingDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTrainingDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTrainingDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTrainingDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int> week = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> actionsJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalTrainingDaysCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                routineId: routineId,
                week: week,
                day: day,
                name: name,
                actionsJson: actionsJson,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int routineId,
                required int week,
                required int day,
                required String name,
                Value<String> actionsJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalTrainingDaysCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                routineId: routineId,
                week: week,
                day: day,
                name: name,
                actionsJson: actionsJson,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalTrainingDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routineId = false,
                localSlotsRefs = false,
                localWorkoutSessionsRefs = false,
                localWorkoutLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localSlotsRefs) db.localSlots,
                    if (localWorkoutSessionsRefs) db.localWorkoutSessions,
                    if (localWorkoutLogsRefs) db.localWorkoutLogs,
                  ],
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
                        if (routineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routineId,
                                    referencedTable:
                                        $$LocalTrainingDaysTableReferences
                                            ._routineIdTable(db),
                                    referencedColumn:
                                        $$LocalTrainingDaysTableReferences
                                            ._routineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localSlotsRefs)
                        await $_getPrefetchedData<
                          LocalTrainingDay,
                          $LocalTrainingDaysTable,
                          LocalSlot
                        >(
                          currentTable: table,
                          referencedTable: $$LocalTrainingDaysTableReferences
                              ._localSlotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalTrainingDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).localSlotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localWorkoutSessionsRefs)
                        await $_getPrefetchedData<
                          LocalTrainingDay,
                          $LocalTrainingDaysTable,
                          LocalWorkoutSession
                        >(
                          currentTable: table,
                          referencedTable: $$LocalTrainingDaysTableReferences
                              ._localWorkoutSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalTrainingDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localWorkoutLogsRefs)
                        await $_getPrefetchedData<
                          LocalTrainingDay,
                          $LocalTrainingDaysTable,
                          LocalWorkoutLog
                        >(
                          currentTable: table,
                          referencedTable: $$LocalTrainingDaysTableReferences
                              ._localWorkoutLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalTrainingDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalTrainingDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalTrainingDaysTable,
      LocalTrainingDay,
      $$LocalTrainingDaysTableFilterComposer,
      $$LocalTrainingDaysTableOrderingComposer,
      $$LocalTrainingDaysTableAnnotationComposer,
      $$LocalTrainingDaysTableCreateCompanionBuilder,
      $$LocalTrainingDaysTableUpdateCompanionBuilder,
      (LocalTrainingDay, $$LocalTrainingDaysTableReferences),
      LocalTrainingDay,
      PrefetchHooks Function({
        bool routineId,
        bool localSlotsRefs,
        bool localWorkoutSessionsRefs,
        bool localWorkoutLogsRefs,
      })
    >;
typedef $$LocalSlotsTableCreateCompanionBuilder =
    LocalSlotsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required int dayId,
      required int order,
      Value<String> syncStatus,
    });
typedef $$LocalSlotsTableUpdateCompanionBuilder =
    LocalSlotsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<int> dayId,
      Value<int> order,
      Value<String> syncStatus,
    });

final class $$LocalSlotsTableReferences
    extends
        BaseReferences<_$LocalTrainingDatabase, $LocalSlotsTable, LocalSlot> {
  $$LocalSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalTrainingDaysTable _dayIdTable(_$LocalTrainingDatabase db) =>
      db.localTrainingDays.createAlias(
        $_aliasNameGenerator(db.localSlots.dayId, db.localTrainingDays.id),
      );

  $$LocalTrainingDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$LocalTrainingDaysTableTableManager(
      $_db,
      $_db.localTrainingDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LocalSlotEntriesTable, List<LocalSlotEntry>>
  _localSlotEntriesRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localSlotEntries,
        aliasName: $_aliasNameGenerator(
          db.localSlots.id,
          db.localSlotEntries.slotId,
        ),
      );

  $$LocalSlotEntriesTableProcessedTableManager get localSlotEntriesRefs {
    final manager = $$LocalSlotEntriesTableTableManager(
      $_db,
      $_db.localSlotEntries,
    ).filter((f) => f.slotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localSlotEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalSlotsTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotsTable> {
  $$LocalSlotsTableFilterComposer({
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

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalTrainingDaysTableFilterComposer get dayId {
    final $$LocalTrainingDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableFilterComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> localSlotEntriesRefs(
    Expression<bool> Function($$LocalSlotEntriesTableFilterComposer f) f,
  ) {
    final $$LocalSlotEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSlotEntries,
      getReferencedColumn: (t) => t.slotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotEntriesTableFilterComposer(
            $db: $db,
            $table: $db.localSlotEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSlotsTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotsTable> {
  $$LocalSlotsTableOrderingComposer({
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

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalTrainingDaysTableOrderingComposer get dayId {
    final $$LocalTrainingDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableOrderingComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSlotsTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotsTable> {
  $$LocalSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$LocalTrainingDaysTableAnnotationComposer get dayId {
    final $$LocalTrainingDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.dayId,
          referencedTable: $db.localTrainingDays,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalTrainingDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.localTrainingDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> localSlotEntriesRefs<T extends Object>(
    Expression<T> Function($$LocalSlotEntriesTableAnnotationComposer a) f,
  ) {
    final $$LocalSlotEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSlotEntries,
      getReferencedColumn: (t) => t.slotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.localSlotEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSlotsTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalSlotsTable,
          LocalSlot,
          $$LocalSlotsTableFilterComposer,
          $$LocalSlotsTableOrderingComposer,
          $$LocalSlotsTableAnnotationComposer,
          $$LocalSlotsTableCreateCompanionBuilder,
          $$LocalSlotsTableUpdateCompanionBuilder,
          (LocalSlot, $$LocalSlotsTableReferences),
          LocalSlot,
          PrefetchHooks Function({bool dayId, bool localSlotEntriesRefs})
        > {
  $$LocalSlotsTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalSlotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => LocalSlotsCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                dayId: dayId,
                order: order,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int dayId,
                required int order,
                Value<String> syncStatus = const Value.absent(),
              }) => LocalSlotsCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                dayId: dayId,
                order: order,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({dayId = false, localSlotEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localSlotEntriesRefs) db.localSlotEntries,
                  ],
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
                        if (dayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayId,
                                    referencedTable: $$LocalSlotsTableReferences
                                        ._dayIdTable(db),
                                    referencedColumn:
                                        $$LocalSlotsTableReferences
                                            ._dayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localSlotEntriesRefs)
                        await $_getPrefetchedData<
                          LocalSlot,
                          $LocalSlotsTable,
                          LocalSlotEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LocalSlotsTableReferences
                              ._localSlotEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalSlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).localSlotEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.slotId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalSlotsTable,
      LocalSlot,
      $$LocalSlotsTableFilterComposer,
      $$LocalSlotsTableOrderingComposer,
      $$LocalSlotsTableAnnotationComposer,
      $$LocalSlotsTableCreateCompanionBuilder,
      $$LocalSlotsTableUpdateCompanionBuilder,
      (LocalSlot, $$LocalSlotsTableReferences),
      LocalSlot,
      PrefetchHooks Function({bool dayId, bool localSlotEntriesRefs})
    >;
typedef $$LocalSlotEntriesTableCreateCompanionBuilder =
    LocalSlotEntriesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required int slotId,
      required String exerciseName,
      Value<int?> exerciseId,
      Value<int> targetSets,
      Value<int?> targetReps,
      Value<double?> targetWeight,
      Value<String> recordMode,
      Value<String> syncStatus,
    });
typedef $$LocalSlotEntriesTableUpdateCompanionBuilder =
    LocalSlotEntriesCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<int> slotId,
      Value<String> exerciseName,
      Value<int?> exerciseId,
      Value<int> targetSets,
      Value<int?> targetReps,
      Value<double?> targetWeight,
      Value<String> recordMode,
      Value<String> syncStatus,
    });

final class $$LocalSlotEntriesTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalSlotEntriesTable,
          LocalSlotEntry
        > {
  $$LocalSlotEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalSlotsTable _slotIdTable(_$LocalTrainingDatabase db) =>
      db.localSlots.createAlias(
        $_aliasNameGenerator(db.localSlotEntries.slotId, db.localSlots.id),
      );

  $$LocalSlotsTableProcessedTableManager get slotId {
    final $_column = $_itemColumn<int>('slot_id')!;

    final manager = $$LocalSlotsTableTableManager(
      $_db,
      $_db.localSlots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_slotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalSlotEntriesTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotEntriesTable> {
  $$LocalSlotEntriesTableFilterComposer({
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

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalSlotsTableFilterComposer get slotId {
    final $$LocalSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.localSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotsTableFilterComposer(
            $db: $db,
            $table: $db.localSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSlotEntriesTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotEntriesTable> {
  $$LocalSlotEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalSlotsTableOrderingComposer get slotId {
    final $$LocalSlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.localSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotsTableOrderingComposer(
            $db: $db,
            $table: $db.localSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSlotEntriesTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSlotEntriesTable> {
  $$LocalSlotEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$LocalSlotsTableAnnotationComposer get slotId {
    final $$LocalSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.localSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.localSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSlotEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalSlotEntriesTable,
          LocalSlotEntry,
          $$LocalSlotEntriesTableFilterComposer,
          $$LocalSlotEntriesTableOrderingComposer,
          $$LocalSlotEntriesTableAnnotationComposer,
          $$LocalSlotEntriesTableCreateCompanionBuilder,
          $$LocalSlotEntriesTableUpdateCompanionBuilder,
          (LocalSlotEntry, $$LocalSlotEntriesTableReferences),
          LocalSlotEntry,
          PrefetchHooks Function({bool slotId})
        > {
  $$LocalSlotEntriesTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalSlotEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSlotEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSlotEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSlotEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> slotId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int?> exerciseId = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<double?> targetWeight = const Value.absent(),
                Value<String> recordMode = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => LocalSlotEntriesCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                slotId: slotId,
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeight: targetWeight,
                recordMode: recordMode,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int slotId,
                required String exerciseName,
                Value<int?> exerciseId = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<double?> targetWeight = const Value.absent(),
                Value<String> recordMode = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => LocalSlotEntriesCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                slotId: slotId,
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                targetSets: targetSets,
                targetReps: targetReps,
                targetWeight: targetWeight,
                recordMode: recordMode,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalSlotEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({slotId = false}) {
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
                    if (slotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.slotId,
                                referencedTable:
                                    $$LocalSlotEntriesTableReferences
                                        ._slotIdTable(db),
                                referencedColumn:
                                    $$LocalSlotEntriesTableReferences
                                        ._slotIdTable(db)
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

typedef $$LocalSlotEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalSlotEntriesTable,
      LocalSlotEntry,
      $$LocalSlotEntriesTableFilterComposer,
      $$LocalSlotEntriesTableOrderingComposer,
      $$LocalSlotEntriesTableAnnotationComposer,
      $$LocalSlotEntriesTableCreateCompanionBuilder,
      $$LocalSlotEntriesTableUpdateCompanionBuilder,
      (LocalSlotEntry, $$LocalSlotEntriesTableReferences),
      LocalSlotEntry,
      PrefetchHooks Function({bool slotId})
    >;
typedef $$LocalWorkoutSessionsTableCreateCompanionBuilder =
    LocalWorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required int routineId,
      Value<int?> dayId,
      Value<String> routineNameSnapshot,
      Value<String> routineSyncIdSnapshot,
      Value<String> dayNameSnapshot,
      Value<int?> dayWeekSnapshot,
      Value<int?> dayIndexSnapshot,
      Value<String> daySyncIdSnapshot,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String> note,
      Value<String> syncStatus,
      required DateTime updatedAt,
    });
typedef $$LocalWorkoutSessionsTableUpdateCompanionBuilder =
    LocalWorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<int> routineId,
      Value<int?> dayId,
      Value<String> routineNameSnapshot,
      Value<String> routineSyncIdSnapshot,
      Value<String> dayNameSnapshot,
      Value<int?> dayWeekSnapshot,
      Value<int?> dayIndexSnapshot,
      Value<String> daySyncIdSnapshot,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> note,
      Value<String> syncStatus,
      Value<DateTime> updatedAt,
    });

final class $$LocalWorkoutSessionsTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalWorkoutSessionsTable,
          LocalWorkoutSession
        > {
  $$LocalWorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalRoutinesTable _routineIdTable(_$LocalTrainingDatabase db) =>
      db.localRoutines.createAlias(
        $_aliasNameGenerator(
          db.localWorkoutSessions.routineId,
          db.localRoutines.id,
        ),
      );

  $$LocalRoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$LocalRoutinesTableTableManager(
      $_db,
      $_db.localRoutines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LocalTrainingDaysTable _dayIdTable(_$LocalTrainingDatabase db) =>
      db.localTrainingDays.createAlias(
        $_aliasNameGenerator(
          db.localWorkoutSessions.dayId,
          db.localTrainingDays.id,
        ),
      );

  $$LocalTrainingDaysTableProcessedTableManager? get dayId {
    final $_column = $_itemColumn<int>('day_id');
    if ($_column == null) return null;
    final manager = $$LocalTrainingDaysTableTableManager(
      $_db,
      $_db.localTrainingDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LocalWorkoutLogsTable, List<LocalWorkoutLog>>
  _localWorkoutLogsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutLogs,
        aliasName: $_aliasNameGenerator(
          db.localWorkoutSessions.id,
          db.localWorkoutLogs.sessionId,
        ),
      );

  $$LocalWorkoutLogsTableProcessedTableManager get localWorkoutLogsRefs {
    final manager = $$LocalWorkoutLogsTableTableManager(
      $_db,
      $_db.localWorkoutLogs,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalWorkoutSetDraftsTable,
    List<LocalWorkoutSetDraft>
  >
  _localWorkoutSetDraftsRefsTable(_$LocalTrainingDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localWorkoutSetDrafts,
        aliasName: $_aliasNameGenerator(
          db.localWorkoutSessions.id,
          db.localWorkoutSetDrafts.sessionId,
        ),
      );

  $$LocalWorkoutSetDraftsTableProcessedTableManager
  get localWorkoutSetDraftsRefs {
    final manager = $$LocalWorkoutSetDraftsTableTableManager(
      $_db,
      $_db.localWorkoutSetDrafts,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localWorkoutSetDraftsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalWorkoutSessionsTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableFilterComposer({
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

  ColumnFilters<String> get routineNameSnapshot => $composableBuilder(
    column: $table.routineNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineSyncIdSnapshot => $composableBuilder(
    column: $table.routineSyncIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayNameSnapshot => $composableBuilder(
    column: $table.dayNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayWeekSnapshot => $composableBuilder(
    column: $table.dayWeekSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndexSnapshot => $composableBuilder(
    column: $table.dayIndexSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daySyncIdSnapshot => $composableBuilder(
    column: $table.daySyncIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalRoutinesTableFilterComposer get routineId {
    final $$LocalRoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableFilterComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableFilterComposer get dayId {
    final $$LocalTrainingDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableFilterComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> localWorkoutLogsRefs(
    Expression<bool> Function($$LocalWorkoutLogsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localWorkoutSetDraftsRefs(
    Expression<bool> Function($$LocalWorkoutSetDraftsTableFilterComposer f) f,
  ) {
    final $$LocalWorkoutSetDraftsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localWorkoutSetDrafts,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSetDraftsTableFilterComposer(
                $db: $db,
                $table: $db.localWorkoutSetDrafts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalWorkoutSessionsTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get routineNameSnapshot => $composableBuilder(
    column: $table.routineNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineSyncIdSnapshot => $composableBuilder(
    column: $table.routineSyncIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayNameSnapshot => $composableBuilder(
    column: $table.dayNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayWeekSnapshot => $composableBuilder(
    column: $table.dayWeekSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndexSnapshot => $composableBuilder(
    column: $table.dayIndexSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daySyncIdSnapshot => $composableBuilder(
    column: $table.daySyncIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalRoutinesTableOrderingComposer get routineId {
    final $$LocalRoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableOrderingComposer get dayId {
    final $$LocalTrainingDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableOrderingComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalWorkoutSessionsTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSessionsTable> {
  $$LocalWorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get routineNameSnapshot => $composableBuilder(
    column: $table.routineNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routineSyncIdSnapshot => $composableBuilder(
    column: $table.routineSyncIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dayNameSnapshot => $composableBuilder(
    column: $table.dayNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayWeekSnapshot => $composableBuilder(
    column: $table.dayWeekSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayIndexSnapshot => $composableBuilder(
    column: $table.dayIndexSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daySyncIdSnapshot => $composableBuilder(
    column: $table.daySyncIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalRoutinesTableAnnotationComposer get routineId {
    final $$LocalRoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableAnnotationComposer get dayId {
    final $$LocalTrainingDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.dayId,
          referencedTable: $db.localTrainingDays,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalTrainingDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.localTrainingDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> localWorkoutLogsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutLogsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localWorkoutLogs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.localWorkoutLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localWorkoutSetDraftsRefs<T extends Object>(
    Expression<T> Function($$LocalWorkoutSetDraftsTableAnnotationComposer a) f,
  ) {
    final $$LocalWorkoutSetDraftsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localWorkoutSetDrafts,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSetDraftsTableAnnotationComposer(
                $db: $db,
                $table: $db.localWorkoutSetDrafts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalWorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalWorkoutSessionsTable,
          LocalWorkoutSession,
          $$LocalWorkoutSessionsTableFilterComposer,
          $$LocalWorkoutSessionsTableOrderingComposer,
          $$LocalWorkoutSessionsTableAnnotationComposer,
          $$LocalWorkoutSessionsTableCreateCompanionBuilder,
          $$LocalWorkoutSessionsTableUpdateCompanionBuilder,
          (LocalWorkoutSession, $$LocalWorkoutSessionsTableReferences),
          LocalWorkoutSession,
          PrefetchHooks Function({
            bool routineId,
            bool dayId,
            bool localWorkoutLogsRefs,
            bool localWorkoutSetDraftsRefs,
          })
        > {
  $$LocalWorkoutSessionsTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalWorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int?> dayId = const Value.absent(),
                Value<String> routineNameSnapshot = const Value.absent(),
                Value<String> routineSyncIdSnapshot = const Value.absent(),
                Value<String> dayNameSnapshot = const Value.absent(),
                Value<int?> dayWeekSnapshot = const Value.absent(),
                Value<int?> dayIndexSnapshot = const Value.absent(),
                Value<String> daySyncIdSnapshot = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalWorkoutSessionsCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                routineId: routineId,
                dayId: dayId,
                routineNameSnapshot: routineNameSnapshot,
                routineSyncIdSnapshot: routineSyncIdSnapshot,
                dayNameSnapshot: dayNameSnapshot,
                dayWeekSnapshot: dayWeekSnapshot,
                dayIndexSnapshot: dayIndexSnapshot,
                daySyncIdSnapshot: daySyncIdSnapshot,
                startedAt: startedAt,
                endedAt: endedAt,
                note: note,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int routineId,
                Value<int?> dayId = const Value.absent(),
                Value<String> routineNameSnapshot = const Value.absent(),
                Value<String> routineSyncIdSnapshot = const Value.absent(),
                Value<String> dayNameSnapshot = const Value.absent(),
                Value<int?> dayWeekSnapshot = const Value.absent(),
                Value<int?> dayIndexSnapshot = const Value.absent(),
                Value<String> daySyncIdSnapshot = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalWorkoutSessionsCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                routineId: routineId,
                dayId: dayId,
                routineNameSnapshot: routineNameSnapshot,
                routineSyncIdSnapshot: routineSyncIdSnapshot,
                dayNameSnapshot: dayNameSnapshot,
                dayWeekSnapshot: dayWeekSnapshot,
                dayIndexSnapshot: dayIndexSnapshot,
                daySyncIdSnapshot: daySyncIdSnapshot,
                startedAt: startedAt,
                endedAt: endedAt,
                note: note,
                syncStatus: syncStatus,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalWorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                routineId = false,
                dayId = false,
                localWorkoutLogsRefs = false,
                localWorkoutSetDraftsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localWorkoutLogsRefs) db.localWorkoutLogs,
                    if (localWorkoutSetDraftsRefs) db.localWorkoutSetDrafts,
                  ],
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
                        if (routineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routineId,
                                    referencedTable:
                                        $$LocalWorkoutSessionsTableReferences
                                            ._routineIdTable(db),
                                    referencedColumn:
                                        $$LocalWorkoutSessionsTableReferences
                                            ._routineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (dayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayId,
                                    referencedTable:
                                        $$LocalWorkoutSessionsTableReferences
                                            ._dayIdTable(db),
                                    referencedColumn:
                                        $$LocalWorkoutSessionsTableReferences
                                            ._dayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localWorkoutLogsRefs)
                        await $_getPrefetchedData<
                          LocalWorkoutSession,
                          $LocalWorkoutSessionsTable,
                          LocalWorkoutLog
                        >(
                          currentTable: table,
                          referencedTable: $$LocalWorkoutSessionsTableReferences
                              ._localWorkoutLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalWorkoutSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localWorkoutSetDraftsRefs)
                        await $_getPrefetchedData<
                          LocalWorkoutSession,
                          $LocalWorkoutSessionsTable,
                          LocalWorkoutSetDraft
                        >(
                          currentTable: table,
                          referencedTable: $$LocalWorkoutSessionsTableReferences
                              ._localWorkoutSetDraftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalWorkoutSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).localWorkoutSetDraftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalWorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalWorkoutSessionsTable,
      LocalWorkoutSession,
      $$LocalWorkoutSessionsTableFilterComposer,
      $$LocalWorkoutSessionsTableOrderingComposer,
      $$LocalWorkoutSessionsTableAnnotationComposer,
      $$LocalWorkoutSessionsTableCreateCompanionBuilder,
      $$LocalWorkoutSessionsTableUpdateCompanionBuilder,
      (LocalWorkoutSession, $$LocalWorkoutSessionsTableReferences),
      LocalWorkoutSession,
      PrefetchHooks Function({
        bool routineId,
        bool dayId,
        bool localWorkoutLogsRefs,
        bool localWorkoutSetDraftsRefs,
      })
    >;
typedef $$LocalWorkoutLogsTableCreateCompanionBuilder =
    LocalWorkoutLogsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      required int sessionId,
      required int routineId,
      Value<int?> dayId,
      required String exerciseName,
      required int setIndex,
      Value<double> weight,
      Value<int> reps,
      Value<double?> rir,
      Value<int> durationSeconds,
      Value<double?> actualWeight,
      Value<int?> actualReps,
      Value<int?> actualDurationSeconds,
      Value<int?> restSeconds,
      Value<bool> hasActualValues,
      Value<String> recordMode,
      Value<String> note,
      Value<String> syncStatus,
      required DateTime createdAt,
    });
typedef $$LocalWorkoutLogsTableUpdateCompanionBuilder =
    LocalWorkoutLogsCompanion Function({
      Value<int> id,
      Value<String> syncId,
      Value<int?> remoteId,
      Value<int> sessionId,
      Value<int> routineId,
      Value<int?> dayId,
      Value<String> exerciseName,
      Value<int> setIndex,
      Value<double> weight,
      Value<int> reps,
      Value<double?> rir,
      Value<int> durationSeconds,
      Value<double?> actualWeight,
      Value<int?> actualReps,
      Value<int?> actualDurationSeconds,
      Value<int?> restSeconds,
      Value<bool> hasActualValues,
      Value<String> recordMode,
      Value<String> note,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
    });

final class $$LocalWorkoutLogsTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalWorkoutLogsTable,
          LocalWorkoutLog
        > {
  $$LocalWorkoutLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalWorkoutSessionsTable _sessionIdTable(
    _$LocalTrainingDatabase db,
  ) => db.localWorkoutSessions.createAlias(
    $_aliasNameGenerator(
      db.localWorkoutLogs.sessionId,
      db.localWorkoutSessions.id,
    ),
  );

  $$LocalWorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$LocalWorkoutSessionsTableTableManager(
      $_db,
      $_db.localWorkoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LocalRoutinesTable _routineIdTable(_$LocalTrainingDatabase db) =>
      db.localRoutines.createAlias(
        $_aliasNameGenerator(
          db.localWorkoutLogs.routineId,
          db.localRoutines.id,
        ),
      );

  $$LocalRoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$LocalRoutinesTableTableManager(
      $_db,
      $_db.localRoutines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LocalTrainingDaysTable _dayIdTable(_$LocalTrainingDatabase db) =>
      db.localTrainingDays.createAlias(
        $_aliasNameGenerator(
          db.localWorkoutLogs.dayId,
          db.localTrainingDays.id,
        ),
      );

  $$LocalTrainingDaysTableProcessedTableManager? get dayId {
    final $_column = $_itemColumn<int>('day_id');
    if ($_column == null) return null;
    final manager = $$LocalTrainingDaysTableTableManager(
      $_db,
      $_db.localTrainingDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalWorkoutLogsTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutLogsTable> {
  $$LocalWorkoutLogsTableFilterComposer({
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

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasActualValues => $composableBuilder(
    column: $table.hasActualValues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutSessionsTableFilterComposer get sessionId {
    final $$LocalWorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.localWorkoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalRoutinesTableFilterComposer get routineId {
    final $$LocalRoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableFilterComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableFilterComposer get dayId {
    final $$LocalTrainingDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableFilterComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalWorkoutLogsTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutLogsTable> {
  $$LocalWorkoutLogsTableOrderingComposer({
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

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasActualValues => $composableBuilder(
    column: $table.hasActualValues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutSessionsTableOrderingComposer get sessionId {
    final $$LocalWorkoutSessionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableOrderingComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LocalRoutinesTableOrderingComposer get routineId {
    final $$LocalRoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableOrderingComposer get dayId {
    final $$LocalTrainingDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.localTrainingDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrainingDaysTableOrderingComposer(
            $db: $db,
            $table: $db.localTrainingDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalWorkoutLogsTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutLogsTable> {
  $$LocalWorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDurationSeconds => $composableBuilder(
    column: $table.actualDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasActualValues => $composableBuilder(
    column: $table.hasActualValues,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordMode => $composableBuilder(
    column: $table.recordMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalWorkoutSessionsTableAnnotationComposer get sessionId {
    final $$LocalWorkoutSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LocalRoutinesTableAnnotationComposer get routineId {
    final $$LocalRoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.localRoutines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalRoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.localRoutines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LocalTrainingDaysTableAnnotationComposer get dayId {
    final $$LocalTrainingDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.dayId,
          referencedTable: $db.localTrainingDays,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalTrainingDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.localTrainingDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalWorkoutLogsTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalWorkoutLogsTable,
          LocalWorkoutLog,
          $$LocalWorkoutLogsTableFilterComposer,
          $$LocalWorkoutLogsTableOrderingComposer,
          $$LocalWorkoutLogsTableAnnotationComposer,
          $$LocalWorkoutLogsTableCreateCompanionBuilder,
          $$LocalWorkoutLogsTableUpdateCompanionBuilder,
          (LocalWorkoutLog, $$LocalWorkoutLogsTableReferences),
          LocalWorkoutLog,
          PrefetchHooks Function({bool sessionId, bool routineId, bool dayId})
        > {
  $$LocalWorkoutLogsTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalWorkoutLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWorkoutLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int?> dayId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double?> actualWeight = const Value.absent(),
                Value<int?> actualReps = const Value.absent(),
                Value<int?> actualDurationSeconds = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> hasActualValues = const Value.absent(),
                Value<String> recordMode = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalWorkoutLogsCompanion(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                sessionId: sessionId,
                routineId: routineId,
                dayId: dayId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                weight: weight,
                reps: reps,
                rir: rir,
                durationSeconds: durationSeconds,
                actualWeight: actualWeight,
                actualReps: actualReps,
                actualDurationSeconds: actualDurationSeconds,
                restSeconds: restSeconds,
                hasActualValues: hasActualValues,
                recordMode: recordMode,
                note: note,
                syncStatus: syncStatus,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                required int sessionId,
                required int routineId,
                Value<int?> dayId = const Value.absent(),
                required String exerciseName,
                required int setIndex,
                Value<double> weight = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double?> rir = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double?> actualWeight = const Value.absent(),
                Value<int?> actualReps = const Value.absent(),
                Value<int?> actualDurationSeconds = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> hasActualValues = const Value.absent(),
                Value<String> recordMode = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime createdAt,
              }) => LocalWorkoutLogsCompanion.insert(
                id: id,
                syncId: syncId,
                remoteId: remoteId,
                sessionId: sessionId,
                routineId: routineId,
                dayId: dayId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                weight: weight,
                reps: reps,
                rir: rir,
                durationSeconds: durationSeconds,
                actualWeight: actualWeight,
                actualReps: actualReps,
                actualDurationSeconds: actualDurationSeconds,
                restSeconds: restSeconds,
                hasActualValues: hasActualValues,
                recordMode: recordMode,
                note: note,
                syncStatus: syncStatus,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalWorkoutLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, routineId = false, dayId = false}) {
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
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$LocalWorkoutLogsTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$LocalWorkoutLogsTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (routineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routineId,
                                    referencedTable:
                                        $$LocalWorkoutLogsTableReferences
                                            ._routineIdTable(db),
                                    referencedColumn:
                                        $$LocalWorkoutLogsTableReferences
                                            ._routineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (dayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayId,
                                    referencedTable:
                                        $$LocalWorkoutLogsTableReferences
                                            ._dayIdTable(db),
                                    referencedColumn:
                                        $$LocalWorkoutLogsTableReferences
                                            ._dayIdTable(db)
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

typedef $$LocalWorkoutLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalWorkoutLogsTable,
      LocalWorkoutLog,
      $$LocalWorkoutLogsTableFilterComposer,
      $$LocalWorkoutLogsTableOrderingComposer,
      $$LocalWorkoutLogsTableAnnotationComposer,
      $$LocalWorkoutLogsTableCreateCompanionBuilder,
      $$LocalWorkoutLogsTableUpdateCompanionBuilder,
      (LocalWorkoutLog, $$LocalWorkoutLogsTableReferences),
      LocalWorkoutLog,
      PrefetchHooks Function({bool sessionId, bool routineId, bool dayId})
    >;
typedef $$LocalWorkoutSetDraftsTableCreateCompanionBuilder =
    LocalWorkoutSetDraftsCompanion Function({
      Value<int> id,
      required int sessionId,
      required int actionIndex,
      required int setIndex,
      Value<String> weightText,
      Value<String> repsText,
      Value<String> durationText,
      Value<String> restText,
      Value<String> noteText,
      required DateTime updatedAt,
    });
typedef $$LocalWorkoutSetDraftsTableUpdateCompanionBuilder =
    LocalWorkoutSetDraftsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> actionIndex,
      Value<int> setIndex,
      Value<String> weightText,
      Value<String> repsText,
      Value<String> durationText,
      Value<String> restText,
      Value<String> noteText,
      Value<DateTime> updatedAt,
    });

final class $$LocalWorkoutSetDraftsTableReferences
    extends
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalWorkoutSetDraftsTable,
          LocalWorkoutSetDraft
        > {
  $$LocalWorkoutSetDraftsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalWorkoutSessionsTable _sessionIdTable(
    _$LocalTrainingDatabase db,
  ) => db.localWorkoutSessions.createAlias(
    $_aliasNameGenerator(
      db.localWorkoutSetDrafts.sessionId,
      db.localWorkoutSessions.id,
    ),
  );

  $$LocalWorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$LocalWorkoutSessionsTableTableManager(
      $_db,
      $_db.localWorkoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalWorkoutSetDraftsTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSetDraftsTable> {
  $$LocalWorkoutSetDraftsTableFilterComposer({
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

  ColumnFilters<int> get actionIndex => $composableBuilder(
    column: $table.actionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightText => $composableBuilder(
    column: $table.weightText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repsText => $composableBuilder(
    column: $table.repsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durationText => $composableBuilder(
    column: $table.durationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get restText => $composableBuilder(
    column: $table.restText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalWorkoutSessionsTableFilterComposer get sessionId {
    final $$LocalWorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.localWorkoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalWorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.localWorkoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalWorkoutSetDraftsTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSetDraftsTable> {
  $$LocalWorkoutSetDraftsTableOrderingComposer({
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

  ColumnOrderings<int> get actionIndex => $composableBuilder(
    column: $table.actionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightText => $composableBuilder(
    column: $table.weightText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repsText => $composableBuilder(
    column: $table.repsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationText => $composableBuilder(
    column: $table.durationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get restText => $composableBuilder(
    column: $table.restText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteText => $composableBuilder(
    column: $table.noteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalWorkoutSessionsTableOrderingComposer get sessionId {
    final $$LocalWorkoutSessionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableOrderingComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalWorkoutSetDraftsTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalWorkoutSetDraftsTable> {
  $$LocalWorkoutSetDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get actionIndex => $composableBuilder(
    column: $table.actionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<String> get weightText => $composableBuilder(
    column: $table.weightText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repsText =>
      $composableBuilder(column: $table.repsText, builder: (column) => column);

  GeneratedColumn<String> get durationText => $composableBuilder(
    column: $table.durationText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get restText =>
      $composableBuilder(column: $table.restText, builder: (column) => column);

  GeneratedColumn<String> get noteText =>
      $composableBuilder(column: $table.noteText, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalWorkoutSessionsTableAnnotationComposer get sessionId {
    final $$LocalWorkoutSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.localWorkoutSessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalWorkoutSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localWorkoutSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalWorkoutSetDraftsTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalWorkoutSetDraftsTable,
          LocalWorkoutSetDraft,
          $$LocalWorkoutSetDraftsTableFilterComposer,
          $$LocalWorkoutSetDraftsTableOrderingComposer,
          $$LocalWorkoutSetDraftsTableAnnotationComposer,
          $$LocalWorkoutSetDraftsTableCreateCompanionBuilder,
          $$LocalWorkoutSetDraftsTableUpdateCompanionBuilder,
          (LocalWorkoutSetDraft, $$LocalWorkoutSetDraftsTableReferences),
          LocalWorkoutSetDraft,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LocalWorkoutSetDraftsTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalWorkoutSetDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutSetDraftsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalWorkoutSetDraftsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalWorkoutSetDraftsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> actionIndex = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<String> weightText = const Value.absent(),
                Value<String> repsText = const Value.absent(),
                Value<String> durationText = const Value.absent(),
                Value<String> restText = const Value.absent(),
                Value<String> noteText = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalWorkoutSetDraftsCompanion(
                id: id,
                sessionId: sessionId,
                actionIndex: actionIndex,
                setIndex: setIndex,
                weightText: weightText,
                repsText: repsText,
                durationText: durationText,
                restText: restText,
                noteText: noteText,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int actionIndex,
                required int setIndex,
                Value<String> weightText = const Value.absent(),
                Value<String> repsText = const Value.absent(),
                Value<String> durationText = const Value.absent(),
                Value<String> restText = const Value.absent(),
                Value<String> noteText = const Value.absent(),
                required DateTime updatedAt,
              }) => LocalWorkoutSetDraftsCompanion.insert(
                id: id,
                sessionId: sessionId,
                actionIndex: actionIndex,
                setIndex: setIndex,
                weightText: weightText,
                repsText: repsText,
                durationText: durationText,
                restText: restText,
                noteText: noteText,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalWorkoutSetDraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$LocalWorkoutSetDraftsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$LocalWorkoutSetDraftsTableReferences
                                        ._sessionIdTable(db)
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

typedef $$LocalWorkoutSetDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalWorkoutSetDraftsTable,
      LocalWorkoutSetDraft,
      $$LocalWorkoutSetDraftsTableFilterComposer,
      $$LocalWorkoutSetDraftsTableOrderingComposer,
      $$LocalWorkoutSetDraftsTableAnnotationComposer,
      $$LocalWorkoutSetDraftsTableCreateCompanionBuilder,
      $$LocalWorkoutSetDraftsTableUpdateCompanionBuilder,
      (LocalWorkoutSetDraft, $$LocalWorkoutSetDraftsTableReferences),
      LocalWorkoutSetDraft,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$LocalSyncQueueTableCreateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> deviceId,
      required String entityType,
      required int entityId,
      Value<String> entitySyncId,
      required String action,
      Value<String> payload,
      Value<String> status,
      Value<int?> serverSeq,
      Value<int> attempts,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$LocalSyncQueueTableUpdateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> deviceId,
      Value<String> entityType,
      Value<int> entityId,
      Value<String> entitySyncId,
      Value<String> action,
      Value<String> payload,
      Value<String> status,
      Value<int?> serverSeq,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$LocalSyncQueueTableFilterComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
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
}

class $$LocalSyncQueueTableOrderingComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
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

class $$LocalSyncQueueTableAnnotationComposer
    extends Composer<_$LocalTrainingDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSyncQueueTableTableManager
    extends
        RootTableManager<
          _$LocalTrainingDatabase,
          $LocalSyncQueueTable,
          LocalSyncQueueData,
          $$LocalSyncQueueTableFilterComposer,
          $$LocalSyncQueueTableOrderingComposer,
          $$LocalSyncQueueTableAnnotationComposer,
          $$LocalSyncQueueTableCreateCompanionBuilder,
          $$LocalSyncQueueTableUpdateCompanionBuilder,
          (
            LocalSyncQueueData,
            BaseReferences<
              _$LocalTrainingDatabase,
              $LocalSyncQueueTable,
              LocalSyncQueueData
            >,
          ),
          LocalSyncQueueData,
          PrefetchHooks Function()
        > {
  $$LocalSyncQueueTableTableManager(
    _$LocalTrainingDatabase db,
    $LocalSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<String> entitySyncId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalSyncQueueCompanion(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                entityType: entityType,
                entityId: entityId,
                entitySyncId: entitySyncId,
                action: action,
                payload: payload,
                status: status,
                serverSeq: serverSeq,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                required String entityType,
                required int entityId,
                Value<String> entitySyncId = const Value.absent(),
                required String action,
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => LocalSyncQueueCompanion.insert(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                entityType: entityType,
                entityId: entityId,
                entitySyncId: entitySyncId,
                action: action,
                payload: payload,
                status: status,
                serverSeq: serverSeq,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTrainingDatabase,
      $LocalSyncQueueTable,
      LocalSyncQueueData,
      $$LocalSyncQueueTableFilterComposer,
      $$LocalSyncQueueTableOrderingComposer,
      $$LocalSyncQueueTableAnnotationComposer,
      $$LocalSyncQueueTableCreateCompanionBuilder,
      $$LocalSyncQueueTableUpdateCompanionBuilder,
      (
        LocalSyncQueueData,
        BaseReferences<
          _$LocalTrainingDatabase,
          $LocalSyncQueueTable,
          LocalSyncQueueData
        >,
      ),
      LocalSyncQueueData,
      PrefetchHooks Function()
    >;

class $LocalTrainingDatabaseManager {
  final _$LocalTrainingDatabase _db;
  $LocalTrainingDatabaseManager(this._db);
  $$LocalRoutinesTableTableManager get localRoutines =>
      $$LocalRoutinesTableTableManager(_db, _db.localRoutines);
  $$LocalTrainingDaysTableTableManager get localTrainingDays =>
      $$LocalTrainingDaysTableTableManager(_db, _db.localTrainingDays);
  $$LocalSlotsTableTableManager get localSlots =>
      $$LocalSlotsTableTableManager(_db, _db.localSlots);
  $$LocalSlotEntriesTableTableManager get localSlotEntries =>
      $$LocalSlotEntriesTableTableManager(_db, _db.localSlotEntries);
  $$LocalWorkoutSessionsTableTableManager get localWorkoutSessions =>
      $$LocalWorkoutSessionsTableTableManager(_db, _db.localWorkoutSessions);
  $$LocalWorkoutLogsTableTableManager get localWorkoutLogs =>
      $$LocalWorkoutLogsTableTableManager(_db, _db.localWorkoutLogs);
  $$LocalWorkoutSetDraftsTableTableManager get localWorkoutSetDrafts =>
      $$LocalWorkoutSetDraftsTableTableManager(_db, _db.localWorkoutSetDrafts);
  $$LocalSyncQueueTableTableManager get localSyncQueue =>
      $$LocalSyncQueueTableTableManager(_db, _db.localSyncQueue);
}

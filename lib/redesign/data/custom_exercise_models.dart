import 'dart:convert';

import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/sync_identity.dart';

class CustomExerciseModel {
  final int? id;
  final String syncId;
  final int? remoteId;
  final String chineseName;
  final String englishName;
  final String bodyPart;
  final String equipment;
  final String primaryMuscles;
  final String description;
  final List<String> imagePaths;
  final bool isCustom;
  final String syncStatus;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomExerciseModel({
    this.id,
    String? syncId,
    this.remoteId,
    required this.chineseName,
    this.englishName = '',
    required this.bodyPart,
    required this.equipment,
    required this.primaryMuscles,
    required this.description,
    List<String>? imagePaths,
    this.isCustom = true,
    this.syncStatus = localSyncPending,
    this.deleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : syncId = syncId ?? SyncId.newId(),
       imagePaths = imagePaths ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get displayName => chineseName;

  String? get builtInKey {
    final reference = builtInExerciseReferenceForRemoteId(remoteId);
    return reference == null ? null : builtInExerciseKeyForReference(reference);
  }

  String get exerciseReference => builtInExerciseReferenceForRemoteId(remoteId) ?? displayName;

  String get abbr {
    final source = chineseName.trim().isNotEmpty ? chineseName.trim() : bodyPart.trim();
    return source.isEmpty ? '动' : source.substring(0, 1);
  }

  String get searchableText => [
    chineseName,
    englishName,
    bodyPart,
    equipment,
    primaryMuscles,
    description,
  ].join(' ').toLowerCase();

  String get imagePathsJson => jsonEncode(imagePaths);

  CustomExerciseModel copyWith({
    int? id,
    String? syncId,
    int? remoteId,
    String? chineseName,
    String? englishName,
    String? bodyPart,
    String? equipment,
    String? primaryMuscles,
    String? description,
    List<String>? imagePaths,
    bool? isCustom,
    String? syncStatus,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomExerciseModel(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      remoteId: remoteId ?? this.remoteId,
      chineseName: chineseName ?? this.chineseName,
      englishName: englishName ?? this.englishName,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      description: description ?? this.description,
      imagePaths: imagePaths ?? List.of(this.imagePaths),
      isCustom: isCustom ?? this.isCustom,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'syncId': syncId,
    'remoteId': remoteId,
    'chineseName': chineseName,
    'englishName': englishName,
    'bodyPart': bodyPart,
    'equipment': equipment,
    'primaryMuscles': primaryMuscles,
    'description': description,
    'imagePaths': imagePaths,
    'isCustom': isCustom,
    'syncStatus': syncStatus,
    'deleted': deleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CustomExerciseModel.fromJson(Map<String, dynamic> json) {
    return CustomExerciseModel(
      id: (json['id'] as num?)?.toInt(),
      syncId: json['syncId'] as String?,
      remoteId: (json['remoteId'] as num?)?.toInt(),
      chineseName: json['chineseName'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      bodyPart: json['bodyPart'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      primaryMuscles: json['primaryMuscles'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imagePaths: (json['imagePaths'] as List<dynamic>? ?? []).whereType<String>().toList(),
      isCustom: json['isCustom'] as bool? ?? true,
      syncStatus: json['syncStatus'] as String? ?? localSyncPending,
      deleted: json['deleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

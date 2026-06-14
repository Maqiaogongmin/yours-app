import 'package:yours/redesign/localization/generated_built_in_exercises.dart';

String normalizeExerciseIdentity(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u2010-\u2015]'), '-')
      .replaceAll(RegExp(r'[^a-z0-9\u3040-\u30ff\u3400-\u9fff]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? builtInExerciseKeyForReference(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith(builtInExercisePrefix)) {
    final key = trimmed.substring(builtInExercisePrefix.length);
    return builtInExerciseKeyByRemoteId.containsValue(key) ? key : null;
  }
  return builtInExerciseLegacyKeyByName[normalizeExerciseIdentity(trimmed)];
}

String? builtInExerciseReferenceForRemoteId(int? remoteId) {
  final key = remoteId == null ? null : builtInExerciseKeyByRemoteId[remoteId];
  return key == null ? null : '$builtInExercisePrefix$key';
}

String canonicalExerciseReference(String value) {
  final trimmed = value.trim();
  final key = builtInExerciseKeyForReference(trimmed);
  return key == null ? trimmed : '$builtInExercisePrefix$key';
}

bool sameExerciseIdentity(String left, String right) {
  return canonicalExerciseReference(left) == canonicalExerciseReference(right);
}

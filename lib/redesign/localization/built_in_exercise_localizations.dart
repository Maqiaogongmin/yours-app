library;

import 'package:flutter/widgets.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/localization/generated_built_in_exercises.dart';

BuiltInExerciseText? _localizedText(BuildContext context, String? key) {
  if (key == null) {
    return null;
  }
  final languageCode = Localizations.localeOf(context).languageCode;
  return builtInExerciseTexts[languageCode]?[key] ?? builtInExerciseTexts['zh']?[key];
}

BuiltInExerciseText? localizedBuiltInExercise(
  BuildContext context,
  CustomExerciseModel exercise,
) {
  if (exercise.isCustom) {
    return null;
  }
  final key = exercise.builtInKey;
  return _localizedText(context, key);
}

String localizedExerciseName(BuildContext context, String reference) {
  final key = builtInExerciseKeyForReference(reference);
  return _localizedText(context, key)?.name ?? reference;
}

String localizedExerciseAbbr(
  BuildContext context,
  CustomExerciseModel exercise,
) {
  final localizedName = localizedBuiltInExercise(context, exercise)?.name.trim() ?? '';
  if (localizedName.isNotEmpty) {
    return localizedName.characters.first.toUpperCase();
  }
  return exercise.abbr;
}

String localizedExerciseCategory(BuildContext context, String category) {
  final languageCode = Localizations.localeOf(context).languageCode;
  final source = builtInExerciseTexts['zh'];
  final target = builtInExerciseTexts[languageCode] ?? builtInExerciseTexts['zh'];
  if (source != null && target != null) {
    for (final entry in source.entries) {
      final localized = target[entry.key];
      if (localized == null) {
        continue;
      }
      if (entry.value.bodyPart == category) {
        return localized.bodyPart;
      }
      if (entry.value.equipment == category) {
        return localized.equipment;
      }
    }
  }
  return category;
}

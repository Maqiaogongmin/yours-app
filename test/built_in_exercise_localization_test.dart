import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/exercise_identity.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/localization/generated_built_in_exercises.dart';

void main() {
  test('every enabled locale contains all five built-in exercises', () {
    final expectedKeys = builtInExerciseKeyByRemoteId.values.toSet();

    expect(expectedKeys, hasLength(5));
    for (final locale in ['zh', 'en', 'ja']) {
      expect(builtInExerciseTexts[locale]?.keys.toSet(), expectedKeys);
      for (final text in builtInExerciseTexts[locale]!.values) {
        expect(text.name.trim(), isNotEmpty);
        expect(text.bodyPart.trim(), isNotEmpty);
        expect(text.equipment.trim(), isNotEmpty);
        expect(text.primaryMuscles.trim(), isNotEmpty);
        expect(text.description.trim(), isNotEmpty);
      }
    }
  });

  test('legacy names in every supported language resolve to stable references', () {
    expect(canonicalExerciseReference('杠铃卧推'), 'built_in:bench_press');
    expect(canonicalExerciseReference('Bench Press'), 'built_in:bench_press');
    expect(canonicalExerciseReference('ベンチプレス'), 'built_in:bench_press');
    expect(canonicalExerciseReference('Squats'), 'built_in:barbell_squat');
    expect(canonicalExerciseReference('バーベルスクワット'), 'built_in:barbell_squat');
    expect(canonicalExerciseReference('用户自定义动作'), '用户自定义动作');
  });

  test('existing plans, slots, and logs migrate to stable references', () async {
    final database = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 6, 13);

    final routineId = await database
        .into(database.localRoutines)
        .insert(
          LocalRoutinesCompanion.insert(
            name: '旧计划',
            createdAt: now,
            updatedAt: now,
          ),
        );
    final dayId = await database
        .into(database.localTrainingDays)
        .insert(
          LocalTrainingDaysCompanion.insert(
            routineId: routineId,
            week: 1,
            day: 1,
            name: 'D1',
            actionsJson: Value(
              jsonEncode([
                LocalTrainingActionModel(name: 'Bench Press').toJson(),
              ]),
            ),
            updatedAt: now,
          ),
        );
    final slotId = await database
        .into(database.localSlots)
        .insert(
          LocalSlotsCompanion.insert(dayId: dayId, order: 0),
        );
    await database
        .into(database.localSlotEntries)
        .insert(
          LocalSlotEntriesCompanion.insert(
            slotId: slotId,
            exerciseName: '杠铃卧推',
          ),
        );
    final sessionId = await database
        .into(database.localWorkoutSessions)
        .insert(
          LocalWorkoutSessionsCompanion.insert(
            routineId: routineId,
            dayId: Value(dayId),
            startedAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.localWorkoutLogs)
        .insert(
          LocalWorkoutLogsCompanion.insert(
            sessionId: sessionId,
            routineId: routineId,
            dayId: Value(dayId),
            exerciseName: 'ベンチプレス',
            setIndex: 1,
            createdAt: now,
          ),
        );

    final repository = LocalTrainingRepository(database);
    expect(await repository.standardizeExerciseNames(), 3);

    final day = await database.select(database.localTrainingDays).getSingle();
    final action = LocalTrainingActionModel.fromJson(
      (jsonDecode(day.actionsJson) as List).single,
    );
    final slot = await database.select(database.localSlotEntries).getSingle();
    final log = await database.select(database.localWorkoutLogs).getSingle();
    expect(action.name, 'built_in:bench_press');
    expect(slot.exerciseName, 'built_in:bench_press');
    expect(log.exerciseName, 'built_in:bench_press');
    expect(sameExerciseIdentity(action.name, log.exerciseName), isTrue);
  });
}

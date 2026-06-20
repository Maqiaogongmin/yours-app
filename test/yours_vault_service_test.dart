import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_models.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/data/yours_vault_service.dart';

void main() {
  test('Yours Vault export writes manifest and plan files', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final repository = LocalTrainingRepository(trainingDb);
    final plan = LocalTrainingPlanModel(name: 'Vault 测试计划', totalWeeks: 1, daysPerWeek: 1);
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: 'D1',
      actions: [
        LocalTrainingActionModel(name: '杠铃卧推'),
        LocalTrainingActionModel(name: '快走', recordMode: localRecordModeFree),
      ],
    );
    await repository.savePlan(plan);

    final dir = await Directory.systemTemp.createTemp('yours_vault_test_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).exportVault(dir);

    expect(result.planCount, 1);
    final manifest = File('${dir.path}/manifest.json');
    expect(manifest.existsSync(), isTrue);
    final decoded = jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    expect(decoded['format'], 'yours-vault');
    final planFile = Directory('${dir.path}/plans').listSync().whereType<File>().single;
    final planJson = jsonDecode(await planFile.readAsString()) as Map<String, dynamic>;
    final weeks = planJson['weeks'] as List<dynamic>;
    final firstDay = (weeks.single as Map<String, dynamic>)['days'] as List<dynamic>;
    final actions = (firstDay.single as Map<String, dynamic>)['actions'] as List<dynamic>;
    final freeAction = actions.cast<Map<String, dynamic>>().singleWhere(
      (action) => action['exercise'] == '快走',
    );
    expect(freeAction['recordMode'], localRecordModeFree);
  });

  test('Yours Vault resolves reopened databases after restore', () async {
    if (locator.isRegistered<LocalTrainingDatabase>()) {
      await locator.unregister<LocalTrainingDatabase>();
    }
    if (locator.isRegistered<CustomExerciseDatabase>()) {
      await locator.unregister<CustomExerciseDatabase>();
    }

    final oldTrainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final oldExerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(oldTrainingDb);
    locator.registerSingleton<CustomExerciseDatabase>(oldExerciseDb);
    final service = YoursVaultService();

    await locator.unregister<LocalTrainingDatabase>();
    await locator.unregister<CustomExerciseDatabase>();
    await oldTrainingDb.close();
    await oldExerciseDb.close();

    final reopenedTrainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final reopenedExerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    locator.registerSingleton<LocalTrainingDatabase>(reopenedTrainingDb);
    locator.registerSingleton<CustomExerciseDatabase>(reopenedExerciseDb);
    addTearDown(() async {
      if (locator.isRegistered<LocalTrainingDatabase>()) {
        await locator.unregister<LocalTrainingDatabase>();
      }
      if (locator.isRegistered<CustomExerciseDatabase>()) {
        await locator.unregister<CustomExerciseDatabase>();
      }
      await reopenedTrainingDb.close();
      await reopenedExerciseDb.close();
    });

    final repository = LocalTrainingRepository(reopenedTrainingDb);
    await repository.savePlan(LocalTrainingPlanModel(name: '恢复后计划'));

    final dir = await Directory.systemTemp.createTemp('yours_vault_reopened_test_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    final result = await service.exportVault(dir);

    expect(result.planCount, 1);
    expect(File('${dir.path}/manifest.json').existsSync(), isTrue);
  });

  test('Yours Vault inbox imports a new plan', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_new_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/new-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': 'Inbox 新计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '推',
                'actions': [
                  {'exercise': '杠铃卧推', 'sets': 4, 'reps': '6-8'},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 1);
    expect(result.failedFiles, isEmpty);
    final plans = await LocalTrainingRepository(trainingDb).getPlans();
    expect(plans.single.name, 'Inbox 新计划');
    expect(plans.single.days.values.single.actions.single.targetReps, 6);
  });

  test('Yours Vault inbox updates an existing plan without deleting workout logs', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );

    final repository = LocalTrainingRepository(trainingDb);
    final plan = LocalTrainingPlanModel(
      name: '两个月增肌PPL六练',
      totalWeeks: 1,
      daysPerWeek: 1,
      archived: true,
      completedWeeks: {1},
    );
    plan.days['1-1'] = LocalTrainingDayModel(
      week: 1,
      day: 1,
      name: '推',
      actions: [LocalTrainingActionModel(name: '杠铃卧推', targetSets: 2, targetReps: 6)],
    );
    final routineId = await repository.savePlan(plan);
    final savedPlan = (await repository.getPlans()).single;
    final sessionId = await repository.startSession(savedPlan, savedPlan.days.values.single);
    await repository.addLog(
      sessionId: sessionId,
      routineId: routineId,
      dayId: savedPlan.days.values.single.id,
      exerciseName: '杠铃卧推',
      setIndex: 1,
      weight: 50,
      reps: 6,
      durationSeconds: 60,
    );

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_update_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/update-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'action': 'upsert',
        'matchName': '两个月增肌PPL六练',
        'name': '两个月增肌PPL六练',
        'totalWeeks': 1,
        'daysPerWeek': 1,
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '推',
                'actions': [
                  {'name': '杠铃卧推', 'sets': 4, 'reps': 8},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 1);
    final plans = await repository.getPlans();
    expect(plans, hasLength(1));
    final updated = plans.single;
    expect(updated.id, routineId);
    expect(updated.syncId, savedPlan.syncId);
    expect(updated.archived, isTrue);
    expect(updated.completedWeeks, contains(1));
    expect(updated.days.values.single.actions.single.targetSets, 4);
    expect(await trainingDb.localWorkoutSessions.count().getSingle(), 1);
    expect(await trainingDb.localWorkoutLogs.count().getSingle(), 1);
  });

  test('Yours Vault inbox imports exercises before plans', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_exercise_first_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/new-exercise.exercise.json').writeAsString(
      jsonEncode({
        'format': 'yours-exercise',
        'formatVersion': 1,
        'action': 'upsert',
        'name': '新动作',
        'category1': '背部',
        'category2': '器械',
      }),
    );
    await File('${dir.path}/inbox/new-plan.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': '含新动作计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '拉',
                'actions': [
                  {'exercise': '新动作', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedExercises, 1);
    expect(result.importedPlans, 1);
    expect(result.failedFiles, isEmpty);
  });

  test('Yours Vault inbox reports missing exercises and malformed plans', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_errors_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/missing.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'name': '缺动作计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '训练',
                'actions': [
                  {'exercise': '不存在动作', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );
    await File('${dir.path}/inbox/bad.plan.json').writeAsString('{');

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 0);
    expect(result.failedFiles, hasLength(2));
    expect(
      result.failedFiles.map((file) => file.message).join('\n'),
      contains('不存在动作'),
    );
    expect(
      result.failedFiles.map((file) => file.message).join('\n'),
      contains('Unexpected end of input'),
    );
  });

  test('Yours Vault inbox rejects ambiguous plan updates', () async {
    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase.memory());
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(trainingDb.close);
    addTearDown(exerciseDb.close);

    await CustomExerciseRepository(exerciseDb).saveExercise(
      CustomExerciseModel(
        chineseName: '杠铃卧推',
        bodyPart: '胸部',
        equipment: '杠铃',
        primaryMuscles: '胸大肌',
        description: '',
      ),
    );
    final repository = LocalTrainingRepository(trainingDb);
    await repository.savePlan(LocalTrainingPlanModel(name: '重复计划'));
    await repository.savePlan(LocalTrainingPlanModel(name: '重复计划'));

    final dir = await Directory.systemTemp.createTemp('yours_vault_import_ambiguous_');
    addTearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });
    Directory('${dir.path}/inbox').createSync(recursive: true);
    await File('${dir.path}/inbox/ambiguous.plan.json').writeAsString(
      jsonEncode({
        'format': 'yours-plan',
        'formatVersion': 1,
        'action': 'update',
        'matchName': '重复计划',
        'name': '重复计划',
        'weeks': [
          {
            'week': 1,
            'days': [
              {
                'day': 1,
                'name': '训练',
                'actions': [
                  {'exercise': '杠铃卧推', 'sets': 3, 'reps': 10},
                ],
              },
            ],
          },
        ],
      }),
    );

    final result = await YoursVaultService(
      trainingDb: trainingDb,
      exerciseDb: exerciseDb,
    ).importInbox(dir);

    expect(result.importedPlans, 0);
    expect(result.failedFiles.single.message, contains('Multiple existing plans'));
    expect(await trainingDb.localRoutines.count().getSingle(), 2);
  });
}

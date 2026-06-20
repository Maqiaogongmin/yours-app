import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/local_training_models.dart';

void main() {
  test('database migrations backfill stable sync ids for old local data', () async {
    final dir = await Directory.systemTemp.createTemp('yours-sync-migration-');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    final trainingFile = File('${dir.path}/training.sqlite');
    final oldTraining = sqlite.sqlite3.open(trainingFile.path);
    final timestamp = DateTime(2026, 1, 1, 8).millisecondsSinceEpoch;
    try {
      oldTraining
        ..execute('PRAGMA user_version = 3')
        ..execute('''
          CREATE TABLE local_routines (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            name TEXT NOT NULL,
            total_weeks INTEGER NOT NULL DEFAULT 4,
            days_per_week INTEGER NOT NULL DEFAULT 4,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            deleted INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_training_days (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            routine_id INTEGER NOT NULL,
            week INTEGER NOT NULL,
            day INTEGER NOT NULL,
            name TEXT NOT NULL,
            actions_json TEXT NOT NULL DEFAULT '[]',
            sync_status TEXT NOT NULL DEFAULT 'pending',
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_slots (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            day_id INTEGER NOT NULL,
            "order" INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''')
        ..execute('''
          CREATE TABLE local_slot_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            slot_id INTEGER NOT NULL,
            exercise_name TEXT NOT NULL,
            exercise_id INTEGER NULL,
            target_sets INTEGER NOT NULL DEFAULT 3,
            target_reps INTEGER NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''')
        ..execute('''
          CREATE TABLE local_workout_sessions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            routine_id INTEGER NOT NULL,
            day_id INTEGER NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_workout_logs (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            session_id INTEGER NOT NULL,
            routine_id INTEGER NOT NULL,
            day_id INTEGER NULL,
            exercise_name TEXT NOT NULL,
            set_index INTEGER NOT NULL,
            weight REAL NOT NULL DEFAULT 0,
            reps INTEGER NOT NULL DEFAULT 0,
            rir REAL NULL,
            duration_seconds INTEGER NOT NULL DEFAULT 0,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            created_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE local_sync_queue (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL DEFAULT '{}',
            status TEXT NOT NULL DEFAULT 'pending',
            attempts INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          INSERT INTO local_routines
            (id, name, total_weeks, days_per_week, sync_status, deleted, created_at, updated_at)
          VALUES (1, '旧计划', 1, 1, 'pending', 0, $timestamp, $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_training_days
            (id, routine_id, week, day, name, actions_json, sync_status, updated_at)
          VALUES (1, 1, 1, 1, 'D1', '[]', 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_slots (id, day_id, "order", sync_status)
          VALUES (1, 1, 0, 'pending')
        ''')
        ..execute('''
          INSERT INTO local_slot_entries
            (id, slot_id, exercise_name, target_sets, target_reps, sync_status)
          VALUES (1, 1, '深蹲', 3, 5, 'pending')
        ''')
        ..execute('''
          INSERT INTO local_workout_sessions
            (id, routine_id, day_id, started_at, sync_status, updated_at)
          VALUES (1, 1, 1, $timestamp, 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_workout_logs
            (id, session_id, routine_id, day_id, exercise_name, set_index, weight, reps, duration_seconds, sync_status, created_at)
          VALUES (1, 1, 1, 1, '深蹲', 1, 80, 5, 90, 'pending', $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_sync_queue
            (id, entity_type, entity_id, action, payload, status, attempts, created_at, updated_at)
          VALUES (1, 'routine', 1, 'upsert', '{}', 'pending', 0, $timestamp, $timestamp)
        ''')
        ..execute('''
          INSERT INTO local_sync_queue
            (id, entity_type, entity_id, action, payload, status, attempts, created_at, updated_at)
          VALUES (2, 'workout_session', 999, 'delete', '{}', 'pending', 0, $timestamp, $timestamp)
        ''');
    } finally {
      oldTraining.dispose();
    }

    final trainingDb = LocalTrainingDatabase.inMemory(NativeDatabase(trainingFile));
    addTearDown(trainingDb.close);
    final routine = (await trainingDb.select(trainingDb.localRoutines).get()).single;
    final day = (await trainingDb.select(trainingDb.localTrainingDays).get()).single;
    final slot = (await trainingDb.select(trainingDb.localSlots).get()).single;
    final entry = (await trainingDb.select(trainingDb.localSlotEntries).get()).single;
    final session = (await trainingDb.select(trainingDb.localWorkoutSessions).get()).single;
    final log = (await trainingDb.select(trainingDb.localWorkoutLogs).get()).single;
    final queue = await (trainingDb.select(
      trainingDb.localSyncQueue,
    )..orderBy([(item) => OrderingTerm.asc(item.id)])).get();

    expect([
      routine.syncId,
      day.syncId,
      slot.syncId,
      entry.syncId,
      session.syncId,
      log.syncId,
    ], everyElement(isNotEmpty));
    expect(queue.first.eventId, isNotEmpty);
    expect(queue.first.deviceId, startsWith('legacy-'));
    expect(queue.first.entitySyncId, 'routine:${routine.syncId}');
    expect(queue.last.entityType, 'workout_session');
    expect(queue.last.entitySyncId, isEmpty);
    expect(queue.last.status, localSyncSynced);
    expect(routine.archived, isFalse);
    expect(routine.completedWeeksJson, '[]');
    expect(entry.recordMode, localRecordModeStandard);
    expect(log.recordMode, localRecordModeStandard);

    final exerciseFile = File('${dir.path}/custom.sqlite');
    final oldExercises = sqlite.sqlite3.open(exerciseFile.path);
    try {
      oldExercises
        ..execute('PRAGMA user_version = 1')
        ..execute('''
          CREATE TABLE custom_exercises (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER NULL,
            chinese_name TEXT NOT NULL,
            english_name TEXT NOT NULL DEFAULT '',
            body_part TEXT NOT NULL,
            equipment TEXT NOT NULL,
            primary_muscles TEXT NOT NULL,
            description TEXT NOT NULL,
            image_paths_json TEXT NOT NULL DEFAULT '[]',
            is_custom INTEGER NOT NULL DEFAULT 1,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            deleted INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          CREATE TABLE custom_exercise_images (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            exercise_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            caption TEXT NULL,
            created_at INTEGER NOT NULL
          )
        ''')
        ..execute('''
          INSERT INTO custom_exercises
            (id, chinese_name, body_part, equipment, primary_muscles, description, created_at, updated_at)
          VALUES (1, '旧动作', '腿', '杠铃', '股四头肌', '旧库动作', $timestamp, $timestamp)
        ''');
    } finally {
      oldExercises.dispose();
    }
    final exerciseDb = CustomExerciseDatabase.inMemory(NativeDatabase(exerciseFile));
    addTearDown(exerciseDb.close);
    final exercise = (await exerciseDb.select(exerciseDb.customExercises).get()).single;
    expect(exercise.syncId, isNotEmpty);
  });
}

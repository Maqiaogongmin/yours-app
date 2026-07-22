import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';

final locator = GetIt.asNewInstance();

Future<void> configureDatabases() async {
  // Register local-first databases
  locator.registerSingleton<LocalTrainingDatabase>(LocalTrainingDatabase());
  locator.registerSingleton<CustomExerciseDatabase>(CustomExerciseDatabase());

  // Migrate legacy SharedPreferences data to SharedPreferencesAsync (one-time).
  // On HarmonyOS plugin bring-up, this must not block the first Flutter frame.
  final logger = Logger('AppDatabase');
  try {
    final legacyPrefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacyPrefs,
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: 'migrationCompleted',
    ).timeout(const Duration(seconds: 3));
  } on TimeoutException catch (error) {
    logger.warning('SharedPreferences migration timed out: $error');
  } catch (error, stack) {
    logger.warning('SharedPreferences migration skipped: $error');
    logger.fine('SharedPreferences migration stack: $stack');
  }
}

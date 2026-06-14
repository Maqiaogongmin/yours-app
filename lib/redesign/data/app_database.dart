import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/local_training_database.dart';

final locator = GetIt.asNewInstance();

Future<void> configureDatabases() async {
  // Migrate legacy SharedPreferences data to SharedPreferencesAsync (one-time)
  final legacyPrefs = await SharedPreferences.getInstance();
  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: legacyPrefs,
    sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
    migrationCompletedKey: 'migrationCompleted',
  );

  // Register local-first databases
  locator.registerSingleton<LocalTrainingDatabase>(LocalTrainingDatabase());
  locator.registerSingleton<CustomExerciseDatabase>(CustomExerciseDatabase());
}

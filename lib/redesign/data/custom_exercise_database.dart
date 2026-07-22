import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:yours/redesign/data/yours_drift_database.dart';

part 'custom_exercise_database.g.dart';

class CustomExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncId => text().withDefault(const Constant(''))();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get chineseName => text()();
  TextColumn get englishName => text().withDefault(const Constant(''))();
  TextColumn get bodyPart => text()();
  TextColumn get equipment => text()();
  TextColumn get primaryMuscles => text()();
  TextColumn get description => text()();
  TextColumn get imagePathsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class CustomExerciseImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(CustomExercises, #id)();
  TextColumn get path => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get caption => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [CustomExercises, CustomExerciseImages])
class CustomExerciseDatabase extends _$CustomExerciseDatabase {
  final _logger = Logger('CustomExerciseDatabase');

  CustomExerciseDatabase() : super(_openConnection());

  CustomExerciseDatabase.inMemory(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (!await _hasColumn('custom_exercises', 'sync_id')) {
          await migrator.addColumn(customExercises, customExercises.syncId);
        }
        await customStatement(
          "UPDATE custom_exercises SET sync_id = lower(hex(randomblob(4)) || '-' || "
          "hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || "
          "substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || "
          "hex(randomblob(6))) WHERE sync_id IS NULL OR sync_id = ''",
        );
      },
    );
  }

  Future<void> deleteEverything() {
    return transaction(() async {
      for (final table in allTables) {
        _logger.info('Deleting custom exercise table ${table.actualTableName}');
        await delete(table).go();
      }
    });
  }
}

extension on CustomExerciseDatabase {
  Future<bool> _hasColumn(String tableName, String columnName) async {
    final rows = await customSelect(
      'PRAGMA table_info($tableName)',
      readsFrom: const {},
    ).get();
    return rows.any((row) => row.data['name'] == columnName);
  }
}

QueryExecutor _openConnection() {
  return openYoursDriftDatabase('custom_exercises');
}

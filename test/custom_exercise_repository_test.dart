import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/custom_exercise_database.dart';
import 'package:yours/redesign/data/custom_exercise_repository.dart';

void main() {
  test('custom exercise repository imports the Yours seed library', () async {
    final db = CustomExerciseDatabase.inMemory(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = CustomExerciseRepository(db);

    await repository.ensureSeedData();

    final rows = await db.select(db.customExercises).get();
    expect(rows.length, greaterThanOrEqualTo(1));
    expect(rows.every((row) => row.chineseName.trim().isNotEmpty), isTrue);
  });
}

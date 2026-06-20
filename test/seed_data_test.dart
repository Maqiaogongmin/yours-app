import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Yours training and exercise seeds are valid', () async {
    final trainingRaw = await rootBundle.loadString('assets/data/demo_training_data.json');
    final training = jsonDecode(trainingRaw) as Map<String, dynamic>;

    expect(training['routines'], isA<List<dynamic>>());
    expect(training['days'], isA<List<dynamic>>());
    expect(training['sessions'], isA<List<dynamic>>());
    expect(training['logs'], isA<List<dynamic>>());
    expect(training['routines'] as List<dynamic>, isEmpty);
    expect(training['days'] as List<dynamic>, isEmpty);

    final exercisesRaw = await rootBundle.loadString('assets/data/custom_exercises_seed.json');
    final exercises = jsonDecode(exercisesRaw) as Map<String, dynamic>;
    final rows = exercises['exercises'] as List<dynamic>;

    expect(rows, hasLength(5));
    expect(rows.first, containsPair('chineseName', isA<String>()));
  });
}

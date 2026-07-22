import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refactored modules stay below the observation threshold', () {
    final files = <File>[
      ...Directory('lib/redesign/design_system').listSync().whereType<File>().where(
        (file) => file.path.contains('yours_') && file.path.endsWith('_components.dart'),
      ),
      ...Directory('lib/redesign/data').listSync().whereType<File>().where(
        (file) => file.path.contains('yours_vault') && file.path.endsWith('.dart'),
      ),
      ...Directory(
        'lib/redesign/design_system',
      ).listSync().whereType<File>().where((file) => file.path.contains('yours_share_poster')),
      ...Directory('lib/redesign/data/local_training_repository')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('workout_') && file.path.endsWith('.dart')),
      ...Directory(
        'lib/redesign/pages/plan',
      ).listSync().whereType<File>().where((file) => file.path.contains('local_gym_session_')),
      ...Directory('lib/redesign/pages/exercises').listSync().whereType<File>().where(
        (file) => file.path.contains('exercise_library_'),
      ),
      ...Directory('lib/redesign/shareability').listSync().whereType<File>().where(
        (file) => file.path.contains('yours_workout_share_poster_'),
      ),
      File('lib/redesign/pages/plan/local_gym_mode_page.dart'),
      ...Directory(
        'lib/redesign/pages/plan/local_gym_mode_page',
      ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
    ];

    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        file.readAsLinesSync().length,
        lessThanOrEqualTo(400),
        reason: '${file.path} has grown past the refactoring observation threshold',
      );
    }
  });
}

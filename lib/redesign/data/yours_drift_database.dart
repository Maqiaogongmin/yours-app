import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yours/redesign/data/harmony_sqlite.dart';

bool _configuredSqlite = false;

QueryExecutor openYoursDriftDatabase(String name) {
  return DatabaseConnection.delayed(
    Future(() async {
      if (!_configuredSqlite) {
        if (Platform.isAndroid) {
          await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
        }
        sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
        _configuredSqlite = true;
      }

      final documents = await getApplicationDocumentsDirectory();
      final databaseFile = File(p.join(documents.path, '$name.sqlite'));
      return NativeDatabase.createBackgroundConnection(
        databaseFile,
        isolateSetup: configureHarmonySqlite,
      );
    }),
  );
}

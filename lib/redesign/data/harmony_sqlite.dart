import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

bool get isHarmonyOS {
  if (kIsWeb) {
    return false;
  }
  final platform = Platform.operatingSystem.toLowerCase();
  return platform == 'ohos' ||
      platform == 'harmonyos' ||
      platform.contains('ohos') ||
      platform.contains('harmony');
}

void configureHarmonySqlite() {
  if (!kIsWeb && Platform.isAndroid) {
    sqlite_open.open.overrideFor(
      sqlite_open.OperatingSystem.android,
      openCipherOnAndroid,
    );
    return;
  }
  if (!isHarmonyOS) {
    return;
  }
  sqlite_open.open.overrideForAll(_openCipherOnHarmonyOS);
}

DynamicLibrary _openCipherOnHarmonyOS() {
  try {
    return DynamicLibrary.open('libsqlcipher.so');
  } catch (_) {
    final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
    final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
    final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

    return DynamicLibrary.open('/data/data/$appId/lib/libsqlcipher.so');
  }
}

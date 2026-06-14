import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares both supported app locales', () {
    final config = File(
      'android/app/src/main/res/xml/locales_config.xml',
    ).readAsStringSync();

    expect(config, contains('<locale android:name="zh"/>'));
    expect(config, contains('<locale android:name="en"/>'));
  });

  test('legacy storage permissions are limited to pre Android 10', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.READ_EXTERNAL_STORAGE'));
    expect(manifest, contains('android.permission.WRITE_EXTERNAL_STORAGE'));
    expect(
      RegExp(
        r'WRITE_EXTERNAL_STORAGE"\s+android:maxSdkVersion="28"',
      ).hasMatch(manifest),
      isTrue,
    );
    expect(manifest, isNot(contains('android:requestLegacyExternalStorage')));
  });

  test('Android public file bridge covers scoped and legacy storage', () {
    final activity = File(
      'android/app/src/main/kotlin/com/ly/yours/MainActivity.kt',
    ).readAsStringSync();

    expect(activity, contains('MediaStore.MediaColumns.IS_PENDING'));
    expect(activity, contains('withLegacyStoragePermission'));
    expect(activity, contains('findLatestPublicZipUri(relativePath)'));
    expect(activity, contains('WindowCompat.setDecorFitsSystemWindows(window, false)'));
    expect(activity, contains('Environment.getExternalStoragePublicDirectory'));
    expect(activity, contains('"syncBackupToPublicDocuments"'));
    expect(activity, contains('"syncVaultToPublicDocuments"'));
    expect(activity, contains('"pickPublicBackup"'));
  });
}

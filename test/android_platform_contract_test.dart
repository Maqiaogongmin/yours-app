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

  test('Android poster photo bridge supports picking and saving images', () {
    final activity = File(
      'android/app/src/main/kotlin/com/ly/yours/MainActivity.kt',
    ).readAsStringSync();

    expect(activity, contains('photosChannelName = "yours/photos"'));
    expect(activity, contains('"pickPosterBackground"'));
    expect(activity, contains('"saveImageToPhotos"'));
    expect(activity, contains('result.success(true)'));
    expect(activity, contains('MediaStore.Images.Media.EXTERNAL_CONTENT_URI'));
    expect(activity, contains('Environment.DIRECTORY_PICTURES'));
    expect(activity, contains('MediaScannerConnection.scanFile'));
  });

  test('release network security trusts only system CAs while debug allows user CAs', () {
    final mainConfig = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();
    final debugConfig = File(
      'android/app/src/debug/res/xml/network_security_config.xml',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:networkSecurityConfig="@xml/network_security_config"'));
    expect(mainConfig, contains('src="system"'));
    expect(mainConfig, isNot(contains('src="user"')));
    expect(debugConfig, contains('src="system"'));
    expect(debugConfig, contains('src="user"'));
  });
}

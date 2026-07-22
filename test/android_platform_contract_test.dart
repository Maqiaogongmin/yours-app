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

  test('Android launcher icon supports adaptive, round, and monochrome masks', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final adaptive = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final adaptiveRound = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
    ).readAsStringSync();
    final themed = File(
      'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    expect(adaptive, contains('<adaptive-icon'));
    expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    expect(adaptiveRound, contains('<adaptive-icon'));
    expect(themed, contains('<monochrome android:drawable="@drawable/ic_launcher_monochrome"'));
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
    final sources = Directory('android/app/src/main/kotlin/com/ly/yours')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.kt'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(sources, contains('MediaStore.MediaColumns.IS_PENDING'));
    expect(sources, contains('StoragePermissionCoordinator'));
    expect(sources, contains('findLatestPublicZipUri(relativePath)'));
    expect(sources, contains('WindowCompat.setDecorFitsSystemWindows(window, false)'));
    expect(sources, contains('Environment.getExternalStoragePublicDirectory'));
    expect(sources, contains('"syncBackupToPublicDocuments"'));
    expect(sources, contains('"syncVaultToPublicDocuments"'));
    expect(sources, contains('"pickPublicBackup"'));
    expect(sources, contains('"prepareDefaultVaultInboxImport"'));
    expect(sources, contains('findPublicVaultInboxFiles(relativePath)'));
    expect(sources, contains('MediaStore.MediaColumns.OWNER_PACKAGE_NAME'));
    expect(sources, contains('ownedPublicFileCandidates(relativePath, filename)'));
    expect(sources, contains('ownedCandidates.none { it.displayName == filename }'));
    expect(sources, contains('overwritePersistedVaultFile('));
    expect(sources, contains('removeOwnedPublicFileDuplicates(relativePath, filename, uri)'));
    expect(sources, contains('Documents/有思/YoursVault'));
    expect(sources, contains('Intent.ACTION_OPEN_DOCUMENT_TREE'));
    expect(sources, contains('persistedUriPermissions'));
    expect(sources, contains('findPersistedDocumentVaultInbox()'));
    expect(sources, contains('DocumentFile.fromTreeUri(activity, treeUri)'));
    expect(sources, contains('documentTreeUri'));
    expect(
      sources.indexOf('val persistedInbox = findPersistedDocumentVaultInbox()'),
      lessThan(sources.indexOf('val sources = findPublicVaultInboxFiles(relativePath)')),
    );
  });

  test('Android poster photo bridge supports picking and saving images', () {
    final activity = File(
      'android/app/src/main/kotlin/com/ly/yours/AndroidPlatformBridge.kt',
    ).readAsStringSync();
    final photos = File(
      'android/app/src/main/kotlin/com/ly/yours/AndroidActivityCoordinators.kt',
    ).readAsStringSync();

    expect(activity, contains('MethodChannel(messenger, "yours/photos")'));
    expect(activity, contains('"pickPosterBackground"'));
    expect(activity, contains('"saveImageToPhotos"'));
    expect(activity, contains('result.success(true)'));
    expect(photos, contains('MediaStore.Images.Media.EXTERNAL_CONTENT_URI'));
    expect(photos, contains('Environment.DIRECTORY_PICTURES'));
    expect(photos, contains('MediaScannerConnection.scanFile'));
  });

  test('Android app entry point stays lifecycle-only', () {
    final activity = File(
      'android/app/src/main/kotlin/com/ly/yours/MainActivity.kt',
    ).readAsLinesSync();

    expect(activity.length, lessThanOrEqualTo(150));
    expect(activity.join('\n'), contains('YoursPlatformActivity'));
    expect(activity.join('\n'), isNot(contains('MethodChannel')));

    final lifecycle = File(
      'android/app/src/main/kotlin/com/ly/yours/YoursPlatformActivity.kt',
    ).readAsLinesSync();
    expect(lifecycle.length, lessThanOrEqualTo(150));
    expect(lifecycle.join('\n'), isNot(contains('MethodChannel')));
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

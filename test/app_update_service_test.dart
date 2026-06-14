import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yours/redesign/data/app_update_service.dart';

void main() {
  PackageInfo packageInfo({String version = '1.11.0', String buildNumber = '11107'}) {
    return PackageInfo(
      appName: '有思',
      packageName: 'com.ly.yours',
      version: version,
      buildNumber: buildNumber,
    );
  }

  AppUpdateService serviceFor({
    required int latestBuild,
    String latestVersion = '1.11.0',
    String currentBuild = '11107',
    bool isAndroid = true,
  }) {
    return AppUpdateService(
      isAndroid: () => isAndroid,
      packageInfoLoader: () async => packageInfo(buildNumber: currentBuild),
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'android': {
                'latestVersion': latestVersion,
                'latestBuild': latestBuild,
                'downloadUrl': yoursAndroidDownloadUrl,
                'releaseNotes': ['测试更新'],
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  }

  test('detects Android update when remote build is newer', () async {
    final service = serviceFor(latestBuild: 11108, currentBuild: '11107');

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.updateAvailable);
    expect(result.hasUpdate, isTrue);
    expect(result.latestBuild, 11108);
    expect(result.downloadUrl, yoursAndroidDownloadUrl);
  });

  test('reports up to date when remote build is equal', () async {
    final service = serviceFor(latestBuild: 11107, currentBuild: '11107');

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.upToDate);
    expect(result.hasUpdate, isFalse);
  });

  test('reports up to date when current build is newer than remote', () async {
    final service = serviceFor(latestBuild: 11107, currentBuild: '11108');

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.upToDate);
    expect(result.hasUpdate, isFalse);
  });

  test('normalizes Flutter split APK version codes before comparing updates', () async {
    final service = serviceFor(latestBuild: 11108, currentBuild: '13107');

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.updateAvailable);
    expect(result.currentBuild, 11107);
    expect(result.latestBuild, 11108);
  });

  test('does not expose Android APK update state on non Android platforms', () async {
    final service = serviceFor(latestBuild: 11108, isAndroid: false);

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.unsupported);
    expect(result.isUnsupported, isTrue);
  });

  test('silent startup check keeps idle state when network fails', () async {
    final service = AppUpdateService(
      isAndroid: () => true,
      packageInfoLoader: () async => packageInfo(),
      client: MockClient((request) async => throw http.ClientException('offline')),
    );

    final result = await service.checkForUpdates(silent: true);

    expect(result.status, AppUpdateStatus.idle);
  });

  test('manual check reports failure when manifest is invalid', () async {
    final service = AppUpdateService(
      isAndroid: () => true,
      packageInfoLoader: () async => packageInfo(),
      client: MockClient((request) async => http.Response('{"android":{}}', 200)),
    );

    final result = await service.checkForUpdates();

    expect(result.status, AppUpdateStatus.failed);
  });
}

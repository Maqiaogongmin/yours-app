import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Harmony package metadata uses build 11174', () {
    final app = jsonDecode(File('ohos/AppScope/app.json5').readAsStringSync());
    expect(app['app']['bundleName'], 'com.ly.yours');
    expect(app['app']['versionName'], '1.11.5');
    expect(app['app']['versionCode'], 11174);
  });

  test('Harmony app and recent-task labels cover Chinese English and Japanese', () {
    const expected = {
      'zh_CN': '有思',
      'en_US': 'Yours',
      'ja_JP': 'Yours',
    };
    for (final entry in expected.entries) {
      final appScope = _strings(
        'ohos/AppScope/resources/${entry.key}/element/string.json',
      );
      final ability = _strings(
        'ohos/entry/src/main/resources/${entry.key}/element/string.json',
      );
      expect(appScope['app_name'], entry.value);
      expect(ability['EntryAbility_label'], entry.value);
    }
  });

  test('Harmony keeps file restore but does not expose backup destination export', () {
    final plugin = File(
      'ohos/entry/src/main/ets/plugins/YoursPlatformPlugin.ets',
    ).readAsStringSync();
    final bridge = File(
      'lib/redesign/data/backup_platform_bridge.dart',
    ).readAsStringSync();
    final dataPage = File(
      'lib/redesign/pages/profile/profile_page/data_management_page.dart',
    ).readAsStringSync();

    expect(plugin, contains("call.method === 'pickPublicBackup'"));
    expect(plugin, isNot(contains("call.method === 'syncBackupToPublicDocuments'")));
    expect(bridge, contains("invokeMethod<String>('pickPublicBackup')"));
    expect(dataPage, contains('context.l10n.profileRestoreFromFile'));
    expect(dataPage, contains('context.l10n.profileCreateBackup'));
    expect(
      RegExp(
        r'profileCreateBackup[\s\S]{0,180}'
        r'icon: isHarmonyOS \? Icons\.archive_outlined : Icons\.ios_share_outlined',
      ).hasMatch(dataPage),
      isTrue,
    );
  });

  test('Harmony imports Vault inbox from Download without opening a folder picker', () {
    final plugin = File(
      'ohos/entry/src/main/ets/plugins/YoursPlatformPlugin.ets',
    ).readAsStringSync();
    final service = File(
      'lib/redesign/data/yours_vault_service.dart',
    ).readAsStringSync();

    expect(plugin, contains("call.method === 'prepareDefaultVaultInboxImport'"));
    expect(plugin, contains("call.method === 'completeVaultInboxImport'"));
    expect(
      plugin,
      contains('/storage/Users/currentUser/Download/有思/YoursVault/inbox'),
    );
    expect(plugin, contains("normalized.endsWith('.plan.json')"));
    expect(plugin, contains("normalized.endsWith('.exercise.json')"));
    expect(
      RegExp(
        r'prepareDefaultVaultInboxImport[\s\S]{0,500}'
        r'findDownloadVaultInboxFiles\(\)',
      ).hasMatch(plugin),
      isTrue,
    );
    expect(
      service,
      contains('(Platform.isIOS || Platform.isAndroid || isHarmonyOS)'),
    );
  });

  test('Harmony platform labels are generated from localization source', () {
    final generator = File('localization/tools/generate.dart').readAsStringSync();
    expect(generator, contains('_writeHarmonyResources(root, language)'));
    expect(generator, contains("'ja' => 'ja_JP'"));
  });
}

Map<String, String> _strings(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final entries = decoded['string'] as List<dynamic>;
  return {
    for (final entry in entries.cast<Map<String, dynamic>>())
      entry['name'] as String: entry['value'] as String,
  };
}

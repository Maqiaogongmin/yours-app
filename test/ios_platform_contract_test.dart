import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Vault bridge imports default inboxes and preserves them on export', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(appDelegate, contains('"prepareDefaultVaultInboxImport"'));
    expect(appDelegate, contains('iCloud Drive'));
    expect(appDelegate, contains('appendingPathComponent("YoursVault"'));
    expect(appDelegate, isNot(contains('"pickVaultInbox"')));
    expect(appDelegate, isNot(contains('forOpeningContentTypes: [.folder]')));
    expect(appDelegate, contains('completeVaultInboxImport'));
    expect(appDelegate, contains('inbox belongs to the user'));
  });
}

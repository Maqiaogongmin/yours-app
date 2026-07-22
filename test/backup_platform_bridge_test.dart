import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yours/redesign/data/backup_platform_bridge.dart';

void main() {
  test('backup share preserves successful and dismissed results', () async {
    const success = ShareResult('saved', ShareResultStatus.success);
    const dismissed = ShareResult('', ShareResultStatus.dismissed);

    expect(await waitForBackupShare(Future.value(success)), success);
    expect(await waitForBackupShare(Future.value(dismissed)), dismissed);
  });

  test('backup share surfaces platform failures', () async {
    final failure = StateError('share failed');
    await expectLater(
      waitForBackupShare(Future<ShareResult>.error(failure)),
      throwsA(same(failure)),
    );
  });

  test('backup share times out when the platform never completes', () async {
    final completer = Completer<ShareResult>();
    await expectLater(
      waitForBackupShare(
        completer.future,
        timeout: const Duration(milliseconds: 1),
      ),
      throwsA(isA<BackupShareTimeoutException>()),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/data/backup_service.dart';

void main() {
  test('server status parses protocol version and latest cursor', () {
    final status = ServerSyncStatus.fromJson({
      'ok': true,
      'serverVersion': 'YoursBackupServer/0.2',
      'protocolVersion': 2,
      'identityMode': 'syncId',
      'eventCount': 12,
      'latestCursor': 12,
      'latestBackup': {
        'bytes': 52834,
        'updatedAt': '2026-06-01T21:40:36',
      },
      'message': 'ok',
    });

    expect(status.available, isTrue);
    expect(status.protocolVersion, 2);
    expect(status.identityMode, 'syncId');
    expect(status.latestCursor, 12);
    expect(status.latestBackupBytes, 52834);
    expect(status.latestBackupAt, DateTime.parse('2026-06-01T21:40:36'));
  });
}

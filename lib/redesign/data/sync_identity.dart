import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SyncId {
  static const _uuid = Uuid();

  const SyncId._();

  static String newId() => _uuid.v4();
}

class SyncIdentity {
  static const serverDeviceIdKey = 'yours_sync_device_id_v2';
  static String? _memoryDeviceId;

  const SyncIdentity._();

  static Future<String> deviceId() async {
    try {
      final prefs = SharedPreferencesAsync();
      final existing = await prefs.getString(serverDeviceIdKey);
      if (existing != null && existing.trim().isNotEmpty) {
        return existing;
      }
      final value = 'yours-${SyncId.newId()}';
      await prefs.setString(serverDeviceIdKey, value);
      return value;
    } on StateError {
      _memoryDeviceId ??= 'yours-${SyncId.newId()}';
      return _memoryDeviceId!;
    }
  }
}

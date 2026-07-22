import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/sync_identity.dart';

class BackupPreferencesStore {
  static const _lastAutoBackupAtKey = 'redesign_last_auto_backup_at';
  static const _lastDailyBackupDateKey = 'redesign_last_daily_backup_date';
  static const _lastAutoBackupReasonKey = 'redesign_last_auto_backup_reason';
  static const _serverBaseUrlKey = 'yours_backup_server_base_url';
  static const _serverApiTokenKey = 'yours_backup_server_api_token';
  static const _legacyServerDeviceIdKey = 'yours_sync_device_id';
  static const _legacyServerEventCursorKey = 'yours_sync_event_cursor';
  static const _serverDeviceIdKey = 'yours_sync_device_id_v2';
  static const _serverEventCursorKey = 'yours_sync_event_cursor_v2';
  static const _serverLastFailureKey = 'yours_sync_last_failure_v2';
  static const _restoredSyncSettingsKey = 'redesign_sync_settings';

  final SharedPreferencesAsync? _prefsOverride;

  BackupPreferencesStore({SharedPreferencesAsync? prefs}) : _prefsOverride = prefs;

  SharedPreferencesAsync get _prefs => _prefsOverride ?? SharedPreferencesAsync();

  Future<DateTime?> lastAutoBackupAt() async {
    final text = await _prefs.getString(_lastAutoBackupAtKey);
    return text == null ? null : DateTime.tryParse(text);
  }

  Future<String?> lastDailyBackupDate() {
    return _prefs.getString(_lastDailyBackupDateKey);
  }

  Future<void> rememberAutomaticBackup(
    BackupResult result, {
    required String reason,
    required bool daily,
  }) async {
    await _prefs.setString(_lastAutoBackupAtKey, result.createdAt.toIso8601String());
    await _prefs.setString(_lastAutoBackupReasonKey, reason);
    if (daily) {
      await _prefs.setString(_lastDailyBackupDateKey, dateKey(result.createdAt));
    }
  }

  Future<ServerBackupSettings> loadServerBackupSettings() async {
    return ServerBackupSettings(
      baseUrl: await _prefs.getString(_serverBaseUrlKey) ?? '',
      apiToken: await _prefs.getString(_serverApiTokenKey) ?? '',
    );
  }

  Future<void> saveServerBackupSettings(ServerBackupSettings settings) async {
    await _prefs.setString(_serverBaseUrlKey, settings.baseUrl.trim());
    await _prefs.setString(_serverApiTokenKey, settings.apiToken.trim());
  }

  Future<Map<String, Object?>> readAppSettings() async {
    final values = Map<String, Object?>.fromEntries(
      (await _prefs.getAll()).entries.where((entry) => shouldBackupPreference(entry.key)).toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'sharedPreferences': values,
    };
  }

  Future<void> restoreAppSettingsText(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final values = decoded['sharedPreferences'];
    if (values is! Map<String, dynamic>) {
      return;
    }

    for (final entry in values.entries) {
      final key = entry.key;
      if (!shouldBackupPreference(key)) {
        continue;
      }
      final value = entry.value;
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List) {
        await _prefs.setStringList(key, value.whereType<String>().toList());
      }
    }
  }

  Future<void> saveRestoredSyncSettingsText(String raw) {
    return _prefs.setString(_restoredSyncSettingsKey, raw);
  }

  Future<Map<String, Object?>> syncSettingsForBackup({
    required DateTime createdAt,
    required int protocolVersion,
  }) async {
    return {
      'schemaVersion': 2,
      'mode': 'local',
      'serverBackupEnabled': false,
      'incrementalSyncEnabled': false,
      'protocolVersion': protocolVersion,
      'identityMode': 'syncId',
      'serverEventCursor': await serverEventCursor(),
      'createdAt': createdAt.toIso8601String(),
      'secretsIncluded': false,
    };
  }

  int? serverCursorFromSyncSettingsText(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final cursor = _asInt(decoded['serverEventCursor']);
      return cursor == null || cursor < 0 ? null : cursor;
    } on Object {
      return null;
    }
  }

  bool shouldBackupPreference(String key) {
    if (_isSensitivePreference(key)) {
      return false;
    }
    return key != _legacyServerDeviceIdKey &&
        key != _legacyServerEventCursorKey &&
        key != _serverDeviceIdKey &&
        key != _serverEventCursorKey;
  }

  Future<String> deviceId() {
    return SyncIdentity.deviceId();
  }

  Future<int> serverEventCursor() async {
    return await _prefs.getInt(_serverEventCursorKey) ?? 0;
  }

  Future<void> setServerEventCursor(int cursor) {
    return _prefs.setInt(_serverEventCursorKey, cursor);
  }

  Future<String?> serverLastFailure() {
    return _prefs.getString(_serverLastFailureKey);
  }

  Future<void> setServerLastFailure(String message) {
    return _prefs.setString(_serverLastFailureKey, message.trim());
  }

  Future<void> clearServerLastFailure() {
    return _prefs.remove(_serverLastFailureKey);
  }

  static String dateKey(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  bool _isSensitivePreference(String key) {
    final lower = key.toLowerCase();
    return key == _serverApiTokenKey ||
        lower.contains('token') ||
        lower.contains('password') ||
        lower.contains('secret');
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

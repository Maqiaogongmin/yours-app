import 'dart:io';

import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_preferences_store.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/server_sync_client.dart';

class BackupDiagnosticsService {
  const BackupDiagnosticsService({
    required BackupPreferencesStore preferences,
    required ServerSyncClient serverClient,
    required int supportedServerProtocolVersion,
  }) : _preferences = preferences,
       _serverClient = serverClient,
       _supportedServerProtocolVersion = supportedServerProtocolVersion;

  final BackupPreferencesStore _preferences;
  final ServerSyncClient _serverClient;
  final int _supportedServerProtocolVersion;

  Future<ServerSyncStatus> checkServerSyncStatus() async {
    final settings = await _preferences.loadServerBackupSettings();
    return _serverClient.checkStatus(
      settings: settings,
      supportedProtocolVersion: _supportedServerProtocolVersion,
    );
  }

  Future<String> serverDiagnosticsText() async {
    final settings = await _preferences.loadServerBackupSettings();
    final buffer = StringBuffer()
      ..writeln('Yours server sync diagnostics')
      ..writeln('generatedAt: ${DateTime.now().toIso8601String()}')
      ..writeln('platform: ${Platform.operatingSystem}')
      ..writeln('configured: ${settings.isConfigured}')
      ..writeln(
        'baseUrl: ${settings.baseUrl.trim().isEmpty ? '(empty)' : _sanitizeDiagnosticText(settings.baseUrl.trim(), apiToken: settings.apiToken)}',
      )
      ..writeln('apiKeyConfigured: ${settings.apiToken.trim().isNotEmpty}')
      ..writeln('serverTransportSecure: ${_serverTransportSecure(settings.baseUrl)}');

    try {
      buffer.writeln('deviceId: ${await _preferences.deviceId()}');
    } on Object catch (error) {
      buffer.writeln(
        'deviceIdError: ${_sanitizeDiagnosticText(error, apiToken: settings.apiToken)}',
      );
    }
    try {
      buffer.writeln('localCursor: ${await _preferences.serverEventCursor()}');
    } on Object catch (error) {
      buffer.writeln(
        'localCursorError: ${_sanitizeDiagnosticText(error, apiToken: settings.apiToken)}',
      );
    }
    try {
      final lastFailure = await _preferences.serverLastFailure();
      if (lastFailure != null && lastFailure.trim().isNotEmpty) {
        buffer.writeln(
          'lastSyncFailure: ${_sanitizeDiagnosticText(lastFailure, apiToken: settings.apiToken)}',
        );
      }
    } on Object catch (error) {
      buffer.writeln(
        'lastSyncFailureError: ${_sanitizeDiagnosticText(error, apiToken: settings.apiToken)}',
      );
    }
    try {
      final pendingCount = locator.isRegistered<LocalTrainingDatabase>()
          ? await LocalSyncQueueRepository(locator<LocalTrainingDatabase>()).pendingCount()
          : 0;
      buffer.writeln('pendingEvents: $pendingCount');
    } on Object catch (error) {
      buffer.writeln(
        'pendingEventsError: ${_sanitizeDiagnosticText(error, apiToken: settings.apiToken)}',
      );
    }

    if (!settings.isConfigured) {
      return buffer.toString();
    }
    try {
      final status = await checkServerSyncStatus();
      buffer
        ..writeln('serverAvailable: ${status.available}')
        ..writeln('serverVersion: ${status.serverVersion}')
        ..writeln('protocolVersion: ${status.protocolVersion}')
        ..writeln('identityMode: ${status.identityMode}')
        ..writeln('serverLatestCursor: ${status.latestCursor}')
        ..writeln('serverEventCount: ${status.eventCount}')
        ..writeln('latestBackupAt: ${status.latestBackupAt?.toIso8601String() ?? '(none)'}')
        ..writeln('latestBackupBytes: ${status.latestBackupBytes ?? 0}')
        ..writeln(
          'message: ${_sanitizeDiagnosticText(status.message, apiToken: settings.apiToken)}',
        );
    } on Object catch (error) {
      buffer.writeln('serverError: ${_sanitizeDiagnosticText(error, apiToken: settings.apiToken)}');
    }
    return buffer.toString();
  }
}

bool _serverTransportSecure(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  return uri?.scheme.toLowerCase() == 'https';
}

String _sanitizeDiagnosticText(Object? value, {String? apiToken}) {
  var text = '$value';
  final token = apiToken?.trim();
  if (token != null && token.isNotEmpty) {
    text = text.replaceAll(token, '[redacted]');
  }
  text = text.replaceAll(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    'Bearer [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'\b(api[_-]?key|token|access[_-]?token|auth[_-]?token)=([^\s&;]+)',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}=[redacted]',
  );
  return text;
}

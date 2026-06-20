import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/backup_platform_bridge.dart';
import 'package:yours/redesign/data/yours_exception.dart';

class ServerSyncClient {
  static const _serverBackupPath = '/api/yours-backups/latest';
  static const _serverEventsPath = '/api/yours-sync/events';
  static const _serverStatusPath = '/api/yours-sync/status';

  Future<ServerBackupUploadResult> uploadBackup(
    File backup, {
    required ServerBackupSettings settings,
  }) {
    return _serverOperation(() async {
      final endpoint = _serverBackupEndpoint(settings);
      final request = http.MultipartRequest('POST', endpoint);
      request.headers.addAll(_serverHeaders(settings));
      request.files.add(
        await http.MultipartFile.fromPath(
          'backup',
          backup.path,
          filename: p.basename(backup.path),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      return ServerBackupUploadResult(
        source: backup,
        endpoint: endpoint,
        uploadedAt: DateTime.now(),
      );
    });
  }

  Future<ServerBackupDownloadResult> downloadLatestBackup({
    required ServerBackupSettings settings,
    required Directory backupDir,
  }) {
    return _serverOperation(() async {
      final endpoint = _serverBackupEndpoint(settings);
      final response = await http
          .get(endpoint, headers: _serverHeaders(settings))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      if (response.bodyBytes.isEmpty) {
        throw const YoursException(YoursErrorCode.backupEmpty);
      }
      if (!BackupPlatformBridge.looksLikeZip(response.bodyBytes)) {
        throw const YoursException(YoursErrorCode.invalidBackup);
      }

      final output = File(p.join(backupDir.path, _serverBackupFilename(response.headers)));
      await output.writeAsBytes(response.bodyBytes);
      return ServerBackupDownloadResult(
        file: output,
        endpoint: endpoint,
        downloadedAt: DateTime.now(),
      );
    });
  }

  Future<Uri> postEvents({
    required ServerBackupSettings settings,
    required List<Map<String, Object?>> events,
  }) {
    return _serverOperation(() async {
      final endpoint = _serverEndpoint(settings, _serverEventsPath);
      final response = await http
          .post(
            endpoint,
            headers: {
              ..._serverHeaders(settings),
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json, text/plain, */*',
            },
            body: jsonEncode({
              'schemaVersion': 2,
              'client': 'yours',
              'createdAt': DateTime.now().toIso8601String(),
              'events': events,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      return endpoint;
    });
  }

  Future<ServerEventPage> downloadEvents({
    required ServerBackupSettings settings,
    required int after,
    required int limit,
  }) {
    return _serverOperation(() async {
      final endpoint = _serverEndpoint(settings, _serverEventsPath).replace(
        queryParameters: {
          'after': '$after',
          'limit': '$limit',
        },
      );
      final response = await http
          .get(
            endpoint,
            headers: {
              ..._serverHeaders(settings),
              'Accept': 'application/json, text/plain, */*',
            },
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 404) {
        return ServerEventPage(
          events: const [],
          cursor: after,
          latestCursor: after,
          hasMore: false,
          legacyServer: true,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const YoursException(YoursErrorCode.invalidServerEvents);
      }
      final events = decoded['events'];
      return ServerEventPage(
        events: events is List
            ? events.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
            : const [],
        cursor: _asInt(decoded['cursor']) ?? after,
        latestCursor: _asInt(decoded['latestCursor']) ?? after,
        hasMore: decoded['hasMore'] == true,
        legacyServer: false,
      );
    });
  }

  Future<ServerSyncStatus> checkStatus({
    required ServerBackupSettings settings,
    required int supportedProtocolVersion,
  }) {
    return _serverOperation(() async {
      final endpoint = _serverEndpoint(settings, _serverStatusPath);
      final response = await http
          .get(
            endpoint,
            headers: {
              ..._serverHeaders(settings),
              'Accept': 'application/json, text/plain, */*',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const YoursException(YoursErrorCode.invalidServerResponse);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const YoursException(YoursErrorCode.invalidServerStatus);
      }
      final status = ServerSyncStatus.fromJson(decoded);
      if (status.protocolVersion != supportedProtocolVersion || status.identityMode != 'syncId') {
        throw YoursException(
          YoursErrorCode.serverOutdated,
          currentVersion: status.protocolVersion,
          requiredVersion: supportedProtocolVersion,
        );
      }
      return status;
    });
  }

  Uri eventsEndpoint(ServerBackupSettings settings) {
    return _serverEndpoint(settings, _serverEventsPath);
  }

  Future<T> _serverOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on YoursException {
      rethrow;
    } on StateError {
      rethrow;
    } on TimeoutException {
      throw const YoursException(YoursErrorCode.serverTimeout);
    } on HandshakeException {
      throw const YoursException(YoursErrorCode.serverTls);
    } on SocketException {
      throw const YoursException(YoursErrorCode.serverUnreachable);
    } on http.ClientException {
      throw const YoursException(YoursErrorCode.serverInterrupted);
    } on FormatException {
      throw const YoursException(YoursErrorCode.invalidServerResponse);
    }
  }

  Uri _serverBackupEndpoint(ServerBackupSettings settings) {
    return _serverEndpoint(settings, _serverBackupPath);
  }

  Uri _serverEndpoint(ServerBackupSettings settings, String path) {
    final raw = settings.baseUrl.trim();
    if (raw.isEmpty) {
      throw const YoursException(YoursErrorCode.serverNotConfigured);
    }
    final base = Uri.tryParse(raw);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      throw const YoursException(YoursErrorCode.invalidServerAddress);
    }
    final normalizedPath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(path: '$normalizedPath$path');
  }

  Map<String, String> _serverHeaders(ServerBackupSettings settings) {
    final headers = <String, String>{
      'Accept': 'application/zip, application/octet-stream',
      'X-Yours-Backup-Client': 'yours',
    };
    final token = settings.apiToken.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _serverBackupFilename(Map<String, String> _) {
    return 'yours-backup.zip';
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

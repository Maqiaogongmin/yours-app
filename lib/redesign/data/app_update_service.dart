import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const yoursUpdateManifestUrl = 'https://yours-app.uk/latest.json';
const yoursAndroidDownloadUrl = 'https://yours-app.uk/#download';

enum AppUpdateStatus {
  idle,
  checking,
  unsupported,
  upToDate,
  updateAvailable,
  failed,
}

class AppUpdateState {
  final AppUpdateStatus status;
  final String currentVersion;
  final int currentBuild;
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final List<String> releaseNotes;
  final String? errorMessage;
  final DateTime? checkedAt;

  const AppUpdateState._({
    required this.status,
    this.currentVersion = '',
    this.currentBuild = 0,
    this.latestVersion = '',
    this.latestBuild = 0,
    this.downloadUrl = yoursAndroidDownloadUrl,
    this.releaseNotes = const [],
    this.errorMessage,
    this.checkedAt,
  });

  const AppUpdateState.idle() : this._(status: AppUpdateStatus.idle);

  const AppUpdateState.checking({
    String currentVersion = '',
    int currentBuild = 0,
  }) : this._(
         status: AppUpdateStatus.checking,
         currentVersion: currentVersion,
         currentBuild: currentBuild,
       );

  const AppUpdateState.unsupported() : this._(status: AppUpdateStatus.unsupported);

  const AppUpdateState.failed(String message)
    : this._(status: AppUpdateStatus.failed, errorMessage: message);

  bool get hasUpdate => status == AppUpdateStatus.updateAvailable;
  bool get isChecking => status == AppUpdateStatus.checking;
  bool get isUnsupported => status == AppUpdateStatus.unsupported;

  String get latestVersionLabel {
    if (latestVersion.isNotEmpty) {
      return latestVersion;
    }
    return latestBuild > 0 ? 'Build $latestBuild' : '';
  }
}

class AndroidUpdateManifest {
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final List<String> releaseNotes;

  const AndroidUpdateManifest({
    required this.latestVersion,
    required this.latestBuild,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory AndroidUpdateManifest.fromJson(Map<String, dynamic> json) {
    final rawBuild = json['latestBuild'];
    final latestBuild = rawBuild is int ? rawBuild : int.tryParse('$rawBuild');
    if (latestBuild == null) {
      throw const FormatException('Missing android.latestBuild');
    }
    final rawNotes = json['releaseNotes'];
    return AndroidUpdateManifest(
      latestVersion: (json['latestVersion'] as String? ?? '').trim(),
      latestBuild: latestBuild,
      downloadUrl: (json['downloadUrl'] as String? ?? yoursAndroidDownloadUrl).trim(),
      releaseNotes: rawNotes is List<dynamic> ? rawNotes.whereType<String>().toList() : const [],
    );
  }
}

class AppUpdateManifest {
  final AndroidUpdateManifest android;

  const AppUpdateManifest({required this.android});

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    final androidJson = json['android'];
    if (androidJson is! Map<String, dynamic>) {
      throw const FormatException('Missing android update manifest');
    }
    return AppUpdateManifest(android: AndroidUpdateManifest.fromJson(androidJson));
  }
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService();

  final ValueNotifier<AppUpdateState> state = ValueNotifier<AppUpdateState>(
    const AppUpdateState.idle(),
  );

  final http.Client? _client;
  final Uri _manifestUri;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final bool Function() _isAndroid;
  bool _checking = false;

  AppUpdateService({
    http.Client? client,
    Uri? manifestUri,
    Future<PackageInfo> Function()? packageInfoLoader,
    bool Function()? isAndroid,
  }) : _client = client,
       _manifestUri = manifestUri ?? Uri.parse(yoursUpdateManifestUrl),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _isAndroid = isAndroid ?? (() => Platform.isAndroid);

  bool get supportsUpdateCheck => _isAndroid();

  Future<AppUpdateState> checkForUpdates({bool silent = false}) async {
    if (!supportsUpdateCheck) {
      state.value = const AppUpdateState.unsupported();
      return state.value;
    }
    if (_checking) {
      return state.value;
    }

    _checking = true;
    if (!silent) {
      state.value = const AppUpdateState.checking();
    }
    try {
      final packageInfo = await _packageInfoLoader();
      final rawCurrentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final currentBuild = normalizeAndroidBuildNumber(rawCurrentBuild);
      if (!silent) {
        state.value = AppUpdateState.checking(
          currentVersion: packageInfo.version,
          currentBuild: currentBuild,
        );
      }

      final response = await _getManifestResponse();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Update manifest returned ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Update manifest must be a JSON object');
      }
      final manifest = AppUpdateManifest.fromJson(decoded);
      final nextState = evaluateAndroidUpdate(
        currentVersion: packageInfo.version,
        currentBuild: currentBuild,
        manifest: manifest.android,
      );
      state.value = AppUpdateState._(
        status: nextState.status,
        currentVersion: nextState.currentVersion,
        currentBuild: nextState.currentBuild,
        latestVersion: nextState.latestVersion,
        latestBuild: nextState.latestBuild,
        downloadUrl: nextState.downloadUrl,
        releaseNotes: nextState.releaseNotes,
        checkedAt: DateTime.now(),
      );
      return state.value;
    } on Object catch (error) {
      if (!silent) {
        state.value = AppUpdateState.failed('$error');
      }
      return state.value;
    } finally {
      _checking = false;
    }
  }

  Future<http.Response> _getManifestResponse() async {
    final client = _client ?? http.Client();
    try {
      return await client.get(_manifestUri).timeout(const Duration(seconds: 8));
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  @visibleForTesting
  AppUpdateState evaluateAndroidUpdate({
    required String currentVersion,
    required int currentBuild,
    required AndroidUpdateManifest manifest,
  }) {
    final hasUpdate = manifest.latestBuild > currentBuild;
    return AppUpdateState._(
      status: hasUpdate ? AppUpdateStatus.updateAvailable : AppUpdateStatus.upToDate,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: manifest.latestVersion,
      latestBuild: manifest.latestBuild,
      downloadUrl: manifest.downloadUrl.isEmpty ? yoursAndroidDownloadUrl : manifest.downloadUrl,
      releaseNotes: manifest.releaseNotes,
    );
  }

  @visibleForTesting
  int normalizeAndroidBuildNumber(int buildNumber) {
    if (buildNumber < 12000) {
      return buildNumber;
    }
    const flutterAbiSplitOffsets = [4000, 2000, 1000];
    for (final offset in flutterAbiSplitOffsets) {
      final normalized = buildNumber - offset;
      if (normalized >= 10000 && normalized < buildNumber) {
        return normalized;
      }
    }
    return buildNumber;
  }
}

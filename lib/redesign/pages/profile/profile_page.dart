/// Profile page — fourth tab. Account info.
///
/// Features from prototype:
/// - Account info card with avatar and user summary
/// - "编辑" button → opens account edit sheet
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/app_update_service.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/backup_platform_bridge.dart';
import 'package:yours/redesign/data/harmony_sqlite.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/redesign_data_refresh.dart';
import 'package:yours/redesign/data/yours_vault_service.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/pages/profile/settings_page.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
import 'package:url_launcher/url_launcher.dart';
part 'profile_page/profile_cards.dart';
part 'profile_page/data_management_page.dart';
part 'profile_page/about_sheet.dart';
part 'profile_page/server_backup_settings_sheet.dart';
part 'profile_page/profile_actions.dart';
part 'profile_page/profile_actions_backup.dart';
part 'profile_page/profile_actions_server.dart';
part 'profile_page/profile_actions_settings.dart';
part 'profile_page/profile_actions_vault.dart';

const _officialWebsiteUrl = 'https://yours-app.uk';
const _privacyPolicyUrl = 'https://yours-app.uk/privacy-policy.html';
const _githubRepositoryUrl = 'https://github.com/Maqiaogongmin/yours-app';
const _harmonyFilesChannel = MethodChannel('yours/files');

Future<bool> _openExternalUrlOnHarmonyOS(String url) async {
  final launched = await _harmonyFilesChannel.invokeMethod<bool>(
    'openExternalUrl',
    {'url': url},
  );
  return launched ?? false;
}

void _showExternalUrlFailureMessage(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final bottomInset = MediaQuery.viewInsetsOf(overlayContext).bottom;
      return Positioned(
        left: 18,
        right: 18,
        bottom: bottomInset + 24,
        child: IgnorePointer(
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(overlayContext).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    message,
                    style: Theme.of(overlayContext).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(overlayContext).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Timer(const Duration(seconds: 3), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

Future<void> _openExternalUrl(
  BuildContext context,
  String url, {
  String? failureMessage,
}) async {
  final resolvedFailureMessage = failureMessage ?? context.l10n.profileOpenLinkFailed;
  try {
    final launched = isHarmonyOS
        ? await _openExternalUrlOnHarmonyOS(url)
        : await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
    if (!launched && context.mounted) {
      _showExternalUrlFailureMessage(context, resolvedFailureMessage);
    }
  } on Object {
    if (!context.mounted) {
      return;
    }
    _showExternalUrlFailureMessage(context, resolvedFailureMessage);
  }
}

String _localizedProfileDataError(BuildContext context, Object error) {
  return localizedErrorDetail(context, error);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _backupService = BackupService();
  final _vaultService = YoursVaultService();
  final _appUpdateService = AppUpdateService.instance;
  final _dataManagementSnapshot = ValueNotifier<YoursDataManagementSnapshot>(
    const YoursDataManagementSnapshot(),
  );
  LocalSyncQueueRepository get _syncQueue =>
      LocalSyncQueueRepository(locator<LocalTrainingDatabase>());
  File? _latestBackup;
  DateTime? _latestBackupUpdatedAt;
  ServerBackupSettings _serverBackupSettings = const ServerBackupSettings(
    baseUrl: '',
    apiToken: '',
  );
  int? _pendingSyncCount;
  Directory? _latestVaultDirectory;
  DateTime? _latestVaultExportedAt;
  ICloudDriveStatus? _iCloudStatus;
  YoursDataManagementActivity? _iCloudActivity;
  ServerSyncStatus? _serverSyncStatus;
  YoursDataManagementError? _serverStatusError;
  bool _busy = false;
  late final _actions = _ProfilePageActions(this);

  @override
  void initState() {
    super.initState();
    _loadLatestBackup();
    _loadServerBackupSettings();
    _loadPendingSyncCount();
    _loadDefaultVaultDirectory();
    _loadICloudStatus();
    RedesignDataRefresh.instance.syncQueueRevision.addListener(_handleSyncQueueChanged);
  }

  @override
  void dispose() {
    RedesignDataRefresh.instance.syncQueueRevision.removeListener(_handleSyncQueueChanged);
    _dataManagementSnapshot.dispose();
    super.dispose();
  }

  void _handleSyncQueueChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadPendingSyncCount());
  }

  YoursDataManagementSnapshot _currentDataManagementSnapshot() {
    return YoursDataManagementSnapshot(
      latestBackupName: _latestBackup == null ? null : _actions.fileName(_latestBackup!.path),
      latestBackupUpdatedAt: _latestBackupUpdatedAt,
      latestVaultPath: _latestVaultDirectory?.path,
      latestVaultExportedAt: _latestVaultExportedAt,
      serverConfigured: _serverBackupSettings.isConfigured,
      iCloudStatus: _iCloudStatus,
      iCloudActivity: _iCloudActivity,
      serverSyncStatus: _serverSyncStatus,
      serverStatusError: _serverStatusError,
      pendingSyncCount: _pendingSyncCount,
    );
  }

  void _publishDataManagementSnapshot() {
    _dataManagementSnapshot.value = _currentDataManagementSnapshot();
  }

  void _updateActionState(VoidCallback fn) => setState(fn);

  Future<void> _loadLatestBackup() async {
    try {
      final latest = await _backupService.latestBackup();
      final updatedAt = latest?.lastModifiedSync();
      if (!mounted) {
        return;
      }
      setState(() {
        _latestBackup = latest;
        _latestBackupUpdatedAt = updatedAt;
      });
      _publishDataManagementSnapshot();
    } on Object {
      // 静默降级 —— 容器未就绪时 latestBackup() 可能失败。
    }
  }

  Future<void> _loadServerBackupSettings() async {
    try {
      final settings = await _backupService.loadServerBackupSettings();
      if (!mounted) {
        return;
      }
      setState(() => _serverBackupSettings = settings);
      _publishDataManagementSnapshot();
    } on Object {
      // 静默降级。
    }
  }

  Future<void> _loadPendingSyncCount() async {
    try {
      final count = await _syncQueue.pendingCount();
      if (!mounted) {
        return;
      }
      setState(() => _pendingSyncCount = count);
      _publishDataManagementSnapshot();
    } on Object {
      // 静默降级。
    }
  }

  Future<void> _loadDefaultVaultDirectory() async {
    try {
      final directory = await _vaultService.defaultVaultDirectory();
      final exportedAt = await _latestVaultExportedAtFrom(directory);
      if (!mounted) {
        return;
      }
      setState(() {
        _latestVaultDirectory = directory;
        _latestVaultExportedAt = exportedAt;
      });
      _publishDataManagementSnapshot();
    } on Object {
      // 容器可能尚未就绪（首次安装/更新后），静默降级。
      // 用户点击「导出 Vault」时 exportDefaultVault() 会重新获取路径。
    }
  }

  Future<DateTime?> _latestVaultExportedAtFrom(Directory directory) async {
    final manifest = File('${directory.path}/manifest.json');
    if (!manifest.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(manifest.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        final exportedAt = decoded['exportedAt'] as String?;
        if (exportedAt != null) {
          return DateTime.tryParse(exportedAt);
        }
      }
      return manifest.lastModifiedSync();
    } on Object {
      return null;
    }
  }

  Future<void> _loadICloudStatus() async {
    if (!Platform.isIOS) {
      return;
    }
    final status = await _backupService.getICloudStatus();
    if (!mounted) {
      return;
    }
    setState(() => _iCloudStatus = status);
    _publishDataManagementSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Title ─────────────────────────────────────────
          _SectionHeader(title: context.l10n.profileTitle),

          const SizedBox(height: 4),

          // ── Account info card ──────────────────────────────────────
          _AccountCard(),
          const SizedBox(height: 16),

          _DataManagementCard(
            snapshotNotifier: _dataManagementSnapshot,
            busy: _busy,
            latestBackupName: _latestBackup == null ? null : _actions.fileName(_latestBackup!.path),
            latestBackupUpdatedAt: _latestBackupUpdatedAt,
            latestVaultPath: _latestVaultDirectory?.path,
            latestVaultExportedAt: _latestVaultExportedAt,
            serverConfigured: _serverBackupSettings.isConfigured,
            iCloudStatus: _iCloudStatus,
            iCloudActivity: _iCloudActivity,
            serverSyncStatus: _serverSyncStatus,
            serverStatusError: _serverStatusError,
            pendingSyncCount: _pendingSyncCount,
            onExportVault: _actions.exportYoursVault,
            onImportVaultInbox: _actions.importYoursVaultInbox,
            onCreateBackup: _actions.createBackup,
            onExportBackupToICloud: _actions.exportLatestBackupToICloudDrive,
            onRestoreBackupFromICloud: _actions.confirmRestoreFromICloud,
            onRestoreBackup: _actions.confirmRestore,
            onEditServer: _actions.showServerBackupSettingsSheet,
            onCheckServer: _actions.checkServerSyncStatus,
            onSyncServer: _actions.syncPendingChangesToServer,
            onCopyServerDiagnostics: _actions.copyServerDiagnostics,
          ),
          const SizedBox(height: 16),

          _SettingsCard(onTap: _actions.openSettings),
        ],
      ),
    );
  }
}

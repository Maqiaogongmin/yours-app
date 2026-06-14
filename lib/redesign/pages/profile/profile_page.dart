/// Profile page — fourth tab. Account info.
///
/// Features from prototype:
/// - Account info card with avatar and user summary
/// - "编辑" button → opens account edit sheet
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/app_database.dart';
import 'package:yours/redesign/data/app_update_service.dart';
import 'package:yours/redesign/data/backup_service.dart';
import 'package:yours/redesign/data/local_sync_queue_repository.dart';
import 'package:yours/redesign/data/local_training_database.dart';
import 'package:yours/redesign/data/redesign_data_refresh.dart';
import 'package:yours/redesign/data/yours_vault_service.dart';
import 'package:yours/redesign/localization/localized_error.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/pages/profile/settings_page.dart';
import 'package:yours/redesign/shared/widgets/responsive_action_button.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
import 'package:url_launcher/url_launcher.dart';

const _officialWebsiteUrl = 'https://yours-app.uk';
const _githubRepositoryUrl = 'https://github.com/Maqiaogongmin/yours-app';

Future<void> _openExternalUrl(
  BuildContext context,
  String url, {
  String? failureMessage,
}) async {
  final resolvedFailureMessage = failureMessage ?? context.l10n.profileOpenLinkFailed;
  try {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resolvedFailureMessage), behavior: SnackBarBehavior.floating),
      );
    }
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resolvedFailureMessage), behavior: SnackBarBehavior.floating),
    );
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
  final _dataManagementSnapshot = ValueNotifier<_DataManagementSnapshot>(
    const _DataManagementSnapshot(),
  );
  LocalSyncQueueRepository get _syncQueue =>
      LocalSyncQueueRepository(locator<LocalTrainingDatabase>());
  File? _latestBackup;
  ServerBackupSettings _serverBackupSettings = const ServerBackupSettings(
    baseUrl: '',
    apiToken: '',
  );
  int? _pendingSyncCount;
  Directory? _latestVaultDirectory;
  ICloudDriveStatus? _iCloudStatus;
  String? _iCloudActivityMessage;
  ServerSyncStatus? _serverSyncStatus;
  String? _serverStatusError;
  bool _busy = false;

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

  _DataManagementSnapshot _currentDataManagementSnapshot() {
    return _DataManagementSnapshot(
      latestBackupName: _latestBackup == null ? null : _fileName(_latestBackup!.path),
      latestVaultPath: _latestVaultDirectory?.path,
      serverConfigured: _serverBackupSettings.isConfigured,
      iCloudStatus: _iCloudStatus,
      iCloudActivityMessage: _iCloudActivityMessage,
      serverSyncStatus: _serverSyncStatus,
      serverStatusError: _serverStatusError,
      pendingSyncCount: _pendingSyncCount,
    );
  }

  void _publishDataManagementSnapshot() {
    _dataManagementSnapshot.value = _currentDataManagementSnapshot();
  }

  Future<void> _loadLatestBackup() async {
    try {
      final latest = await _backupService.latestBackup();
      if (!mounted) {
        return;
      }
      setState(() => _latestBackup = latest);
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
      if (!mounted) {
        return;
      }
      setState(() => _latestVaultDirectory = directory);
      _publishDataManagementSnapshot();
    } on Object {
      // 容器可能尚未就绪（首次安装/更新后），静默降级。
      // 用户点击「导出 Vault」时 exportDefaultVault() 会重新获取路径。
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

  Future<void> _exportYoursVault() async {
    setState(() => _busy = true);
    try {
      final result = await _vaultService.exportDefaultVault();
      if (!mounted) {
        return;
      }
      setState(() {
        _latestVaultDirectory = result.directory;
        if (Platform.isIOS) {
          _iCloudActivityMessage = context.l10n.profileRecentVaultExport(
            _fileName(result.directory.path),
          );
        }
      });
      _publishDataManagementSnapshot();
      _showMessage(
        context.l10n.profileVaultExportSummary(
          result.planCount,
          result.workoutCount,
          result.exerciseCount,
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = _friendlyDataError(error);
      if (Platform.isIOS) {
        setState(
          () => _iCloudActivityMessage = context.l10n.profileRecentVaultExportFailed(message),
        );
        _publishDataManagementSnapshot();
      }
      _showMessage(context.l10n.profileVaultExportFailed(message));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importYoursVaultInbox() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final result = await _vaultService.importDefaultInbox();
      if (!mounted) {
        return;
      }
      if (result.importedPlans > 0 || result.importedExercises > 0) {
        RedesignDataRefresh.instance.notifyRestored();
        await _loadPendingSyncCount();
      }
      final skippedText = result.skippedFiles.isEmpty
          ? ''
          : l10n.profileSkippedFiles(result.skippedFiles.length);
      final summary = l10n.profileVaultImportSummary(
        result.importedPlans,
        result.importedExercises,
        skippedText,
      );
      final firstFailure = result.failedFiles.isEmpty ? null : result.failedFiles.first;
      _showMessage(
        firstFailure == null
            ? summary
            : '$summary ${firstFailure.fileName}: ${firstFailure.message}',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        context.l10n.profileVaultImportFailed(localizedErrorDetail(context, error)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final result = await _backupService.createBackup();
      if (!mounted) {
        return;
      }
      setState(() => _latestBackup = result.file);
      _publishDataManagementSnapshot();
      await _loadPendingSyncCount();
      if (!mounted) {
        return;
      }
      final l10n = context.l10n;
      await _backupService.shareBackup(
        result.file,
        sharePositionOrigin: _sharePositionOrigin(),
        title: l10n.backupShareTitle,
        subject: l10n.backupShareSubject,
        text: l10n.backupShareText,
      );
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.profileBackupCreated(_fileName(result.file.path)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.profileBackupFailed(localizedErrorDetail(context, error)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _exportLatestBackupToICloudDrive() async {
    setState(() => _busy = true);
    try {
      final result = await _backupService.exportLatestBackupToICloudDrive();
      await _loadICloudStatus();
      if (!mounted) {
        return;
      }
      setState(
        () =>
            _iCloudActivityMessage = context.l10n.profileRecentBackupExport(_fileName(result.path)),
      );
      _showMessage(context.l10n.profileBackupExportedICloud(_fileName(result.path)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final detail = localizedErrorDetail(context, error);
      setState(() => _iCloudActivityMessage = context.l10n.profileRecentExportFailed(detail));
      _showMessage(context.l10n.profileICloudExportFailed(detail));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    final viewSize = MediaQuery.sizeOf(context);
    final x = (origin.dx + renderObject.size.width / 2).clamp(1.0, viewSize.width - 1);
    final y = (origin.dy + renderObject.size.height / 2).clamp(1.0, viewSize.height - 1);
    return Rect.fromCenter(center: Offset(x, y), width: 1, height: 1);
  }

  Future<void> _confirmRestore() async {
    final File? picked;
    try {
      picked = await _backupService.pickBackupFile();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        context.l10n.profilePickBackupFailed(localizedErrorDetail(context, error)),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (picked == null) {
      _showMessage(context.l10n.profilePickBackupCancelled);
      return;
    }
    final backup = picked;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.profileRestoreBackupTitle),
        content: Text(context.l10n.profileRestoreBackupMessage(_fileName(backup.path))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(context.l10n.commonRestore),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    await _restoreBackupFile(backup);
  }

  Future<void> _confirmRestoreFromICloud() async {
    final File? picked;
    try {
      picked = await _backupService.pickICloudBackup();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final detail = localizedErrorDetail(context, error);
      setState(() => _iCloudActivityMessage = context.l10n.profileRecentRestoreFailed(detail));
      _publishDataManagementSnapshot();
      _showMessage(context.l10n.profilePickICloudBackupFailed(detail));
      return;
    }
    if (!mounted) {
      return;
    }
    if (picked == null) {
      _showMessage(context.l10n.profilePickICloudBackupCancelled);
      return;
    }
    final backup = picked;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.profileRestoreICloudTitle),
        content: Text(context.l10n.profileRestoreBackupMessage(_fileName(backup.path))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(context.l10n.commonRestore),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _iCloudActivityMessage = context.l10n.profileRestoringICloud);
    _publishDataManagementSnapshot();
    await _restoreBackupFile(
      backup,
      successMessagePrefix: context.l10n.profileICloudRestoreComplete,
    );
  }

  Future<void> _showServerBackupSettingsSheet() async {
    final urlController = TextEditingController(text: _serverBackupSettings.baseUrl);
    final tokenController = TextEditingController(text: _serverBackupSettings.apiToken);
    final saved = await showModalBottomSheet<ServerBackupSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _ServerBackupSettingsSheet(
            urlController: urlController,
            tokenController: tokenController,
          ),
        );
      },
    );
    urlController.dispose();
    tokenController.dispose();
    if (saved == null || !mounted) {
      return;
    }
    await _backupService.saveServerBackupSettings(saved);
    if (!mounted) {
      return;
    }
    setState(() => _serverBackupSettings = saved);
    _publishDataManagementSnapshot();
    _showMessage(
      saved.isConfigured
          ? context.l10n.profileServerAddressSaved
          : context.l10n.profileServerAddressCleared,
    );
  }

  Future<void> _syncPendingChangesToServer() async {
    final l10n = context.l10n;
    if (!_serverBackupSettings.isConfigured) {
      _showMessage(l10n.profileConfigureServerFirst);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _backupService.syncNowWithServer();
      if (!mounted) {
        return;
      }
      await _handleServerSmartSyncResult(result);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final detail = localizedErrorDetail(context, error);
      await _loadPendingSyncCount();
      if (!mounted) {
        return;
      }
      _showMessage(l10n.profileServerSyncFailed(detail));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleServerSmartSyncResult(ServerSmartSyncResult result) async {
    final l10n = context.l10n;
    switch (result.state) {
      case ServerSmartSyncState.synced:
        final sync = result.sync;
        if (sync == null) {
          _showMessage(l10n.profileServerSyncComplete);
          return;
        }
        setState(() => _latestBackup = sync.backup.file);
        _publishDataManagementSnapshot();
        await _loadPendingSyncCount();
        await _refreshServerSyncStatus();
        if (sync.appliedEventCount > 0) {
          RedesignDataRefresh.instance.notifyRestored();
        }
        _showMessage(
          sync.uploadedCount == 0 && sync.downloadedEventCount == 0 && sync.appliedEventCount == 0
              ? l10n.profileServerAlreadyLatest
              : l10n.profileServerSyncSummary(
                  sync.uploadedCount,
                  sync.downloadedEventCount,
                  sync.appliedEventCount,
                ),
        );
      case ServerSmartSyncState.needsInitialRestore:
        await _confirmRestoreLatestServerBackup(
          title: l10n.profileServerBackupFound,
          content: l10n.profileServerBackupFoundMessage,
          confirmLabel: l10n.profileRestoreToDevice,
        );
      case ServerSmartSyncState.canFallbackRestore:
        await _confirmRestoreLatestServerBackup(
          title: l10n.profileNormalSyncFailed,
          content: l10n.profileNormalSyncFailedMessage(
            result.errorMessage ?? l10n.commonUnknownError,
          ),
          confirmLabel: l10n.profileRestoreFromBackup,
        );
      case ServerSmartSyncState.failed:
        await _loadPendingSyncCount();
        await _refreshServerSyncStatus();
        _showMessage(
          l10n.profileServerSyncFailed(
            result.errorMessage ?? l10n.commonUnknownError,
          ),
        );
    }
  }

  Future<void> _checkServerSyncStatus() async {
    if (!_serverBackupSettings.isConfigured) {
      _showMessage(context.l10n.profileConfigureServerSyncFirst);
      return;
    }
    setState(() {
      _busy = true;
      _serverStatusError = null;
    });
    try {
      final status = await _backupService.checkServerSyncStatus();
      if (!mounted) {
        return;
      }
      setState(() => _serverSyncStatus = status);
      _publishDataManagementSnapshot();
      _showMessage(
        context.l10n.profileServerAvailable(status.protocolVersion ?? 0, status.eventCount),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final detail = localizedErrorDetail(context, error);
      setState(() => _serverStatusError = detail);
      _publishDataManagementSnapshot();
      _showMessage(context.l10n.profileServerTestFailed(detail));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _refreshServerSyncStatus() async {
    if (!_serverBackupSettings.isConfigured) {
      return;
    }
    try {
      final status = await _backupService.checkServerSyncStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _serverSyncStatus = status;
        _serverStatusError = null;
      });
      _publishDataManagementSnapshot();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _serverStatusError = localizedErrorDetail(context, error));
      _publishDataManagementSnapshot();
    }
  }

  Future<void> _copyServerDiagnostics() async {
    try {
      final text = await _backupService.serverDiagnosticsText();
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.profileDiagnosticsCopied);
    } on Object catch (error) {
      await Clipboard.setData(
        ClipboardData(
          text:
              'Yours server sync diagnostics\n'
              'generatedAt: ${DateTime.now().toIso8601String()}\n'
              'copyFallbackError: $error\n',
        ),
      );
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.profileDiagnosticsFallbackCopied);
    }
  }

  Future<void> _confirmRestoreLatestServerBackup({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    if (!_serverBackupSettings.isConfigured) {
      _showMessage(context.l10n.profileConfigureServerFirst);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    await _restoreLatestServerBackup();
  }

  Future<void> _restoreBackupFile(
    File backup, {
    String? successMessagePrefix,
  }) async {
    setState(() => _busy = true);
    try {
      final result = await _backupService.restoreBackup(backup);
      if (!mounted) {
        return;
      }
      setState(() => _latestBackup = result.source);
      _publishDataManagementSnapshot();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(successMessagePrefix ?? context.l10n.profileRestoreComplete),
          content: Text(
            context.l10n.profileRestoreSummary(
              result.restoredFileCount,
              _fileName(result.safetyBackup.path),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.profileAcknowledged),
            ),
          ],
        ),
      );
      RedesignDataRefresh.instance.notifyRestored();
      await _loadLatestBackup();
      await _loadPendingSyncCount();
      if ((successMessagePrefix ?? '').contains('iCloud')) {
        setState(
          () => _iCloudActivityMessage = context.l10n.profileRecentICloudRestore(
            _fileName(result.source.path),
          ),
        );
        _publishDataManagementSnapshot();
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.profileRestoreFailed(localizedErrorDetail(context, error)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restoreLatestServerBackup() async {
    setState(() => _busy = true);
    try {
      final result = await _backupService.restoreLatestServerBackup();
      if (!mounted) {
        return;
      }
      setState(() => _latestBackup = result.source);
      _publishDataManagementSnapshot();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.profileServerRestoreComplete),
          content: Text(
            context.l10n.profileRestoreSummary(
              result.restoredFileCount,
              _fileName(result.safetyBackup.path),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.profileAcknowledged),
            ),
          ],
        ),
      );
      RedesignDataRefresh.instance.notifyRestored();
      await _loadLatestBackup();
      await _loadPendingSyncCount();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        context.l10n.profileServerSnapshotRestoreFailed(
          localizedErrorDetail(context, error),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _friendlyDataError(Object error) {
    final rawText = '$error';
    if (rawText.contains('connection was closed') || rawText.contains('Tried to send Request')) {
      return context.l10n.profileDatabasePreparing;
    }
    return _localizedDataError(error);
  }

  String _localizedDataError(Object error) {
    return _localizedProfileDataError(context, error);
  }

  void _showMessage(String message) {
    final safeMessage = message
        .replaceAll(
          RegExp(r'.*connection was closed.*', caseSensitive: false, dotAll: true),
          context.l10n.profileDatabasePreparing,
        )
        .replaceAll(
          RegExp(r'.*Tried to send Request.*', caseSensitive: false, dotAll: true),
          context.l10n.profileDatabasePreparing,
        )
        .replaceAll(
          RegExp(r'<!doctype html.*', caseSensitive: false, dotAll: true),
          context.l10n.profileServerReturnedHtml,
        )
        .replaceAll(
          RegExp(r'<html.*', caseSensitive: false, dotAll: true),
          context.l10n.profileServerReturnedHtml,
        )
        .replaceAll(
          RegExp(r'target-server', caseSensitive: false),
          context.l10n.profileTargetServer,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(safeMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fileName(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }

  void _showAboutYoursSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<AppUpdateState>(
        valueListenable: _appUpdateService.state,
        builder: (context, updateState, _) => _AboutYoursSheet(
          officialWebsiteUrl: _officialWebsiteUrl,
          githubRepositoryUrl: _githubRepositoryUrl,
          showUpdateCheck: _appUpdateService.supportsUpdateCheck,
          updateState: updateState,
          onCheckUpdate: _checkForUpdatesManually,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(onAbout: _showAboutYoursSheet),
      ),
    );
  }

  Future<void> _checkForUpdatesManually() async {
    final result = await _appUpdateService.checkForUpdates();
    if (!mounted) {
      return;
    }
    if (result.status == AppUpdateStatus.upToDate) {
      _showMessage(context.l10n.profileUpToDate);
    } else if (result.status == AppUpdateStatus.failed) {
      _showMessage(context.l10n.profileUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(kGutter, kGutter, kGutter, 28),
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
            latestBackupName: _latestBackup == null ? null : _fileName(_latestBackup!.path),
            latestVaultPath: _latestVaultDirectory?.path,
            serverConfigured: _serverBackupSettings.isConfigured,
            iCloudStatus: _iCloudStatus,
            iCloudActivityMessage: _iCloudActivityMessage,
            serverSyncStatus: _serverSyncStatus,
            serverStatusError: _serverStatusError,
            pendingSyncCount: _pendingSyncCount,
            onExportVault: _exportYoursVault,
            onImportVaultInbox: _importYoursVaultInbox,
            onCreateBackup: _createBackup,
            onExportBackupToICloud: _exportLatestBackupToICloudDrive,
            onRestoreBackupFromICloud: _confirmRestoreFromICloud,
            onRestoreBackup: _confirmRestore,
            onEditServer: _showServerBackupSettingsSheet,
            onCheckServer: _checkServerSyncStatus,
            onSyncServer: _syncPendingChangesToServer,
            onCopyServerDiagnostics: _copyServerDiagnostics,
          ),
          const SizedBox(height: 16),

          _SettingsCard(onTap: _openSettings),
        ],
      ),
    );
  }
}

class _DataManagementSnapshot {
  final String? latestBackupName;
  final String? latestVaultPath;
  final bool serverConfigured;
  final ICloudDriveStatus? iCloudStatus;
  final String? iCloudActivityMessage;
  final ServerSyncStatus? serverSyncStatus;
  final String? serverStatusError;
  final int? pendingSyncCount;

  const _DataManagementSnapshot({
    this.latestBackupName,
    this.latestVaultPath,
    this.serverConfigured = false,
    this.iCloudStatus,
    this.iCloudActivityMessage,
    this.serverSyncStatus,
    this.serverStatusError,
    this.pendingSyncCount,
  });
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: palette.fg,
          height: 1.08,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.settings_outlined, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settingsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.settingsDescription,
                      style: TextStyle(fontSize: 13, color: palette.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'YS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: palette.fg,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.profileLocalFirstRecord,
                  style: TextStyle(
                    fontSize: 14,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  final ValueNotifier<_DataManagementSnapshot> snapshotNotifier;
  final bool busy;
  final String? latestBackupName;
  final String? latestVaultPath;
  final bool serverConfigured;
  final ICloudDriveStatus? iCloudStatus;
  final String? iCloudActivityMessage;
  final ServerSyncStatus? serverSyncStatus;
  final String? serverStatusError;
  final int? pendingSyncCount;
  final Future<void> Function() onExportVault;
  final Future<void> Function() onImportVaultInbox;
  final Future<void> Function() onCreateBackup;
  final Future<void> Function() onExportBackupToICloud;
  final Future<void> Function() onRestoreBackupFromICloud;
  final Future<void> Function() onRestoreBackup;
  final Future<void> Function() onEditServer;
  final Future<void> Function() onCheckServer;
  final Future<void> Function() onSyncServer;
  final Future<void> Function() onCopyServerDiagnostics;

  const _DataManagementCard({
    required this.snapshotNotifier,
    required this.busy,
    required this.latestBackupName,
    required this.latestVaultPath,
    required this.serverConfigured,
    required this.iCloudStatus,
    required this.iCloudActivityMessage,
    required this.serverSyncStatus,
    required this.serverStatusError,
    required this.pendingSyncCount,
    required this.onExportVault,
    required this.onImportVaultInbox,
    required this.onCreateBackup,
    required this.onExportBackupToICloud,
    required this.onRestoreBackupFromICloud,
    required this.onRestoreBackup,
    required this.onEditServer,
    required this.onCheckServer,
    required this.onSyncServer,
    required this.onCopyServerDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        snapshotNotifier.value = _DataManagementSnapshot(
          latestBackupName: latestBackupName,
          latestVaultPath: latestVaultPath,
          serverConfigured: serverConfigured,
          iCloudStatus: iCloudStatus,
          iCloudActivityMessage: iCloudActivityMessage,
          serverSyncStatus: serverSyncStatus,
          serverStatusError: serverStatusError,
          pendingSyncCount: pendingSyncCount,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _DataManagementPage(
              snapshotListenable: snapshotNotifier,
              onExportVault: onExportVault,
              onImportVaultInbox: onImportVaultInbox,
              onCreateBackup: onCreateBackup,
              onExportBackupToICloud: onExportBackupToICloud,
              onRestoreBackupFromICloud: onRestoreBackupFromICloud,
              onRestoreBackup: onRestoreBackup,
              onEditServer: onEditServer,
              onCheckServer: onCheckServer,
              onSyncServer: onSyncServer,
              onCopyServerDiagnostics: onCopyServerDiagnostics,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.inventory_2_outlined, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dataManagement,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: '.AppleSystemUIFont',
                      fontFamilyFallback: const ['PingFang SC', 'Heiti SC', 'Microsoft YaHei'],
                      color: palette.fg,
                    ),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.profileProcessingData,
                      style: TextStyle(fontSize: 13, color: palette.muted, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _DataManagementPage extends StatefulWidget {
  final ValueListenable<_DataManagementSnapshot> snapshotListenable;
  final Future<void> Function() onExportVault;
  final Future<void> Function() onImportVaultInbox;
  final Future<void> Function() onCreateBackup;
  final Future<void> Function() onExportBackupToICloud;
  final Future<void> Function() onRestoreBackupFromICloud;
  final Future<void> Function() onRestoreBackup;
  final Future<void> Function() onEditServer;
  final Future<void> Function() onCheckServer;
  final Future<void> Function() onSyncServer;
  final Future<void> Function() onCopyServerDiagnostics;

  const _DataManagementPage({
    required this.snapshotListenable,
    required this.onExportVault,
    required this.onImportVaultInbox,
    required this.onCreateBackup,
    required this.onExportBackupToICloud,
    required this.onRestoreBackupFromICloud,
    required this.onRestoreBackup,
    required this.onEditServer,
    required this.onCheckServer,
    required this.onSyncServer,
    required this.onCopyServerDiagnostics,
  });

  @override
  State<_DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<_DataManagementPage> {
  bool _running = false;

  bool get _busy => _running;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _running = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  String _shortPath(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length <= 2) {
      return normalized;
    }
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }

  String _serverDetail(BuildContext context, _DataManagementSnapshot snapshot) {
    if (snapshot.serverStatusError != null) {
      return context.l10n.profileServerConnectionFailed(
        snapshot.serverStatusError!,
      );
    }
    final status = snapshot.serverSyncStatus;
    if (status != null && status.available) {
      final backupText = status.latestBackupAt == null
          ? context.l10n.profileNoServerSnapshot
          : context.l10n.profileRecentSnapshot(_dateText(status.latestBackupAt!));
      return context.l10n.profileServerDetail(backupText, status.eventCount, status.latestCursor);
    }
    return snapshot.serverConfigured
        ? context.l10n.profileServerConfiguredHint
        : context.l10n.profileServerNotConfigured;
  }

  String _iCloudDetail(BuildContext context, _DataManagementSnapshot snapshot) {
    final activity = snapshot.iCloudActivityMessage;
    if (activity != null && activity.trim().isNotEmpty) {
      return activity;
    }
    final status = snapshot.iCloudStatus;
    if (status == null) {
      return context.l10n.profileCheckingICloud;
    }
    return switch (status.state) {
      'available' => context.l10n.profileICloudAvailable,
      'signedOut' => context.l10n.profileICloudSignedOut,
      'containerUnavailable' => context.l10n.profileICloudContainerUnavailable,
      'unsupported' => context.l10n.profileICloudUnsupported,
      _ => context.l10n.profileICloudUnknown,
    };
  }

  String _dateText(DateTime value) {
    return '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_DataManagementSnapshot>(
      valueListenable: widget.snapshotListenable,
      builder: (context, snapshot, _) {
        final palette = context.yoursPalette;
        final pendingCount = snapshot.pendingSyncCount;
        return Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                          child: Icon(Icons.chevron_left, color: palette.fg, size: 30),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.dataManagement,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: '.AppleSystemUIFont',
                                fontFamilyFallback: const [
                                  'PingFang SC',
                                  'Heiti SC',
                                  'Microsoft YaHei',
                                ],
                                color: palette.fg,
                                height: 1.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StatusPanel(
                    latestBackupName: snapshot.latestBackupName,
                    pendingSyncCount: pendingCount,
                    serverConfigured: snapshot.serverConfigured,
                    busy: _busy,
                  ),
                  const SizedBox(height: 14),
                  _DataSection(
                    icon: Icons.folder_open_outlined,
                    title: context.l10n.yoursVaultName,
                    detail: snapshot.latestVaultPath == null
                        ? context.l10n.profileVaultPathPending
                        : _shortPath(snapshot.latestVaultPath!),
                    actions: [
                      YoursResponsiveActionButton(
                        label: context.l10n.profileExportVault,
                        icon: Icons.ios_share_outlined,
                        onTap: _busy ? null : () => _run(widget.onExportVault),
                      ),
                      YoursResponsiveActionButton(
                        label: context.l10n.profileImportInbox,
                        icon: Icons.move_to_inbox_outlined,
                        onTap: _busy ? null : () => _run(widget.onImportVaultInbox),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DataSection(
                    icon: Icons.archive_outlined,
                    title: context.l10n.backupPackage,
                    detail: snapshot.latestBackupName == null
                        ? context.l10n.profileBackupDescription
                        : context.l10n.profileLatestBackup(snapshot.latestBackupName!),
                    actions: [
                      YoursResponsiveActionButton(
                        label: _busy
                            ? context.l10n.profileProcessing
                            : context.l10n.profileCreateExport,
                        icon: Icons.ios_share_outlined,
                        onTap: _busy ? null : () => _run(widget.onCreateBackup),
                      ),
                      YoursResponsiveActionButton(
                        label: context.l10n.profileRestoreFromFile,
                        icon: Icons.file_open_outlined,
                        onTap: _busy ? null : () => _run(widget.onRestoreBackup),
                        danger: true,
                      ),
                    ],
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 14),
                    _DataSection(
                      icon: snapshot.iCloudStatus?.available == true
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      title: context.l10n.icloudDrive,
                      detail: _iCloudDetail(context, snapshot),
                      actions: [
                        YoursResponsiveActionButton(
                          label: context.l10n.profileExportBackup,
                          icon: Icons.cloud_upload_outlined,
                          onTap: _busy || snapshot.iCloudStatus?.available != true
                              ? null
                              : () => _run(widget.onExportBackupToICloud),
                        ),
                        YoursResponsiveActionButton(
                          label: context.l10n.profileExportVault,
                          icon: Icons.folder_copy_outlined,
                          onTap: _busy || snapshot.iCloudStatus?.available != true
                              ? null
                              : () => _run(widget.onExportVault),
                        ),
                        YoursResponsiveActionButton(
                          label: context.l10n.profileRestoreFromICloud,
                          icon: Icons.file_open_outlined,
                          onTap: _busy || snapshot.iCloudStatus?.available != true
                              ? null
                              : () => _run(widget.onRestoreBackupFromICloud),
                          danger: true,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DataSection(
                    icon: snapshot.serverConfigured
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    title: context.l10n.serverSync,
                    detail: _serverDetail(context, snapshot),
                    actions: [
                      YoursResponsiveActionButton(
                        label: context.l10n.commonSettings,
                        icon: Icons.tune_outlined,
                        onTap: _busy ? null : () => _run(widget.onEditServer),
                      ),
                      YoursResponsiveActionButton(
                        label: context.l10n.commonTest,
                        icon: Icons.health_and_safety_outlined,
                        onTap: _busy || !snapshot.serverConfigured
                            ? null
                            : () => _run(widget.onCheckServer),
                      ),
                      if (snapshot.serverSyncStatus != null || snapshot.serverStatusError != null)
                        YoursResponsiveActionButton(
                          label: context.l10n.profileCopyDiagnostics,
                          icon: Icons.content_copy_outlined,
                          onTap: _busy || !snapshot.serverConfigured
                              ? null
                              : () => _run(widget.onCopyServerDiagnostics),
                        ),
                      YoursResponsiveActionButton(
                        label: context.l10n.commonSyncNow,
                        icon: Icons.sync_outlined,
                        onTap: _busy || !snapshot.serverConfigured
                            ? null
                            : () => _run(widget.onSyncServer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final String? latestBackupName;
  final int? pendingSyncCount;
  final bool serverConfigured;
  final bool busy;

  const _StatusPanel({
    required this.latestBackupName,
    required this.pendingSyncCount,
    required this.serverConfigured,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  busy ? Icons.hourglass_top_rounded : Icons.shield_outlined,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busy
                          ? context.l10n.profileProcessingDataShort
                          : context.l10n.profileLocalDataSafety,
                      style: TextStyle(
                        color: palette.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatusPill(
                  label: context.l10n.backupPackage,
                  value: latestBackupName == null
                      ? context.l10n.profileNotCreated
                      : context.l10n.profileAvailable,
                  active: latestBackupName != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusPill(
                  label: context.l10n.profileManualExport,
                  value: context.l10n.profileFile,
                  active: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusPill(
                  label: context.l10n.commonPendingSync,
                  value: pendingSyncCount == null
                      ? context.l10n.profileReading
                      : context.l10n.profilePendingCount(pendingSyncCount!),
                  active: (pendingSyncCount ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusPill(
                  label: context.l10n.profileServer,
                  value: serverConfigured
                      ? context.l10n.profileConfigured
                      : context.l10n.profileNotConfigured,
                  active: serverConfigured,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const _StatusPill({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? palette.accentSoft : palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? palette.accent.withValues(alpha: 0.18) : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: active ? palette.accent : palette.fg,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final List<YoursResponsiveActionButton> actions;

  const _DataSection({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: palette.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              detail,
              style: TextStyle(
                color: palette.fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < actions.length; index++) ...[
            SizedBox(width: double.infinity, child: actions[index]),
            if (index != actions.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AboutYoursSheet extends StatelessWidget {
  final String officialWebsiteUrl;
  final String githubRepositoryUrl;
  final bool showUpdateCheck;
  final AppUpdateState updateState;
  final Future<void> Function() onCheckUpdate;

  const _AboutYoursSheet({
    required this.officialWebsiteUrl,
    required this.githubRepositoryUrl,
    required this.showUpdateCheck,
    required this.updateState,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.aboutYours,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: palette.fg,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.fg),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  _AboutInfoRow(
                    icon: Icons.language_outlined,
                    label: context.l10n.officialWebsite,
                    url: officialWebsiteUrl,
                  ),
                  Divider(height: 1, color: palette.border),
                  _AboutInfoRow(
                    icon: Icons.code_outlined,
                    label: context.l10n.githubRepository,
                    url: githubRepositoryUrl,
                  ),
                  if (showUpdateCheck) ...[
                    Divider(height: 1, color: palette.border),
                    _AboutUpdateRow(
                      updateState: updateState,
                      onCheckUpdate: onCheckUpdate,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutUpdateRow extends StatelessWidget {
  final AppUpdateState updateState;
  final Future<void> Function() onCheckUpdate;

  const _AboutUpdateRow({
    required this.updateState,
    required this.onCheckUpdate,
  });

  String _detailText(BuildContext context) {
    if (updateState.hasUpdate) {
      return context.l10n.profileNewVersionDownload(updateState.latestVersionLabel);
    }
    if (updateState.isChecking) {
      return context.l10n.profileCheckingUpdates;
    }
    if (updateState.status == AppUpdateStatus.upToDate) {
      return context.l10n.profileUpToDate;
    }
    if (updateState.status == AppUpdateStatus.failed) {
      return context.l10n.profileUpdateFailed;
    }
    return context.l10n.profileAndroidUpdate;
  }

  Future<void> _handleTap(BuildContext context) async {
    if (updateState.hasUpdate) {
      await _openExternalUrl(context, updateState.downloadUrl);
      return;
    }
    await onCheckUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return InkWell(
      onTap: updateState.isChecking ? null : () => _handleTap(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.system_update_alt, color: palette.accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.profileCheckUpdates,
                      style: TextStyle(
                        color: palette.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _detailText(context),
                      style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              updateState.hasUpdate ? Icons.open_in_new : Icons.refresh,
              color: palette.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  Future<void> _open(BuildContext context) async {
    await _openExternalUrl(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: palette.accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _open(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: palette.accent, width: 1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerBackupSettingsSheet extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController tokenController;

  const _ServerBackupSettingsSheet({
    required this.urlController,
    required this.tokenController,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.profileServerSettings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: palette.fg,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.fg),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
              cursorColor: palette.accent,
              decoration: InputDecoration(
                labelText: context.l10n.profileServerAddress,
                hintText: 'https://backup.example.com', // l10n-ignore-hardcoded
                labelStyle: TextStyle(color: palette.muted),
                hintStyle: TextStyle(color: palette.muted),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              obscureText: true,
              style: TextStyle(color: palette.fg, fontWeight: FontWeight.w700),
              cursorColor: palette.accent,
              decoration: InputDecoration(
                labelText: context.l10n.profileApiKeyOptional,
                hintText: context.l10n.profileApiKeyHint,
                labelStyle: TextStyle(color: palette.muted),
                hintStyle: TextStyle(color: palette.muted),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const ServerBackupSettings(baseUrl: '', apiToken: ''),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: palette.danger,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(context.l10n.profileClear),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        ServerBackupSettings(
                          baseUrl: urlController.text.trim(),
                          apiToken: tokenController.text.trim(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(context.l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

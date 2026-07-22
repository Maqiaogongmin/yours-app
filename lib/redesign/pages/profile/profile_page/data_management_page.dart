part of '../profile_page.dart';

@visibleForTesting
class YoursDataManagementPage extends StatefulWidget {
  final ValueListenable<YoursDataManagementSnapshot> snapshotListenable;
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

  const YoursDataManagementPage({
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
  State<YoursDataManagementPage> createState() => _YoursDataManagementPageState();
}

class _YoursDataManagementPageState extends State<YoursDataManagementPage> {
  _DataManagementOperation? _runningOperation;

  bool get _busy => _runningOperation != null;

  bool _isRunning(_DataManagementOperation operation) => _runningOperation == operation;

  Future<void> _run(
    _DataManagementOperation operation,
    Future<void> Function() action,
  ) async {
    if (_busy) {
      return;
    }
    setState(() => _runningOperation = operation);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _runningOperation = null);
      }
    }
  }

  String _actionLabel(
    BuildContext context,
    _DataManagementOperation operation,
    String label,
  ) {
    return _isRunning(operation) ? context.l10n.profileProcessing : label;
  }

  String? _statusProcessingTitle(BuildContext context) {
    return switch (_runningOperation) {
      _DataManagementOperation.vaultExport => context.l10n.profileExportingVault,
      null => null,
      _ => context.l10n.profileProcessingDataShort,
    };
  }

  String _vaultDetail(BuildContext context, YoursDataManagementSnapshot snapshot) {
    final exportedAt = snapshot.latestVaultExportedAt;
    if (exportedAt == null) {
      return context.l10n.profileVaultNotExported;
    }
    return context.l10n.profileLastVaultExport(_dateText(exportedAt));
  }

  String _backupDetail(BuildContext context, YoursDataManagementSnapshot snapshot) {
    final updatedAt = snapshot.latestBackupUpdatedAt;
    if (updatedAt == null) {
      return context.l10n.profileBackupNotCreated;
    }
    return context.l10n.profileLastBackup(_dateText(updatedAt));
  }

  String? _backupNote(BuildContext context) {
    if (Platform.isAndroid) {
      return context.l10n.profileBackupAndroidLocation;
    }
    return context.l10n.profileBackupPlaintextWarning;
  }

  String _serverDetail(BuildContext context, YoursDataManagementSnapshot snapshot) {
    final serverStatusError = snapshot.serverStatusError;
    if (serverStatusError != null) {
      return context.l10n.profileServerConnectionFailed(
        serverStatusError.localizedDetail(context),
      );
    }
    final status = snapshot.serverSyncStatus;
    if (status != null && status.available) {
      return status.latestBackupAt == null
          ? context.l10n.profileNoServerSnapshot
          : context.l10n.profileRecentSnapshot(_dateText(status.latestBackupAt!));
    }
    return snapshot.serverConfigured
        ? context.l10n.profileServerConfiguredHint
        : context.l10n.profileServerNotConfigured;
  }

  String _iCloudDetail(BuildContext context, YoursDataManagementSnapshot snapshot) {
    final activity = snapshot.iCloudActivity;
    if (activity != null) {
      return activity.localizedText(context);
    }
    final status = snapshot.iCloudStatus;
    if (status == null) {
      return context.l10n.profileCheckingICloud;
    }
    return switch (status.state) {
      'available' =>
        snapshot.latestBackupUpdatedAt == null
            ? context.l10n.profileBackupNotCreated
            : context.l10n.profileRecentBackupExport(_dateText(snapshot.latestBackupUpdatedAt!)),
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
    return ValueListenableBuilder<YoursDataManagementSnapshot>(
      valueListenable: widget.snapshotListenable,
      builder: (context, snapshot, _) {
        final pendingCount = snapshot.pendingSyncCount;
        return YoursPageScaffold(
          title: context.l10n.dataManagement,
          onClose: () => Navigator.pop(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPanel(
                latestBackupName: snapshot.latestBackupName,
                pendingSyncCount: pendingCount,
                serverConfigured: snapshot.serverConfigured,
                processingTitle: _statusProcessingTitle(context),
              ),
              const SizedBox(height: 14),
              _DataSection(
                icon: Icons.folder_open_outlined,
                title: context.l10n.yoursVaultName,
                detail: _vaultDetail(context, snapshot),
                actions: [
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.vaultExport,
                      context.l10n.profileExportVault,
                    ),
                    icon: Icons.ios_share_outlined,
                    busy: _isRunning(_DataManagementOperation.vaultExport),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy,
                    onTap: () => _run(_DataManagementOperation.vaultExport, widget.onExportVault),
                  ),
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.vaultImport,
                      context.l10n.profileImportInbox,
                    ),
                    icon: Icons.move_to_inbox_outlined,
                    busy: _isRunning(_DataManagementOperation.vaultImport),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy,
                    onTap: () =>
                        _run(_DataManagementOperation.vaultImport, widget.onImportVaultInbox),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DataSection(
                icon: Icons.archive_outlined,
                title: context.l10n.backupPackage,
                detail: _backupDetail(context, snapshot),
                note: _backupNote(context),
                actions: [
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.backupCreate,
                      isHarmonyOS
                          ? context.l10n.profileCreateBackup
                          : context.l10n.profileCreateExport,
                    ),
                    icon: isHarmonyOS ? Icons.archive_outlined : Icons.ios_share_outlined,
                    busy: _isRunning(_DataManagementOperation.backupCreate),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy,
                    onTap: () => _run(_DataManagementOperation.backupCreate, widget.onCreateBackup),
                  ),
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.backupRestore,
                      context.l10n.profileRestoreFromFile,
                    ),
                    icon: Icons.file_open_outlined,
                    tone: YoursTone.danger,
                    busy: _isRunning(_DataManagementOperation.backupRestore),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy,
                    onTap: () =>
                        _run(_DataManagementOperation.backupRestore, widget.onRestoreBackup),
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
                    YoursManagementAction(
                      label: _actionLabel(
                        context,
                        _DataManagementOperation.iCloudBackupExport,
                        context.l10n.profileExportBackup,
                      ),
                      icon: Icons.cloud_upload_outlined,
                      busy: _isRunning(_DataManagementOperation.iCloudBackupExport),
                      density: YoursComponentDensity.compact,
                      enabled: !_busy && snapshot.iCloudStatus?.available == true,
                      onTap: () => _run(
                        _DataManagementOperation.iCloudBackupExport,
                        widget.onExportBackupToICloud,
                      ),
                    ),
                    YoursManagementAction(
                      label: _actionLabel(
                        context,
                        _DataManagementOperation.vaultExport,
                        context.l10n.profileExportVault,
                      ),
                      icon: Icons.folder_copy_outlined,
                      busy: _isRunning(_DataManagementOperation.vaultExport),
                      density: YoursComponentDensity.compact,
                      enabled: !_busy && snapshot.iCloudStatus?.available == true,
                      onTap: () => _run(_DataManagementOperation.vaultExport, widget.onExportVault),
                    ),
                    YoursManagementAction(
                      label: _actionLabel(
                        context,
                        _DataManagementOperation.iCloudBackupRestore,
                        context.l10n.profileRestoreFromICloud,
                      ),
                      icon: Icons.file_open_outlined,
                      tone: YoursTone.danger,
                      busy: _isRunning(_DataManagementOperation.iCloudBackupRestore),
                      density: YoursComponentDensity.compact,
                      enabled: !_busy && snapshot.iCloudStatus?.available == true,
                      onTap: () => _run(
                        _DataManagementOperation.iCloudBackupRestore,
                        widget.onRestoreBackupFromICloud,
                      ),
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
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.serverSettings,
                      context.l10n.commonSettings,
                    ),
                    icon: Icons.tune_outlined,
                    busy: _isRunning(_DataManagementOperation.serverSettings),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy,
                    onTap: () => _run(_DataManagementOperation.serverSettings, widget.onEditServer),
                  ),
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.serverCheck,
                      context.l10n.commonTest,
                    ),
                    icon: Icons.health_and_safety_outlined,
                    busy: _isRunning(_DataManagementOperation.serverCheck),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy && snapshot.serverConfigured,
                    onTap: () => _run(_DataManagementOperation.serverCheck, widget.onCheckServer),
                  ),
                  if (snapshot.serverSyncStatus != null || snapshot.serverStatusError != null)
                    YoursManagementAction(
                      label: _actionLabel(
                        context,
                        _DataManagementOperation.serverDiagnostics,
                        context.l10n.profileCopyDiagnostics,
                      ),
                      icon: Icons.content_copy_outlined,
                      busy: _isRunning(_DataManagementOperation.serverDiagnostics),
                      density: YoursComponentDensity.compact,
                      enabled: !_busy && snapshot.serverConfigured,
                      onTap: () => _run(
                        _DataManagementOperation.serverDiagnostics,
                        widget.onCopyServerDiagnostics,
                      ),
                    ),
                  YoursManagementAction(
                    label: _actionLabel(
                      context,
                      _DataManagementOperation.serverSync,
                      context.l10n.commonSyncNow,
                    ),
                    icon: Icons.sync_outlined,
                    busy: _isRunning(_DataManagementOperation.serverSync),
                    density: YoursComponentDensity.compact,
                    enabled: !_busy && snapshot.serverConfigured,
                    onTap: () => _run(_DataManagementOperation.serverSync, widget.onSyncServer),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _DataManagementOperation {
  vaultExport,
  vaultImport,
  backupCreate,
  backupRestore,
  iCloudBackupExport,
  iCloudBackupRestore,
  serverSettings,
  serverCheck,
  serverDiagnostics,
  serverSync,
}

class _StatusPanel extends StatelessWidget {
  final String? latestBackupName;
  final int? pendingSyncCount;
  final bool serverConfigured;
  final String? processingTitle;

  const _StatusPanel({
    required this.latestBackupName,
    required this.pendingSyncCount,
    required this.serverConfigured,
    required this.processingTitle,
  });

  @override
  Widget build(BuildContext context) {
    return YoursAsyncStatusPanel(
      title: processingTitle ?? context.l10n.profileLocalDataSafety,
      busy: processingTitle != null,
      layout: YoursStatusPanelLayout.compactGrid,
      items: [
        (
          context.l10n.backupPackage,
          latestBackupName == null ? context.l10n.profileNotCreated : context.l10n.profileAvailable,
          latestBackupName == null ? YoursTone.muted : YoursTone.accent,
        ),
        (context.l10n.profileManualExport, context.l10n.profileFile, YoursTone.accent),
        (
          context.l10n.commonPendingSync,
          pendingSyncCount == null
              ? context.l10n.profileReading
              : context.l10n.profilePendingCount(pendingSyncCount!),
          (pendingSyncCount ?? 0) > 0 ? YoursTone.warning : YoursTone.muted,
        ),
        (
          context.l10n.profileServer,
          serverConfigured ? context.l10n.profileConfigured : context.l10n.profileNotConfigured,
          serverConfigured ? YoursTone.accent : YoursTone.muted,
        ),
      ],
    );
  }
}

class _DataSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String? note;
  final List<YoursManagementAction> actions;

  const _DataSection({
    required this.icon,
    required this.title,
    required this.detail,
    this.note,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoursIconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.yoursText(YoursTextRole.cardTitle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          YoursNotePanel(
            child: Text(
              detail,
              style: context.yoursText(YoursTextRole.body).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: context
                  .yoursText(YoursTextRole.bodyMuted)
                  .copyWith(
                    color: context.yoursPalette.muted,
                    height: 1.3,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          YoursActionGroup(children: actions),
        ],
      ),
    );
  }
}

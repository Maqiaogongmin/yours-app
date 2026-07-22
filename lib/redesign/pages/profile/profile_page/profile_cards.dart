part of '../profile_page.dart';

@visibleForTesting
class YoursDataManagementSnapshot {
  final String? latestBackupName;
  final DateTime? latestBackupUpdatedAt;
  final String? latestVaultPath;
  final DateTime? latestVaultExportedAt;
  final bool serverConfigured;
  final ICloudDriveStatus? iCloudStatus;
  final YoursDataManagementActivity? iCloudActivity;
  final ServerSyncStatus? serverSyncStatus;
  final YoursDataManagementError? serverStatusError;
  final int? pendingSyncCount;

  const YoursDataManagementSnapshot({
    this.latestBackupName,
    this.latestBackupUpdatedAt,
    this.latestVaultPath,
    this.latestVaultExportedAt,
    this.serverConfigured = false,
    this.iCloudStatus,
    this.iCloudActivity,
    this.serverSyncStatus,
    this.serverStatusError,
    this.pendingSyncCount,
  });
}

@visibleForTesting
enum YoursDataManagementActivityKind {
  recentVaultExport,
  recentVaultExportFailed,
  recentBackupExport,
  recentBackupExportFailed,
  recentRestoreFailed,
  restoringICloud,
  recentICloudRestore,
}

@visibleForTesting
class YoursDataManagementActivity {
  const YoursDataManagementActivity._({
    required this.kind,
    this.fileName,
    this.error,
  });

  final YoursDataManagementActivityKind kind;
  final String? fileName;
  final YoursDataManagementError? error;

  const YoursDataManagementActivity.recentVaultExport(String fileName)
    : this._(kind: YoursDataManagementActivityKind.recentVaultExport, fileName: fileName);

  const YoursDataManagementActivity.recentVaultExportFailed(YoursDataManagementError error)
    : this._(kind: YoursDataManagementActivityKind.recentVaultExportFailed, error: error);

  const YoursDataManagementActivity.recentBackupExport(String fileName)
    : this._(kind: YoursDataManagementActivityKind.recentBackupExport, fileName: fileName);

  const YoursDataManagementActivity.recentBackupExportFailed(YoursDataManagementError error)
    : this._(kind: YoursDataManagementActivityKind.recentBackupExportFailed, error: error);

  const YoursDataManagementActivity.recentRestoreFailed(YoursDataManagementError error)
    : this._(kind: YoursDataManagementActivityKind.recentRestoreFailed, error: error);

  const YoursDataManagementActivity.restoringICloud()
    : this._(kind: YoursDataManagementActivityKind.restoringICloud);

  const YoursDataManagementActivity.recentICloudRestore(String fileName)
    : this._(kind: YoursDataManagementActivityKind.recentICloudRestore, fileName: fileName);

  String localizedText(BuildContext context) {
    return switch (kind) {
      YoursDataManagementActivityKind.recentVaultExport => context.l10n.profileRecentVaultExport(
        fileName ?? '',
      ),
      YoursDataManagementActivityKind.recentVaultExportFailed =>
        context.l10n.profileRecentVaultExportFailed(_localizedErrorDetail(context)),
      YoursDataManagementActivityKind.recentBackupExport => context.l10n.profileRecentBackupExport(
        fileName ?? '',
      ),
      YoursDataManagementActivityKind.recentBackupExportFailed =>
        context.l10n.profileRecentExportFailed(_localizedErrorDetail(context)),
      YoursDataManagementActivityKind.recentRestoreFailed =>
        context.l10n.profileRecentRestoreFailed(_localizedErrorDetail(context)),
      YoursDataManagementActivityKind.restoringICloud => context.l10n.profileRestoringICloud,
      YoursDataManagementActivityKind.recentICloudRestore =>
        context.l10n.profileRecentICloudRestore(fileName ?? ''),
    };
  }

  String _localizedErrorDetail(BuildContext context) {
    return (error ?? const YoursDataManagementError.text(null)).localizedDetail(context);
  }
}

@visibleForTesting
class YoursDataManagementError {
  const YoursDataManagementError.raw(this.error) : fallbackText = null;

  const YoursDataManagementError.text(this.fallbackText) : error = null;

  final Object? error;
  final String? fallbackText;

  String localizedDetail(BuildContext context) {
    final rawError = error;
    if (rawError != null) {
      final rawText = '$rawError';
      if (rawText.contains('connection was closed') || rawText.contains('Tried to send Request')) {
        return context.l10n.profileDatabasePreparing;
      }
      return localizedErrorDetail(context, rawError);
    }
    return fallbackText ?? context.l10n.commonUnknownError;
  }
}

String _dataManagementDateText(DateTime value) {
  return '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return YoursPageHeader(title: title);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return YoursListActionCard(
      key: const ValueKey('profile-settings-entry'),
      title: context.l10n.settingsTitle,
      subtitle: context.l10n.settingsDescription,
      leading: const YoursIconBadge(icon: Icons.settings_outlined),
      onTap: onTap,
      minHeight: 84,
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return YoursSurfaceCard(
      key: const ValueKey('profile-account-card'),
      shadow: true,
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
            child: Text(
              'YS',
              style: context
                  .yoursText(YoursTextRole.body)
                  .copyWith(
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
                  style: context.yoursText(YoursTextRole.cardTitle),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.profileLocalFirstRecord,
                  style: context.yoursText(YoursTextRole.bodyMuted),
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
  final ValueNotifier<YoursDataManagementSnapshot> snapshotNotifier;
  final bool busy;
  final String? latestBackupName;
  final DateTime? latestBackupUpdatedAt;
  final String? latestVaultPath;
  final DateTime? latestVaultExportedAt;
  final bool serverConfigured;
  final ICloudDriveStatus? iCloudStatus;
  final YoursDataManagementActivity? iCloudActivity;
  final ServerSyncStatus? serverSyncStatus;
  final YoursDataManagementError? serverStatusError;
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
    required this.latestBackupUpdatedAt,
    required this.latestVaultPath,
    required this.latestVaultExportedAt,
    required this.serverConfigured,
    required this.iCloudStatus,
    required this.iCloudActivity,
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
    return YoursListActionCard(
      key: const ValueKey('profile-data-entry'),
      title: context.l10n.dataManagement,
      subtitle: busy ? context.l10n.profileProcessingData : null,
      leading: const YoursIconBadge(icon: Icons.inventory_2_outlined),
      shadow: true,
      minHeight: 84,
      busy: busy,
      onTap: () {
        snapshotNotifier.value = YoursDataManagementSnapshot(
          latestBackupName: latestBackupName,
          latestBackupUpdatedAt: latestBackupUpdatedAt,
          latestVaultPath: latestVaultPath,
          latestVaultExportedAt: latestVaultExportedAt,
          serverConfigured: serverConfigured,
          iCloudStatus: iCloudStatus,
          iCloudActivity: iCloudActivity,
          serverSyncStatus: serverSyncStatus,
          serverStatusError: serverStatusError,
          pendingSyncCount: pendingSyncCount,
        );
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => YoursDataManagementPage(
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
    );
  }
}

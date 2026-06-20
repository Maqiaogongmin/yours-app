part of '../profile_page.dart';

extension _ProfilePageBackupActions on _ProfilePageActions {
  Future<void> createBackup() async {
    setState(() => state._busy = true);
    try {
      final result = await state._backupService.createBackup();
      if (!state.mounted) {
        return;
      }
      setState(() {
        state._latestBackup = result.file;
        state._latestBackupUpdatedAt = result.createdAt;
      });
      state._publishDataManagementSnapshot();
      await state._loadPendingSyncCount();
      if (!state.mounted) {
        return;
      }
      final l10n = state.context.l10n;
      await state._backupService.shareBackup(
        result.file,
        sharePositionOrigin: _sharePositionOrigin(),
        title: l10n.backupShareTitle,
        subject: l10n.backupShareSubject,
        text: l10n.backupShareText,
      );
      if (!state.mounted) {
        return;
      }
      _showMessage(state.context.l10n.profileBackupCreated(fileName(result.file.path)));
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      _showMessage(
        state.context.l10n.profileBackupFailed(localizedErrorDetail(state.context, error)),
      );
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }

  Future<void> exportLatestBackupToICloudDrive() async {
    setState(() => state._busy = true);
    try {
      final result = await state._backupService.exportLatestBackupToICloudDrive();
      await state._loadLatestBackup();
      await state._loadICloudStatus();
      if (!state.mounted) {
        return;
      }
      setState(
        () => state._iCloudActivity = YoursDataManagementActivity.recentBackupExport(
          fileName(result.path),
        ),
      );
      _showMessage(state.context.l10n.profileBackupExportedICloud(fileName(result.path)));
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      setState(
        () => state._iCloudActivity = YoursDataManagementActivity.recentBackupExportFailed(
          _dataManagementError(error),
        ),
      );
      final detail = localizedErrorDetail(state.context, error);
      _showMessage(state.context.l10n.profileICloudExportFailed(detail));
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }

  Future<void> confirmRestore() async {
    final File? picked;
    try {
      picked = await state._backupService.pickBackupFile();
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      _showMessage(
        state.context.l10n.profilePickBackupFailed(localizedErrorDetail(state.context, error)),
      );
      return;
    }
    if (!state.mounted) {
      return;
    }
    if (picked == null) {
      _showMessage(state.context.l10n.profilePickBackupCancelled);
      return;
    }
    final backup = picked;

    final confirmed = await showDialog<bool>(
      context: state.context,
      builder: (ctx) => AlertDialog(
        title: Text(state.context.l10n.profileRestoreBackupTitle),
        content: Text(state.context.l10n.profileRestoreBackupMessage(fileName(backup.path))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(state.context.l10n.commonRestore),
          ),
        ],
      ),
    );

    if (confirmed != true || !state.mounted) {
      return;
    }
    await _restoreBackupFile(backup);
  }

  Future<void> confirmRestoreFromICloud() async {
    final File? picked;
    try {
      picked = await state._backupService.pickICloudBackup();
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      setState(
        () => state._iCloudActivity = YoursDataManagementActivity.recentRestoreFailed(
          _dataManagementError(error),
        ),
      );
      state._publishDataManagementSnapshot();
      final detail = localizedErrorDetail(state.context, error);
      _showMessage(state.context.l10n.profilePickICloudBackupFailed(detail));
      return;
    }
    if (!state.mounted) {
      return;
    }
    if (picked == null) {
      _showMessage(state.context.l10n.profilePickICloudBackupCancelled);
      return;
    }
    final backup = picked;

    final confirmed = await showDialog<bool>(
      context: state.context,
      builder: (ctx) => AlertDialog(
        title: Text(state.context.l10n.profileRestoreICloudTitle),
        content: Text(state.context.l10n.profileRestoreBackupMessage(fileName(backup.path))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(state.context.l10n.commonRestore),
          ),
        ],
      ),
    );

    if (confirmed != true || !state.mounted) {
      return;
    }
    setState(() => state._iCloudActivity = const YoursDataManagementActivity.restoringICloud());
    state._publishDataManagementSnapshot();
    await _restoreBackupFile(
      backup,
      successMessagePrefix: state.context.l10n.profileICloudRestoreComplete,
    );
  }

  Future<void> _restoreBackupFile(
    File backup, {
    String? successMessagePrefix,
  }) async {
    setState(() => state._busy = true);
    try {
      final result = await state._backupService.restoreBackup(backup);
      if (!state.mounted) {
        return;
      }
      setState(() => state._latestBackup = result.source);
      await state._loadLatestBackup();
      if (!state.mounted) {
        return;
      }
      final l10n = state.context.l10n;
      state._publishDataManagementSnapshot();
      await showDialog<void>(
        context: state.context,
        builder: (ctx) => AlertDialog(
          title: Text(successMessagePrefix ?? l10n.profileRestoreComplete),
          content: Text(
            l10n.profileRestoreSummary(
              result.restoredFileCount,
              fileName(result.safetyBackup.path),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.profileAcknowledged),
            ),
          ],
        ),
      );
      RedesignDataRefresh.instance.notifyRestored();
      await state._loadLatestBackup();
      await state._loadPendingSyncCount();
      if ((successMessagePrefix ?? '').contains('iCloud')) {
        setState(
          () => state._iCloudActivity = YoursDataManagementActivity.recentICloudRestore(
            fileName(result.source.path),
          ),
        );
        state._publishDataManagementSnapshot();
      }
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      _showMessage(
        state.context.l10n.profileRestoreFailed(localizedErrorDetail(state.context, error)),
      );
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }
}

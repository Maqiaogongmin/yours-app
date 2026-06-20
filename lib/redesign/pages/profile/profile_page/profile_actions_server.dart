part of '../profile_page.dart';

extension _ProfilePageServerActions on _ProfilePageActions {
  Future<void> showServerBackupSettingsSheet() async {
    final urlController = TextEditingController(text: state._serverBackupSettings.baseUrl);
    final tokenController = TextEditingController(text: state._serverBackupSettings.apiToken);
    final saved = await showModalBottomSheet<ServerBackupSettings>(
      context: state.context,
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
    if (saved == null || !state.mounted) {
      return;
    }
    await state._backupService.saveServerBackupSettings(saved);
    if (!state.mounted) {
      return;
    }
    setState(() => state._serverBackupSettings = saved);
    state._publishDataManagementSnapshot();
    _showMessage(
      saved.isConfigured
          ? state.context.l10n.profileServerAddressSaved
          : state.context.l10n.profileServerAddressCleared,
    );
  }

  Future<void> syncPendingChangesToServer() async {
    final l10n = state.context.l10n;
    if (!state._serverBackupSettings.isConfigured) {
      _showMessage(l10n.profileConfigureServerFirst);
      return;
    }
    setState(() => state._busy = true);
    try {
      final result = await state._backupService.syncNowWithServer();
      if (!state.mounted) {
        return;
      }
      await _handleServerSmartSyncResult(result);
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      final detail = localizedErrorDetail(state.context, error);
      await state._loadPendingSyncCount();
      if (!state.mounted) {
        return;
      }
      _showMessage(l10n.profileServerSyncFailed(detail));
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }

  Future<void> _handleServerSmartSyncResult(ServerSmartSyncResult result) async {
    final l10n = state.context.l10n;
    switch (result.state) {
      case ServerSmartSyncState.synced:
        final sync = result.sync;
        if (sync == null) {
          _showMessage(l10n.profileServerSyncComplete);
          return;
        }
        setState(() => state._latestBackup = sync.backup.file);
        state._publishDataManagementSnapshot();
        await state._loadPendingSyncCount();
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
        await state._loadPendingSyncCount();
        await _refreshServerSyncStatus();
        _showMessage(
          l10n.profileServerSyncFailed(
            result.errorMessage ?? l10n.commonUnknownError,
          ),
        );
    }
  }

  Future<void> checkServerSyncStatus() async {
    if (!state._serverBackupSettings.isConfigured) {
      _showMessage(state.context.l10n.profileConfigureServerSyncFirst);
      return;
    }
    setState(() {
      state._busy = true;
      state._serverStatusError = null;
    });
    try {
      final status = await state._backupService.checkServerSyncStatus();
      if (!state.mounted) {
        return;
      }
      setState(() => state._serverSyncStatus = status);
      state._publishDataManagementSnapshot();
      _showMessage(
        state.context.l10n.profileServerAvailable(status.protocolVersion ?? 0, status.eventCount),
      );
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      final detail = localizedErrorDetail(state.context, error);
      setState(() => state._serverStatusError = _dataManagementError(error));
      state._publishDataManagementSnapshot();
      _showMessage(state.context.l10n.profileServerTestFailed(detail));
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }

  Future<void> _refreshServerSyncStatus() async {
    if (!state._serverBackupSettings.isConfigured) {
      return;
    }
    try {
      final status = await state._backupService.checkServerSyncStatus();
      if (!state.mounted) {
        return;
      }
      setState(() {
        state._serverSyncStatus = status;
        state._serverStatusError = null;
      });
      state._publishDataManagementSnapshot();
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      setState(() => state._serverStatusError = _dataManagementError(error));
      state._publishDataManagementSnapshot();
    }
  }

  Future<void> copyServerDiagnostics() async {
    try {
      final text = await state._backupService.serverDiagnosticsText();
      await Clipboard.setData(ClipboardData(text: text));
      if (!state.mounted) {
        return;
      }
      _showMessage(state.context.l10n.profileDiagnosticsCopied);
    } on Object catch (error) {
      await Clipboard.setData(
        ClipboardData(
          text:
              'Yours server sync diagnostics\n'
              'generatedAt: ${DateTime.now().toIso8601String()}\n'
              'copyFallbackError: $error\n',
        ),
      );
      if (!state.mounted) {
        return;
      }
      _showMessage(state.context.l10n.profileDiagnosticsFallbackCopied);
    }
  }

  Future<void> _confirmRestoreLatestServerBackup({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    if (!state._serverBackupSettings.isConfigured) {
      _showMessage(state.context.l10n.profileConfigureServerFirst);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: state.context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kRed),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !state.mounted) {
      return;
    }
    await _restoreLatestServerBackup();
  }

  Future<void> _restoreLatestServerBackup() async {
    setState(() => state._busy = true);
    try {
      final result = await state._backupService.restoreLatestServerBackup();
      if (!state.mounted) {
        return;
      }
      setState(() => state._latestBackup = result.source);
      state._publishDataManagementSnapshot();
      await showDialog<void>(
        context: state.context,
        builder: (ctx) => AlertDialog(
          title: Text(state.context.l10n.profileServerRestoreComplete),
          content: Text(
            state.context.l10n.profileRestoreSummary(
              result.restoredFileCount,
              fileName(result.safetyBackup.path),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(state.context.l10n.profileAcknowledged),
            ),
          ],
        ),
      );
      RedesignDataRefresh.instance.notifyRestored();
      await state._loadLatestBackup();
      await state._loadPendingSyncCount();
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      _showMessage(
        state.context.l10n.profileServerSnapshotRestoreFailed(
          localizedErrorDetail(state.context, error),
        ),
      );
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }
}

part of '../profile_page.dart';

extension _ProfilePageVaultActions on _ProfilePageActions {
  Future<void> exportYoursVault() async {
    setState(() => state._busy = true);
    try {
      final result = await state._vaultService.exportDefaultVault();
      if (!state.mounted) {
        return;
      }
      setState(() {
        state._latestVaultDirectory = result.directory;
        state._latestVaultExportedAt = result.exportedAt;
        if (Platform.isIOS) {
          state._iCloudActivity = YoursDataManagementActivity.recentVaultExport(
            fileName(result.directory.path),
          );
        }
      });
      state._publishDataManagementSnapshot();
      final l10n = state.context.l10n;
      _showMessage(
        Platform.isAndroid
            ? l10n.profileVaultExportAndroidSummary(
                result.planCount,
                result.workoutCount,
                result.exerciseCount,
              )
            : l10n.profileVaultExportSummary(
                result.planCount,
                result.workoutCount,
                result.exerciseCount,
              ),
      );
    } on Object catch (error) {
      if (!state.mounted) {
        return;
      }
      if (Platform.isIOS) {
        setState(
          () => state._iCloudActivity = YoursDataManagementActivity.recentVaultExportFailed(
            _dataManagementError(error),
          ),
        );
        state._publishDataManagementSnapshot();
      }
      _showMessage(state.context.l10n.profileVaultExportFailed(_friendlyDataError(error)));
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }

  Future<void> importYoursVaultInbox() async {
    final l10n = state.context.l10n;
    setState(() => state._busy = true);
    try {
      final result = await state._vaultService.importDefaultInbox();
      if (!state.mounted) {
        return;
      }
      if (result.importedPlans > 0 || result.importedExercises > 0) {
        RedesignDataRefresh.instance.notifyRestored();
        await state._loadPendingSyncCount();
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
      if (!state.mounted) {
        return;
      }
      _showMessage(
        state.context.l10n.profileVaultImportFailed(localizedErrorDetail(state.context, error)),
      );
    } finally {
      if (state.mounted) {
        setState(() => state._busy = false);
      }
    }
  }
}

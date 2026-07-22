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
        if (Platform.isIOS || isHarmonyOS) {
          state._iCloudActivity = YoursDataManagementActivity.recentVaultExport(
            _dataManagementDateText(result.exportedAt),
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
      if (Platform.isIOS || isHarmonyOS) {
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
      final result = await state._vaultService.importAutomaticInbox();
      if (!state.mounted) {
        return;
      }
      if (result.importedPlans > 0 || result.importedExercises > 0) {
        RedesignDataRefresh.instance.notifyRestored();
        await state._loadPendingSyncCount();
      }
      if (result.importedPlans == 0 &&
          result.importedExercises == 0 &&
          result.skippedFiles.isEmpty) {
        _showMessage(
          l10n.profileVaultImportNoFiles(result.scannedSources.join('、')),
        );
        return;
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
      final archiveWarning = result.archiveFailures.isEmpty
          ? ''
          : ' ${l10n.profileVaultImportArchiveFailed(result.archiveFailures.length)}';
      final sourceNotice = result.unavailableSources.isEmpty
          ? ''
          : ' ${l10n.profileVaultImportSourcesUnavailable(result.unavailableSources.join('、'))}';
      _showMessage(
        firstFailure == null
            ? '$summary$archiveWarning$sourceNotice'
            : '$summary ${firstFailure.fileName}: ${firstFailure.message}$archiveWarning$sourceNotice',
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

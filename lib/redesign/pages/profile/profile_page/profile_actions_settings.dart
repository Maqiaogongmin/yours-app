part of '../profile_page.dart';

extension _ProfilePageSettingsActions on _ProfilePageActions {
  void _showAboutYoursSheet() {
    showModalBottomSheet<void>(
      context: state.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<AppUpdateState>(
        valueListenable: state._appUpdateService.state,
        builder: (context, updateState, _) => YoursAboutSheet(
          officialWebsiteUrl: _officialWebsiteUrl,
          githubRepositoryUrl: _githubRepositoryUrl,
          showUpdateCheck: state._appUpdateService.supportsUpdateCheck,
          updateState: updateState,
          onCheckUpdate: _checkForUpdatesManually,
        ),
      ),
    );
  }

  void openSettings() {
    Navigator.of(state.context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(onAbout: _showAboutYoursSheet),
      ),
    );
  }

  Future<void> _checkForUpdatesManually() async {
    final result = await state._appUpdateService.checkForUpdates();
    if (!state.mounted) {
      return;
    }
    if (result.status == AppUpdateStatus.upToDate) {
      _showMessage(state.context.l10n.profileUpToDate);
    } else if (result.status == AppUpdateStatus.failed) {
      _showMessage(state.context.l10n.profileUpdateFailed);
    }
  }
}

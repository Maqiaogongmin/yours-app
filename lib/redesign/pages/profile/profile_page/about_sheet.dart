part of '../profile_page.dart';

@visibleForTesting
class YoursAboutSheet extends StatelessWidget {
  final String officialWebsiteUrl;
  final String privacyPolicyUrl;
  final String githubRepositoryUrl;
  final bool showUpdateCheck;
  final AppUpdateState updateState;
  final Future<void> Function() onCheckUpdate;

  const YoursAboutSheet({
    required this.officialWebsiteUrl,
    this.privacyPolicyUrl = _privacyPolicyUrl,
    required this.githubRepositoryUrl,
    required this.showUpdateCheck,
    required this.updateState,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return YoursSheetShell(
      title: context.l10n.aboutYours,
      trailing: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.close, color: context.yoursPalette.fg),
      ),
      child: YoursSurfaceCard(
        role: YoursSurfaceRole.panel,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _AboutInfoRow(
              icon: Icons.language_outlined,
              label: context.l10n.officialWebsite,
              url: officialWebsiteUrl,
            ),
            Divider(height: 1, color: context.yoursPalette.border),
            _AboutInfoRow(
              icon: Icons.privacy_tip_outlined,
              label: context.l10n.privacyPolicy,
              url: privacyPolicyUrl,
            ),
            Divider(height: 1, color: context.yoursPalette.border),
            _AboutInfoRow(
              icon: Icons.code_outlined,
              label: context.l10n.githubRepository,
              url: githubRepositoryUrl,
            ),
            if (showUpdateCheck) ...[
              Divider(height: 1, color: context.yoursPalette.border),
              _AboutUpdateRow(updateState: updateState, onCheckUpdate: onCheckUpdate),
            ],
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
    return InkWell(
      onTap: updateState.isChecking ? null : () => _handleTap(context),
      child: YoursInfoRow(
        icon: Icons.system_update_alt,
        title: context.l10n.profileCheckUpdates,
        detail: _detailText(context),
        trailing: Icon(
          updateState.hasUpdate ? Icons.open_in_new : Icons.refresh,
          color: context.yoursPalette.muted,
          size: 18,
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
    return YoursInfoRow(
      icon: icon,
      title: label,
      detail: url,
      onTap: () => _open(context),
      trailing: Icon(Icons.open_in_new, color: context.yoursPalette.muted, size: 18),
    );
  }
}

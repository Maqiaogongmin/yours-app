part of '../profile_page.dart';

class _ServerBackupSettingsSheet extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController tokenController;

  const _ServerBackupSettingsSheet({
    required this.urlController,
    required this.tokenController,
  });

  @override
  Widget build(BuildContext context) {
    return YoursSheetShell(
      title: context.l10n.profileServerSettings,
      trailing: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.close, color: context.yoursPalette.fg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YoursFormField(
            label: context.l10n.profileServerAddress,
            controller: urlController,
            keyboardType: TextInputType.url,
            hintText: 'https://backup.example.com', // l10n-ignore-hardcoded
          ),
          YoursFormField(
            label: context.l10n.profileApiKeyOptional,
            controller: tokenController,
            obscureText: true,
            hintText: context.l10n.profileApiKeyHint,
          ),
          const SizedBox(height: 4),
          YoursFieldGroup(
            children: [
              YoursDangerAction(
                label: context.l10n.profileClear,
                onPressed: () {
                  Navigator.pop(context, const ServerBackupSettings(baseUrl: '', apiToken: ''));
                },
              ),
              YoursPrimaryAction(
                label: context.l10n.commonSave,
                onPressed: () {
                  Navigator.pop(
                    context,
                    ServerBackupSettings(
                      baseUrl: urlController.text.trim(),
                      apiToken: tokenController.text.trim(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

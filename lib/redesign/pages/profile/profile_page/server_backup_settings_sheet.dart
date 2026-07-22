part of '../profile_page.dart';

class _ServerBackupSettingsSheet extends StatefulWidget {
  const _ServerBackupSettingsSheet({required this.initialSettings});

  final ServerBackupSettings initialSettings;

  @override
  State<_ServerBackupSettingsSheet> createState() => _ServerBackupSettingsSheetState();
}

class _ServerBackupSettingsSheetState extends State<_ServerBackupSettingsSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialSettings.baseUrl);
    _tokenController = TextEditingController(text: widget.initialSettings.apiToken);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _pop([ServerBackupSettings? settings]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, settings);
  }

  void _clear() {
    _pop(const ServerBackupSettings(baseUrl: '', apiToken: ''));
  }

  void _save() {
    _pop(
      ServerBackupSettings(
        baseUrl: _urlController.text.trim(),
        apiToken: _tokenController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoursSheetShell(
      title: context.l10n.profileServerSettings,
      trailing: IconButton(
        onPressed: _pop,
        icon: Icon(Icons.close, color: context.yoursPalette.fg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YoursFormField(
            label: context.l10n.profileServerAddress,
            controller: _urlController,
            keyboardType: TextInputType.url,
            hintText: 'https://backup.example.com', // l10n-ignore-hardcoded
          ),
          YoursFormField(
            label: context.l10n.profileApiKeyOptional,
            controller: _tokenController,
            obscureText: true,
            hintText: context.l10n.profileApiKeyHint,
          ),
          const SizedBox(height: 4),
          YoursFieldGroup(
            children: [
              YoursDangerAction(
                label: context.l10n.profileClear,
                onPressed: _clear,
              ),
              YoursPrimaryAction(
                label: context.l10n.commonSave,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

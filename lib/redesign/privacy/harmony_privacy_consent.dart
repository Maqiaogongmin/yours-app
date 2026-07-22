import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';

abstract interface class HarmonyPrivacyConsentRepository {
  Future<bool> hasAcceptedCurrentVersion();

  Future<void> acceptCurrentVersion();
}

final class SharedPreferencesHarmonyPrivacyConsentRepository
    implements HarmonyPrivacyConsentRepository {
  static const agreementVersion = 1;
  static const _agreementVersionKey = 'harmony_privacy_agreement_version';

  SharedPreferencesHarmonyPrivacyConsentRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> hasAcceptedCurrentVersion() async {
    final acceptedVersion = await _preferences.getInt(_agreementVersionKey);
    return acceptedVersion != null && acceptedVersion >= agreementVersion;
  }

  @override
  Future<void> acceptCurrentVersion() {
    return _preferences.setInt(_agreementVersionKey, agreementVersion);
  }
}

enum _PrivacyBootstrapState { checking, consentRequired, initializing, ready, failed }

class HarmonyPrivacyConsentGate extends StatefulWidget {
  const HarmonyPrivacyConsentGate({
    super.key,
    required this.repository,
    required this.initializeApp,
    required this.onDecline,
    required this.child,
  });

  final HarmonyPrivacyConsentRepository repository;
  final Future<void> Function() initializeApp;
  final VoidCallback onDecline;
  final Widget child;

  @override
  State<HarmonyPrivacyConsentGate> createState() => _HarmonyPrivacyConsentGateState();
}

class _HarmonyPrivacyConsentGateState extends State<HarmonyPrivacyConsentGate> {
  _PrivacyBootstrapState _state = _PrivacyBootstrapState.checking;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final accepted = await widget.repository.hasAcceptedCurrentVersion();
      if (!mounted) {
        return;
      }
      if (!accepted) {
        setState(() => _state = _PrivacyBootstrapState.consentRequired);
        return;
      }
      await _initializeApp();
    } on Object {
      if (mounted) {
        setState(() => _state = _PrivacyBootstrapState.failed);
      }
    }
  }

  Future<void> _accept() async {
    setState(() => _state = _PrivacyBootstrapState.initializing);
    try {
      await widget.repository.acceptCurrentVersion();
      await _initializeApp();
    } on Object {
      if (mounted) {
        setState(() => _state = _PrivacyBootstrapState.failed);
      }
    }
  }

  Future<void> _initializeApp() async {
    if (mounted) {
      setState(() => _state = _PrivacyBootstrapState.initializing);
    }
    await widget.initializeApp();
    if (mounted) {
      setState(() => _state = _PrivacyBootstrapState.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _PrivacyBootstrapState.ready) {
      return widget.child;
    }
    if (_state == _PrivacyBootstrapState.consentRequired) {
      return _PrivacyConsentPrompt(
        onAccept: _accept,
        onDecline: widget.onDecline,
      );
    }
    if (_state == _PrivacyBootstrapState.failed) {
      return _PrivacyBootstrapFailure(onRetry: _bootstrap);
    }
    return const _PrivacyBootstrapProgress();
  }
}

class _PrivacyConsentPrompt extends StatelessWidget {
  const _PrivacyConsentPrompt({
    required this.onAccept,
    required this.onDecline,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.yoursPalette.bg,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Opacity(
                  opacity: 0.16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const YoursBrandMark(size: 72),
                      const SizedBox(height: 12),
                      Text(context.l10n.appName, style: context.yoursText(YoursTextRole.pageTitle)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Dialog(
                    key: const ValueKey('privacy-consent-dialog'),
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
                      child: YoursSurfaceCard(
                        role: YoursSurfaceRole.panel,
                        shadow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.privacyConsentTitle,
                              style: context.yoursText(YoursTextRole.cardTitle),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.privacyPolicyUpdatedAt,
                              style: context.yoursText(YoursTextRole.bodyMuted),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  key: const ValueKey('privacy-policy-content'),
                                  padding: const EdgeInsetsDirectional.only(end: 8),
                                  child: _PrivacyPolicyContent(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            YoursPrimaryAction(
                              key: const ValueKey('privacy-consent-accept'),
                              label: context.l10n.privacyConsentAgree,
                              onPressed: onAccept,
                            ),
                            const SizedBox(height: 8),
                            YoursDangerAction(
                              key: const ValueKey('privacy-consent-decline'),
                              label: context.l10n.privacyConsentDecline,
                              onPressed: onDecline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    final sections = <(String, String)>[
      (context.l10n.privacyPolicyDataTitle, context.l10n.privacyPolicyDataBody),
      (context.l10n.privacyPolicyStorageTitle, context.l10n.privacyPolicyStorageBody),
      (context.l10n.privacyPolicySyncTitle, context.l10n.privacyPolicySyncBody),
      (context.l10n.privacyPolicyPhotosTitle, context.l10n.privacyPolicyPhotosBody),
      (context.l10n.privacyPolicyBackupTitle, context.l10n.privacyPolicyBackupBody),
      (context.l10n.privacyPolicyDeletionTitle, context.l10n.privacyPolicyDeletionBody),
      (context.l10n.privacyPolicyChildrenTitle, context.l10n.privacyPolicyChildrenBody),
      (context.l10n.privacyPolicyThirdPartyTitle, context.l10n.privacyPolicyThirdPartyBody),
      (context.l10n.privacyPolicyContactTitle, context.l10n.privacyPolicyContactBody),
      (context.l10n.privacyPolicyUpdatesTitle, context.l10n.privacyPolicyUpdatesBody),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.privacyConsentMessage,
          style: context.yoursText(YoursTextRole.bodyMuted),
        ),
        for (final section in sections) ...[
          const SizedBox(height: 16),
          Text(section.$1, style: context.yoursText(YoursTextRole.label)),
          const SizedBox(height: 4),
          Text(section.$2, style: context.yoursText(YoursTextRole.bodyMuted)),
        ],
      ],
    );
  }
}

class _PrivacyBootstrapProgress extends StatelessWidget {
  const _PrivacyBootstrapProgress();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.yoursPalette.bg,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PrivacyBootstrapFailure extends StatelessWidget {
  const _PrivacyBootstrapFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.yoursPalette.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: YoursSurfaceCard(
                role: YoursSurfaceRole.panel,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.privacyInitializationFailed,
                      textAlign: TextAlign.center,
                      style: context.yoursText(YoursTextRole.body),
                    ),
                    const SizedBox(height: 16),
                    YoursPrimaryAction(
                      label: context.l10n.commonRetry,
                      onPressed: onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

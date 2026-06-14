import 'package:flutter/material.dart';
import 'package:yours/redesign/localization/generated_language_registry.dart';
import 'package:yours/redesign/localization/locale_controller.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/theme/redesign_theme.dart';
import 'package:yours/redesign/theme/theme_mode_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onAbout,
    this.themeController,
    this.localeController,
  });

  final VoidCallback onAbout;
  final YoursThemeModeController? themeController;
  final YoursLocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: context.l10n.settingsTitle,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: context.l10n.appearanceTitle,
            subtitle: context.l10n.appearanceDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _AppearancePage(
                  controller: themeController ?? yoursThemeModeController,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.translate_rounded,
            title: context.l10n.language,
            subtitle: context.l10n.languageDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _LanguagePage(
                  controller: localeController ?? yoursLocaleController,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.info_outline,
            title: context.l10n.aboutYours,
            subtitle: context.l10n.aboutDescription,
            onTap: onAbout,
          ),
        ],
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({required this.controller});

  final YoursThemeModeController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: context.l10n.appearanceTitle,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _ChoiceCard<ThemeMode>(
          value: controller.mode,
          onChanged: controller.setMode,
          options: [
            (ThemeMode.system, context.l10n.themeSystem),
            (ThemeMode.light, context.l10n.themeLight),
            (ThemeMode.dark, context.l10n.themeDark),
          ],
        ),
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.controller});

  final YoursLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: context.l10n.language,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final selected = controller.locale?.toLanguageTag() ?? 'system';
          return _ChoiceCard<String>(
            value: selected,
            onChanged: (value) {
              final locale = value == 'system'
                  ? null
                  : yoursSupportedLanguages
                        .singleWhere(
                          (language) => language.locale.toLanguageTag() == value,
                        )
                        .locale;
              return controller.setLocale(locale);
            },
            options: [
              ('system', context.l10n.languageSystem),
              for (final language in yoursSupportedLanguages)
                (language.locale.toLanguageTag(), language.nativeName),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.chevron_left, color: palette.fg, size: 30),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: palette.fg,
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.fg,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final Future<void> Function(T value) onChanged;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: palette.border),
      ),
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        child: Column(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              RadioListTile<T>(
                value: options[index].$1,
                title: Text(options[index].$2),
              ),
              if (index != options.length - 1)
                Divider(height: 1, indent: 16, endIndent: 16, color: palette.border),
            ],
          ],
        ),
      ),
    );
  }
}

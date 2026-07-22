# Android engineering health policy

Android changes are accepted only after the shared health gate and runtime
acceptance pass. A signed APK is an artifact, not runtime evidence.

## Required gates

1. Run `tool/android_health_check.sh`.
2. Run `tool/android_runtime_acceptance.sh <apk>` with a USB device connected.
   The script selects a physical device first and falls back to an emulator.
3. Inspect the generated package metadata, signature, SHA-256 and fatal log scan.
4. Publish to the website or GitHub only after runtime acceptance.

New database, YoursVault, workout persistence and synchronization behavior must
include a regression test. New platform channels must live outside
`MainActivity` and include error-path coverage. Files over 400 lines appear in
the monthly health report and should not grow without an explicit refactoring
note.

The line coverage gate excludes only generated Drift `*.g.dart` files and
Flutter-generated `lib/l10n/app_localizations*.dart` files. The minimum for
handwritten code is 65%; no application or platform bridge file may be excluded.
Backup archive, YoursVault import/export, training persistence and active workout
session modules each have an additional 80% minimum. The shared gate reports and
enforces each module separately.

## Temporary dependency constraints

- `package_info_plus` 10 and `share_plus` 13 are blocked by stable
  `file_picker` 11 because they require incompatible `win32` major versions.
- Drift 2.32+ requires sqlite3 3 through `drift_dev`. sqlite3 3 removed the
  dynamic-library override currently used to load SQLCipher on Android and
  HarmonyOS. Keep the current database versions until an encrypted migration
  proves open, migrate, rollback and cross-platform compatibility.
- `path_provider_foundation` remains pinned until an App Store upload accepts
  the native-assets dependency introduced by its newer release.

Review these constraints monthly; do not bypass them with beta packages in a
release branch.

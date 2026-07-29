# Yours Flutter HarmonyOS Porting

## Direction

Yours uses the Flutter app as the single source of truth for product behavior,
UI, assets, data formats, localization, and sync semantics. The HarmonyOS port
must be built from the Flutter app first. The ArkTS project is only a shell and
native capability lab for HarmonyOS platform bridges.

Do not continue a full ArkTS reimplementation unless the Flutter HarmonyOS
route fails at an engine or database blocker that cannot be bypassed without
breaking Yours data compatibility.

## Current Baseline

- Main app: `<repo-root>`
- ArkTS shell/lab: `<legacy-harmony-lab>`
- Current upstream Flutter: `3.41.9`, Dart `3.11.5`
- Matching Flutter-OH candidate: `oh-3.41.9-release`
- Default Flutter-OH SDK path: `$FLUTTER_OH_HOME`

Use the matching Flutter-OH SDK in isolation. Do not replace the system Flutter
SDK and do not downgrade the main app until a spike proves the need and impact.

## First Spike

1. Run `dart run tool/check_harmony_flutter_ready.dart`.
2. Ensure Flutter-OH reports `3.41.9` and supports `ohos` commands.
3. Run `make harmony-flutter-pub-get` to resolve dependencies with the isolated
   OHOS pub cache. This target first runs
   `tool/bootstrap_harmony_flutter_deps.dart`, which prepares the local
   HarmonyOS package overrides under `.dart_tool/harmony-flutter-packages`.
4. Run `make harmony-flutter-patch-deps` before the first HarmonyOS build.
   This patches only the isolated OHOS pub cache for packages that do not yet
   understand `TargetPlatform.ohos`.
5. Run `make harmony-flutter-build-debug`, then
   `make harmony-flutter-build-release`.
6. If a module/HAR split is needed later, create a dedicated Flutter module
   after the app-level HAP path has proven viability.
7. Configure DevEco debug signing for `ohos/`, then run
   `make harmony-flutter-run` against the Pura emulator when HDC reports a
   connected target.

The spike passes only when the original Flutter UI launches on HarmonyOS and
the four bottom tabs, home, plans, exercises, and profile pages are visible.

Do not use an unsigned HAP installed with `hdc install` as UI evidence. The
unsigned package is useful for build verification only; runtime/UI validation
must use DevEco debug signing plus `flutter run`, otherwise the app can launch
to a blank Flutter surface with no Dart UI.

## Runtime Spike Result

2026-07-05 runtime verification on the Pura 90 emulator reached the first
product loop:

- HDC target: `127.0.0.1:5555` connected after `hdc tconn 127.0.0.1:5555`.
- Installed bundle: `com.ly.yours`, version `1.11.4`, debug provision.
- Flutter original UI launched with the expected bottom tabs: home, plans,
  exercise library, and profile.
- Created a new training plan, added one custom exercise, started training,
  ended the workout, force-stopped the app, relaunched it, and confirmed the
  calendar still showed `1 天有训练`.

2026-07-05 Flutter-OH database update: the first accepted HarmonyOS data loop
now runs through the Flutter app, not the ArkTS rewrite:

- `path_provider` and `shared_preferences` use OpenHarmony Flutter packages.
- Drift background isolates call the HarmonyOS SQLite loader through
  `DriftNativeOptions(isolateSetup: configureHarmonySqlite)`.
- `sqlite3` stays in the app dependency graph and loads the bundled
  `libsqlcipher.so` from the HarmonyOS `sqlcipher_flutter_libs` package on
  OHOS only.
- Verified on Pura: create training plan -> add one exercise to D1 -> start
  training -> save three sets -> end and save workout -> force-stop -> relaunch.
- Relaunch evidence: the July 5 calendar cell still shows a training marker.

Open follow-up: this SQLCipher package is a local verification dependency, and
its upstream README warns about release-package crashes. Treat it as a debug
bridge proving Drift/SQLite viability, not yet as the final store-ready
database dependency.

2026-07-06 dependency bootstrap update: HarmonyOS-specific Flutter package
checkouts are now reproducible through `make harmony-flutter-pub-get`:

- `path_provider` is fetched from `openharmony-tpc/flutter_packages`
  `br_path_provider-v2.1.5_ohos`.
- `shared_preferences` is fetched from `openharmony-tpc/flutter_packages`
  `br_shared_preferences-v2.5.4_ohos`.
- `sqlcipher_flutter_libs` is fetched from `tech-ming/sqlite3-ohos.dart`
  `main`.
- `pubspec_overrides.yaml` is generated locally and ignored by git so normal
  iOS/Android Flutter dependency resolution does not depend on HarmonyOS
  package paths.

2026-07-06 release smoke update:

- `make harmony-flutter-build-debug` passed and produced an unsigned debug HAP.
- `make harmony-flutter-build-release` passed and produced an unsigned release
  HAP.
- `flutter build hap --release` passed with the local DevEco signing config and
  produced `entry-default-signed.hap`.
- Installing that signed release HAP on the Pura emulator succeeded.
- The signed release HAP launched to the Flutter home UI, retained the July 5
  training marker, and opened the training plan list through Drift/SQLite.

This reduces the SQLCipher release risk, but does not close it. Store-signed
release packages and physical HarmonyOS NEXT devices still need verification.

2026-07-05 signing status: `flutter run -d 127.0.0.1:5555` stops with DevEco's
debug signing requirement until `ohos/` is opened in DevEco Studio and
Project Structure -> Signing Configs completes Huawei account login and
automatic signature generation.

2026-07-05 signed runtime update: Pura emulator can run the Flutter-OH signed
debug HAP and render Flutter content. A blank screen was reproduced when
`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` ran before
`runApp`; HarmonyOS now skips that setup path. The original Flutter home UI is
visible after this guard.

The previous `shared_preferences` and `path_provider` missing-plugin blocker is
resolved for the debug runtime. The next blockers are release viability of the
SQLite native library, file/share/package-info plugins, and real Vault
compatibility.

2026-07-06 simulator-first real backup update:

- Target remains the Pura emulator only; physical HarmonyOS devices are out of
  scope for this phase.
- Real backup source:
  `<local-private-test-backup.zip>`.
- The backup archive contains the expected portable structure:
  `databases/local_training.sqlite`, `databases/custom_exercises.sqlite`,
  `settings/app_settings.json`, `settings/sync_settings.json`, and
  `manifest.json`.
- `yours/files` now implements HarmonyOS `pickPublicBackup` and
  `importPublicBackup`. The Flutter restore flow on HarmonyOS first imports a
  visible/default backup into the app sandbox, then falls back to the system file
  picker.
- Verified on Pura: restore from the real backup, force-stop, relaunch, open the
  Flutter original home, plan, and exercise library pages.
- Restored UI evidence: the plan page showed `共 1 个计划 · 本地优先` and
  `新训练计划`; the exercise library showed restored exercise data.
- Restored sandbox evidence:
  `/data/app/el2/100/base/com.ly.yours/files/flutter/local_training.sqlite`,
  `custom_exercises.sqlite`, `YoursVault/`, `backups/yours-backup.zip`, and
  `exercise_images/` exist after restore/export.
- Export evidence: the HarmonyOS-generated `backups/yours-backup.zip` was pulled
  back to macOS and passed `unzip -t`; it contains the same five portable backup
  entries listed above.
- Regression test evidence:
  `flutter test test/backup_archive_diagnostics_test.dart --plain-name 'backup archive restores real training custom exercise and settings data'`
  passed.

Open boundary: the HarmonyOS file manager's document provider namespace is not
the same as the `hdc shell` `/storage` namespace on the Pura emulator. App-level
export can succeed and be visible in Files while `/storage/Users/currentUser`
does not exist in shell. Use the app sandbox and pulled ZIPs for automated
evidence; use the Files app for user-visible directory evidence.

2026-07-06 poster photo background update:

- The Flutter poster page already calls `yours/photos.pickPosterBackground`.
- HarmonyOS now implements that method through `photoAccessHelper.PhotoViewPicker`.
- The selected photo URI is copied into the app sandbox under
  `poster_backgrounds/`, and Flutter receives a normal file path so the existing
  poster renderer can keep using `File(path)`.
- Build and install evidence: `flutter build hap --debug` passed, the signed HAP
  was installed on the Pura emulator, and the app launched to the Flutter home UI.
- Manual follow-up: use the Pura photo picker to select an actual simulator
  gallery image and confirm the poster preview renders it as the background.

2026-07-06 real backup completeness correction:

- The previous automated restore was incomplete because the HarmonyOS
  `pickBackupFile()` path preferred `importPublicBackup` before opening the file
  picker. That silently restored an older small visible backup instead of the
  intended real ZIP.
- Product behavior is corrected: HarmonyOS `pickBackupFile()` now opens the
  system picker through `pickPublicBackup`, matching the user-facing "restore
  from file" expectation.
- Audit result for the real backup:
  11 routines, 103 training days, 144 workout sessions, 1905 workout logs,
  covering 2026-01 through 2026-07.
- The Pura simulator state was reseeded from the real backup databases for UI
  validation and now matches those counts.
- Remaining validation: manually choose the real ZIP in the system picker to
  verify the full restore entry point end to end. The direct reseed is only a
  simulator data-state fix, not proof of the picker restore flow.

## Dependency Risk

Pure Dart dependencies are expected to stay unchanged: `archive`, `collection`,
`crypto`, `http`, `logging`, `path`, and `uuid`.

Platform dependencies must use an OHOS implementation or a Yours bridge:
`path_provider`, `shared_preferences`, `url_launcher`, `file_picker`,
`share_plus`, and `package_info_plus`.

Database is the highest risk. `drift`, `drift_flutter`, and `sqlite3` must be
validated before any product claim. If they cannot run directly on Flutter-OH,
add a HarmonyOS database adapter behind the existing repository boundary. Do
not change Vault structure, sync IDs, or server protocol semantics.

## Platform Bridge Scope

The first HarmonyOS bridge layer exposes only:

- application documents/cache directories
- Vault export and import
- backup ZIP save and restore
- file picker and document save
- system share
- permission requests
- package/version info
- external URL launch

Prefer Pigeon when the interface will be shared across platforms. Use
MethodChannel only for small, narrow platform calls.

## Issue Protocol

When a Flutter HarmonyOS issue appears, follow this lookup order:

1. Check the Obsidian note `Flutter开发HarmonyOS应用热点问题集-华为开发者话题  华为开发者联盟.md`.
2. Open the matching subtopic: porting scheme, build, FlutterChannel, hybrid
   rendering, plugin development, debugging, performance, permission, or file
   capability.
3. Check `Flutter鸿蒙化开发指南___华为开发者联盟.md`, especially environment,
   HAR integration, third-party packages, FlutterChannel, Pigeon, and existing
   Flutter app adaptation sections.
4. Check `openharmony-tpc/flutter_flutter`, `flutter_packages`, and
   `flutter_samples` README/issues.
5. Only then add a local workaround or custom plugin, and record the reason in
   this document or the Harmony porting status.

## Acceptance Gates

- Environment: current Flutter, Flutter-OH, DevEco tools, Java, and HDC target
  are reported by the preflight script.
- Build: `flutter pub get`, `flutter build hap --debug`, and
  `flutter build hap --release` pass with the Flutter-OH SDK. HAR is deferred
  until a Flutter module split is intentionally needed.
- Product loop: create a plan, start training, save a workout record, restart,
  and confirm the record remains.
- Data compatibility: import a real iOS/Android YoursVault, export from
  HarmonyOS, and import back into the Flutter app with no missing, duplicated,
  or reordered plan/exercise/workout data.

# Database dependency migration

Status: blocked pending a Flutter-OH-compatible `sqlite3` 3.x loader.

Owner: Yours platform maintainers
Next review: 2026-09-30

## Current boundary

- Production stays on Drift 2.31, sqlite3 2.9 and sqlcipher_flutter_libs 0.6.
- The application does not issue `PRAGMA key` or `rekey`; SQLCipher currently
  supplies the native SQLite-compatible library and the HarmonyOS loader, not
  an application-managed database encryption key.
- `configureHarmonySqlite` depends on the sqlite3 2.x runtime
  `DynamicLibrary` override API to load `libsqlcipher.so` on HarmonyOS.
- Database schema versions remain training v8 and exercise v2.

## 2026-07-22 isolated upgrade experiment

The experiment used a detached worktree and did not change production
dependencies or user data.

Tested candidate:

- drift 2.34.2
- drift_dev 2.34.0
- sqlite3 3.5.0
- sqlcipher_flutter_libs 0.7.0+eol

Results:

- drift_dev 2.34.2 could not resolve because it requires an analyzer version
  needing meta 1.18+, while the current Flutter SDK pins meta 1.17.
- drift_dev 2.34.0 resolved with drift 2.34.2.
- Existing schema migration, backup restore and YoursVault tests passed after
  replacing the old loader with sqlite3 3.x native assets.
- An Android arm64 Release APK built successfully with that temporary setup.
- HarmonyOS did not compile unchanged: sqlite3 3.x removed
  `package:sqlite3/open.dart`, and sqlcipher_flutter_libs 0.7 is intentionally
  an inert compatibility package.

## Required evidence before upgrading production

1. Flutter-OH must support Dart native asset hooks, or the project must provide
   a maintained sqlite3 3.x-compatible HarmonyOS native asset package.
2. The same dependency set must build Android, iOS and a signed HarmonyOS
   Release package from reproducible CI inputs.
3. A copied v8/v2 production database fixture must be opened by the candidate,
   verified table-by-table, modified, and then reopened by the previous release.
4. Backup creation and restore must pass before and after the dependency change,
   including a safety backup made before first candidate launch.
5. Android must pass physical-device upgrade and rollback acceptance. HarmonyOS
   must pass the equivalent physical-device persistence loop.

## Rollback rule

Do not increase either Drift schema version in the dependency-only change.
Keep the pre-upgrade APK and safety backup until both platforms pass. If opening,
verification or persistence fails, reinstall the previous build and restore the
safety backup; do not attempt an in-place repair on the only user database.

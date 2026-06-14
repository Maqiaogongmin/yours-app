# Source Audit Summary

Audit date: 2026-06-14

This is a technical source audit, not a legal opinion.

## Reference points

- Internal source commit:
  `9c040543acd78ee8f75f00dffe69e073547c999f`
- Previous audit baseline:
  `6128395bda3f73927449c0ccc59fc3585cde0b32`
- wger Flutter reference:
  tag `1.11.0`, commit
  `e3e33b717ce3240a920f8c997c1e789cabc5e6b5`

## Findings

- Current Yours business code under `lib/redesign/` and `tool/yours_cli/`
  does not contain detected wger package names, API clients, old Drift schema
  symbols, or exact wger business-source file matches.
- The previously identified wger `schema.json` and desktop app icons are not
  present in this public snapshot.
- Unused macOS, Windows, and Linux runner projects were removed instead of
  carrying forward unmaintained scaffold code.
- Files that remain byte-identical to wger are standard iOS/Android Flutter
  templates, the standard AGPL text, and the Roboto Condensed font. They are
  classified as platform templates or third-party material, not Yours
  business logic.
- `assets/data/custom_exercises_seed.json` retains five wger exercise
  identities for compatibility. The data source, authors, and CC BY-SA 3.0
  license are recorded in `assets/data/README.md`.
- The duplicate self-hosted server implementation was removed. The
  authoritative server is the independent Apache-2.0
  `Maqiaogongmin/yours-sync-server` repository.
- Sensitive-file and literal scans found no keystore, certificate, private
  key, API token, App Store archive, APK, IPA, database, personal filesystem
  path, or Apple developer team identifier in the public snapshot.

## Source classification

- **Historical wger-derived context**: project ancestry, Flutter/platform
  scaffold, AGPL lineage, and the attributed exercise seed identities.
- **Yours implementation**: local-first data model, training workflows,
  Yours Vault, synchronization client, localization system, current UI,
  backup/restore behavior, and Yours CLI.
- **Platform/generated material**: Flutter runner projects, generated plugin
  registrants, workspace settings, and standard build configuration.
- **Third-party material**: Dart/Flutter dependencies, Roboto Condensed, and
  attributed CC BY-SA exercise seed data.

## Publication decision

The audited snapshot is suitable for publication under
`AGPL-3.0-or-later` with `APP_STORE_EXCEPTION.md`, provided publication uses a
new clean Git history and retains all notices in this repository.

App Store Connect now confirms that iOS `1.11.2` is `READY_FOR_SALE` and is
attached to build `11136`, build ID
`2d9a3385-5619-4d89-a0aa-18d66c2aad26`, with processing state `VALID`.

The current public repository commit is a post-release clean source snapshot
derived from the internal source used for that release. It should not be
described as a byte-for-byte reproducible source tag for the already-published
App Store binary, because the public snapshot includes release-documentation
and source-link cleanup performed after the binary was built.

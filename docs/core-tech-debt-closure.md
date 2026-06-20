# Core Tech Debt Closure

Date: 2026-06-18

This document closes the core technical-debt refinement round that started from
`docs/core-tech-debt-baseline.md`. The round stayed inside the agreed boundary:
no UI redesign, no backup format change, no server protocol change, and no
database schema change.

## Completed batches

| Batch | Commit | Result |
| --- | --- | --- |
| Baseline | `c71f6cd` | Recorded the starting file sizes, accepted warnings, and verification set. |
| Server sync event applier | `2fdecad` | Split routine, session, workout log, and custom exercise handlers behind the existing `ServerSyncEventApplier.applyRemoteEvent` entrypoint. |
| Local training repository | `c21f62e` | Split plan, workout record, stats, and seed responsibilities behind the existing `LocalTrainingRepository` facade. |
| Entry pages | `3c7b72b` | Split the large home, plan, and profile page files into focused part files without changing copy, visual design, or navigation behavior. |
| Core tests | `42b64ef` | Split backup/archive/diagnostics and Yours Vault tests out of the broad core test file while preserving coverage. |
| Test follow-up | This follow-up | Split local gym session controller behavior out of the broad core test file. |

## Current large-file status

Generated localization and Drift files remain excluded from manual cleanup.

| File | Lines | Closure status |
| --- | ---: | --- |
| `test/yours_core_test.dart` | 1967 | Still broad, but reduced from 3083 and now no longer carries backup archive, diagnostics, vault, or local gym session controller tests. Future splits should be by behavior, not by file size alone. |
| `test/local_gym_session_controller_test.dart` | 297 | Covers local gym resume, per-set notes, free-record timing, action replacement, and free-record persistence behavior. |
| `lib/redesign/pages/profile/profile_page.dart` | 919 | Still large, but the main risk panels were moved out. The remaining file is mainly profile state and section orchestration. |
| `lib/redesign/data/yours_vault_service.dart` | 871 | Outside this core pass. It now has a dedicated test file, which lowers change risk before any later extraction. |
| `lib/redesign/pages/home/home_page/workout_record_editors.dart` | 555 | Accepted as the focused editor surface extracted from the home page. Split further only when editor behavior changes. |
| `lib/redesign/data/server_sync_event_applier.dart` | 414 | No longer a large-file risk; it now coordinates entity-specific handlers. |
| `lib/redesign/data/local_training_repository.dart` | 206 | No longer a large-file risk; it is now a facade. |
| `lib/redesign/pages/home/home_page.dart` | 210 | No longer a large-page risk; it is now page orchestration. |
| `lib/redesign/pages/plan/plan_page.dart` | 325 | No longer a large-page risk; it is now page orchestration. |

## Accepted residual debt

- Drift multiple-database warnings can still appear in test output. They were
  present at baseline and are not caused by this refinement round.
- `test/backup_archive_diagnostics_test.dart` keeps two
  `depend_on_referenced_packages` ignores for Flutter test platform utilities.
  Replacing them would require a dependency-policy change, so this round leaves
  them explicit.
- `lib/main.dart` keeps one `avoid_print` ignore inside the app-wide logging
  bridge. It is intentional debug logging, not feature logic.
- Generated localization and Drift files keep generated lint ignores.
- `@visibleForTesting` entrypoints remain where tests need stable access to
  critical sync, backup, and presentation behavior.

## Future split triggers

Continue splitting only when one of these conditions is true:

- A file repeatedly requires unrelated changes in the same edit.
- A test failure is hard to localize because multiple behavior domains share one
  test group.
- A page part starts owning both state transitions and substantial widget
  rendering for more than one user workflow.
- A service needs a protocol or schema change and the current boundary makes
  review difficult.

## Final verification

The final batch is considered valid only when these commands pass:

- `flutter analyze`
- `flutter test`
- `dart run tool/check_ui_guard.dart --strict`
- `flutter build apk --debug`
- `git diff --check`

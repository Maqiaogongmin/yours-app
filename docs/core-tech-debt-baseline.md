# Core Tech Debt Baseline

Created: 2026-06-18

This baseline records the starting point for the core technical-debt refinement
round. It is intentionally factual and lightweight so each follow-up batch can
be reviewed against the same reference point.

## Current largest tracked Dart files

Generated files are excluded from the manual-refactor target even when they are
larger than app code.

| File | Lines | Status |
| --- | ---: | --- |
| `test/yours_core_test.dart` | 3083 | Too broad; split by behavior domain later. |
| `lib/redesign/pages/home/home_page.dart` | 1895 | Multiple page/detail/editor responsibilities. |
| `lib/redesign/pages/plan/plan_page.dart` | 1677 | List, detail, plan edit, and day edit share one file. |
| `lib/redesign/pages/profile/profile_page.dart` | 1648 | Profile, data management, server settings, and about UI share one file. |
| `lib/redesign/design_system/yours_components.dart` | 1454 | Large, but not in the first core-debt pass. |
| `lib/redesign/data/local_training_repository.dart` | 1219 | Plan, workout, stats, seed, and normalization logic share one repository. |
| `lib/redesign/data/server_sync_event_applier.dart` | 972 | Clear boundary, but still large enough to split by synced entity. |
| `lib/redesign/pages/plan/local_gym_mode_page.dart` | 994 | Large, but outside the first core-debt pass unless touched by page extraction. |

## Accepted baseline warnings

- Core and full test runs pass, but debug test output still includes Drift
  multiple-database warnings from in-memory database tests.
- Dependency output reports newer package versions; this round does not update
  dependencies.
- Generated localization and Drift files are excluded from manual cleanup.

## Verified baseline

- `flutter analyze`
- `flutter test test/server_sync_engine_test.dart`
- `flutter test test/yours_core_test.dart`
- `flutter test`
- `dart run tool/check_ui_guard.dart --strict`
- `flutter build apk --debug`

## Refinement batches

1. Split `ServerSyncEventApplier` by synced entity while keeping
   `applyRemoteEvent` as the public entrypoint.
2. Split `LocalTrainingRepository` behind the existing repository facade.
3. Split large home, plan, and profile page files without changing visual
   design, copy, or navigation behavior.
4. Split broad tests by behavior domain and keep existing coverage.
5. Tighten small static-analysis and test-hygiene issues only after behavior
   boundaries are stable.

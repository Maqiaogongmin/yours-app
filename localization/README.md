# Yours language packs

`localization/` is the source of truth for languages shipped with Yours.
Files under `lib/l10n`, iOS `.lproj` folders, Android locale resources, and the
Dart language registry are generated outputs.

## Add a language

1. Copy `localization/en` to a new locale directory.
2. Add the locale to `manifest.yaml` with `enabled: false`.
3. Translate `strings.arb` and `platform.yaml`.
4. Run `make l10n-generate`.
5. Run `make l10n-check`.
6. Set `enabled: true` only after validation passes.

Application pages must use `context.l10n`. Do not add user-facing text literals
directly to widgets. Business and data layers should return stable error codes,
not localized sentences.

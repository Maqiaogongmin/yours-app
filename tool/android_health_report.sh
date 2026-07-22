#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if [[ "${1:-}" == "--refresh" ]]; then
  tool/android_health_check.sh >/dev/null
fi

coverage="not generated"
if [[ -f coverage/lcov.info ]]; then
  coverage="$(awk -F: '
    /^SF:/ {
      skip = ($0 ~ /\.g\.dart$/ || $0 ~ /lib\/l10n\/app_localizations(_[a-z]+)?\.dart$/)
    }
    /^LF:/ && !skip { found += $2 }
    /^LH:/ && !skip { hit += $2 }
    END {
      percent = found == 0 ? 0 : 100 * hit / found
      printf "%d/%d (%.2f%%)", hit, found, percent
    }
  ' coverage/lcov.info)"
fi

lint="not generated"
if [[ -f build/app/reports/lint-results-release.txt ]]; then
  lint="$(tail -n 1 build/app/reports/lint-results-release.txt)"
fi

echo "# Yours Android health report"
echo
echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "- Commit: $(git rev-parse --short HEAD)"
echo "- Flutter: $(flutter --version | head -n 1)"
echo "- Dart source files: $(find lib -name '*.dart' -type f | wc -l | tr -d ' ')"
echo "- Flutter test files: $(find test integration_test -name '*_test.dart' -type f | wc -l | tr -d ' ')"
echo "- Line coverage: $coverage"
echo "- Android lint: $lint"
echo "- MainActivity lines: $(wc -l < android/app/src/main/kotlin/com/ly/yours/MainActivity.kt | tr -d ' ')"
echo
echo "## Files over 400 lines"
echo
find lib android/app/src/main -type f \( -name '*.dart' -o -name '*.kt' \) ! -name '*.g.dart' -print0 |
  xargs -0 wc -l |
  awk '$1 > 400 && $2 != "total" && $2 !~ /lib\/l10n\/app_localizations/ {printf "- %s: %s lines\n", $2, $1}' |
  sort -t: -k2,2nr
echo
echo "## Direct dependency status"
echo
echo '```text'
flutter pub outdated --no-dev-dependencies || true
echo '```'
echo
echo "## Dependency exceptions"
echo
echo "- Drift/sqlite3/SQLCipher: HarmonyOS loader blocked; owner Yours platform maintainers; review 2026-09-30; see docs/database-dependency-migration.md."

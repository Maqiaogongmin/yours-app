#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

minimum_coverage="${MINIMUM_COVERAGE_PERCENT:-65.0}"
minimum_critical_coverage="${MINIMUM_CRITICAL_COVERAGE_PERCENT:-80.0}"
maximum_lint_warnings="${MAXIMUM_ANDROID_LINT_WARNINGS:-0}"

if [[ -n "${JAVA_21_HOME:-}" ]]; then
  export JAVA_HOME="$JAVA_21_HOME"
elif [[ -d /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home ]]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
fi

echo "[1/6] Flutter analyze"
flutter analyze --no-pub

echo "[2/6] Flutter tests and coverage"
flutter test --coverage --no-pub

coverage_summary="$({
  awk -F: '
    /^SF:/ {
      skip = ($0 ~ /\.g\.dart$/ || $0 ~ /lib\/l10n\/app_localizations(_[a-z]+)?\.dart$/)
    }
    /^LF:/ && !skip { found += $2 }
    /^LH:/ && !skip { hit += $2 }
    END {
      percent = found == 0 ? 0 : (100 * hit / found)
      printf "%d %d %.2f", hit, found, percent
    }
  ' coverage/lcov.info
})"
read -r covered_lines total_lines coverage_percent <<<"$coverage_summary"
echo "Coverage: ${covered_lines}/${total_lines} lines (${coverage_percent}%)"
awk -v actual="$coverage_percent" -v required="$minimum_coverage" 'BEGIN {
  if (actual + 0.0001 < required) {
    printf "Coverage %.2f%% is below required %.2f%%.\n", actual, required > "/dev/stderr"
    exit 1
  }
}'

critical_module_groups=(
  "backup archive|^lib/redesign/data/backup_archive_service\\.dart$"
  "training persistence|^lib/redesign/data/local_training_repository(\\.dart|/.*\\.dart)$"
  "YoursVault|^lib/redesign/data/yours_vault(_.*)?\\.dart$"
  "workout session|^lib/redesign/pages/plan/local_gym_session_.*\\.dart$"
)
for module_group in "${critical_module_groups[@]}"; do
  IFS='|' read -r module_label module_pattern <<<"$module_group"
  module_summary="$(awk -F: -v target="$module_pattern" '
    /^SF:/ { current = $2; selected = (current ~ target) }
    /^LF:/ && selected { found += $2 }
    /^LH:/ && selected { hit += $2 }
    END {
      if (found == 0) exit 2
      printf "%d %d %.2f", hit, found, (100 * hit / found)
    }
  ' coverage/lcov.info)"
  read -r module_hit module_total module_percent <<<"$module_summary"
  echo "Critical coverage: $module_label ${module_hit}/${module_total} (${module_percent}%)"
  awk -v actual="$module_percent" -v required="$minimum_critical_coverage" \
    -v module="$module_label" 'BEGIN {
      if (actual + 0.0001 < required) {
        printf "%s coverage %.2f%% is below required %.2f%%.\n", module, actual, required > "/dev/stderr"
        exit 1
      }
    }'
done

# `flutter test` regenerates a shared plugin registrant containing the
# debug-only integration_test plugin. Release Gradle tasks cannot compile that
# plugin, so normalize the registrant before the first native Release task.
python3 tool/prepare_android_release_registrant.py

echo "[3/6] Android release unit tests"
(cd android && ./gradlew :app:testReleaseUnitTest)

echo "[4/6] Android release lint"
(cd android && ./gradlew :app:lintRelease)
lint_report="build/app/reports/lint-results-release.txt"
lint_summary="$(tail -n 1 "$lint_report")"
if [[ "$lint_summary" == "No issues found." ]]; then
  lint_errors=0
  lint_warnings=0
else
  lint_errors="$(sed -E 's/^([0-9]+) errors?, ([0-9]+) warnings?.*/\1/' <<<"$lint_summary")"
  lint_warnings="$(sed -E 's/^([0-9]+) errors?, ([0-9]+) warnings?.*/\2/' <<<"$lint_summary")"
fi
if [[ ! "$lint_errors" =~ ^[0-9]+$ || ! "$lint_warnings" =~ ^[0-9]+$ ]]; then
  echo "Unable to parse Android lint summary: $lint_summary" >&2
  exit 1
fi
if (( lint_errors > 0 || lint_warnings > maximum_lint_warnings )); then
  echo "Android lint failed: $lint_summary (maximum warnings: $maximum_lint_warnings)" >&2
  exit 1
fi
echo "Android lint: $lint_summary"

echo "[5/6] Android arm64 release APK"
# Flutter 3.41 generates one registrant for all build modes, while the
# integration_test Android implementation is debug-only. Keep every production
# plugin registered and remove only that debug-only entry for the release build.
python3 tool/prepare_android_release_registrant.py
flutter build apk --release --split-per-abi --target-platform android-arm64 --no-pub

echo "[6/6] APK package and signature"
apk_path="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
android_sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$android_sdk_root" ]] && command -v flutter >/dev/null 2>&1; then
  android_sdk_root="$(flutter doctor -v | sed -n 's/.*Android SDK at //p' | head -n 1)"
fi
build_tools="$(find "$android_sdk_root/build-tools" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
"$build_tools/aapt" dump badging "$apk_path" | sed -n '1p'
"$build_tools/apksigner" verify --verbose "$apk_path"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$apk_path"
else
  sha256sum "$apk_path"
fi

echo "Android health check passed."

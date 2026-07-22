#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apk_path="${1:-$project_root/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk}"
package_name="com.ly.yours"
fixture="$project_root/tool/fixtures/android-acceptance.exercise.json"
inbox="/sdcard/Documents/有思/YoursVault/inbox"
acceptance_name="android-acceptance-$(date +%Y%m%d%H%M%S).exercise.json"
acceptance_archive="$inbox/imported/$acceptance_name"

start_fallback_emulator() {
  local sdk_root emulator_bin selected_avd booted
  sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
  emulator_bin="$sdk_root/emulator/emulator"
  if [[ ! -x "$emulator_bin" ]]; then
    echo "No Android device is online and the Android emulator is unavailable." >&2
    return 1
  fi
  selected_avd="${YOURS_ANDROID_AVD:-$($emulator_bin -list-avds | head -n 1)}"
  if [[ -z "$selected_avd" ]]; then
    echo "No Android device is online and no AVD is configured." >&2
    return 1
  fi
  echo "No physical device is online; starting emulator AVD: $selected_avd"
  "$emulator_bin" -avd "$selected_avd" -no-window -no-audio -no-snapshot-save \
    >"${TMPDIR:-/tmp}/yours-android-emulator.log" 2>&1 &
  adb wait-for-device
  booted=""
  for _ in $(seq 1 120); do
    booted="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    [[ "$booted" == "1" ]] && break
    sleep 1
  done
  if [[ "$booted" != "1" ]]; then
    echo "Android emulator did not finish booting." >&2
    return 1
  fi
}

devices=($(adb devices | awk 'NR > 1 && $2 == "device" {print $1}'))
if (( ${#devices[@]} == 0 )); then
  start_fallback_emulator || exit 2
  devices=($(adb devices | awk 'NR > 1 && $2 == "device" {print $1}'))
fi

serial=""
for candidate in "${devices[@]}"; do
  if [[ "$(adb -s "$candidate" shell getprop ro.kernel.qemu | tr -d '\r')" != "1" ]]; then
    serial="$candidate"
    break
  fi
done
serial="${serial:-${devices[0]}}"
echo "Using Android target: $serial"

existing="$(adb -s "$serial" shell "find '$inbox' -maxdepth 1 -type f \( -iname '*.plan.json' -o -iname '*.exercise.json' \) -print" 2>/dev/null | tr -d '\r')"
if [[ -n "$existing" ]]; then
  echo "Inbox already contains import files; refusing to mix acceptance data with user data:" >&2
  echo "$existing" >&2
  exit 3
fi

adb -s "$serial" install -r "$apk_path"
adb -s "$serial" logcat -c
adb -s "$serial" shell input keyevent KEYCODE_WAKEUP
adb -s "$serial" shell wm dismiss-keyguard
adb -s "$serial" shell input keyevent KEYCODE_HOME
sleep 1
adb -s "$serial" shell am force-stop "$package_name"
adb -s "$serial" shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 4
if ! adb -s "$serial" shell pidof "$package_name" >/dev/null; then
  echo "Application process exited during cold start." >&2
  exit 4
fi

python3 "$project_root/tool/android_tap_semantics.py" "$serial" 用户 User ユーザー
sleep 1
python3 "$project_root/tool/android_tap_semantics.py" "$serial" 数据管理 "Data management" データ管理
sleep 1

adb -s "$serial" push "$fixture" "$inbox/$acceptance_name" >/dev/null
python3 "$project_root/tool/android_tap_semantics.py" "$serial" "导入 inbox" "Import inbox" "inboxをインポート"
sleep 4

top_activity="$(adb -s "$serial" shell dumpsys activity activities | sed -n 's/.*topResumedActivity=//p' | head -n 1)"
if [[ "$top_activity" != *"$package_name"* ]]; then
  echo "Unexpected foreground activity after import: $top_activity" >&2
  exit 4
fi
adb -s "$serial" shell test -f "$acceptance_archive"

python3 "$project_root/tool/android_tap_semantics.py" "$serial" "导入 inbox" "Import inbox" "inboxをインポート"
sleep 2
adb -s "$serial" shell input keyevent 3
sleep 1
adb -s "$serial" shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3

if adb -s "$serial" logcat -d -v brief | grep -Eiq \
  'FATAL EXCEPTION|Fatal signal|SIGSEGV|ANR in com\.ly\.yours|PlatformException|VAULT_IMPORT_COMPLETE_FAILED'; then
  echo "Runtime acceptance found a fatal Android error." >&2
  exit 5
fi

adb -s "$serial" shell rm "$acceptance_archive"
echo "Android runtime acceptance passed on $serial."

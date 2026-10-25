# Release Record: Android 1.11.7+11178

Date: 2026-10-25. Release owner: LY.

## Identity and artifacts

- App: `com.ly.yours`, versionName `1.11.7`, product build `11178`, arm64 APK versionCode `13178`.
- Public source tag: `v1.11.7-public-source.1`, commit `26db5dcd35f220792ff71769e725f6e4827456e4`.
- APK: `Yours-android-arm64-v8a-1.11.7+11178.apk`, 28,087,220 bytes.
- APK SHA-256: `4033873dbf5a72086345224f2bb2f337ed39b741d9759eb58fce099889d063c4`.
- Source archive: `Yours-source-1.11.7+11178.tar.gz`, SHA-256 `c8d384e7f9e461e00fa633c8d4a996234dfc457fd1f371c3598ed0e63f3f61bf`.
- [GitHub Release](https://github.com/Maqiaogongmin/YoursVault/releases/tag/v1.11.7%2B11178).
- [Official download](https://yours-app.uk/downloads/android).

## Validation

- Flutter analyze: no issues. Flutter tests: 182 passed.
- APK Signature Scheme v2 verified. Pixel 8 / Android 16 / API 36 / arm64-v8a emulator.
- Exact release APK upgraded from 1.11.6 (13176); cold start and second cold start passed.
- Home, Plans, Exercises and Profile displayed; Vault plan import and workout export passed.
- Two occurrences of bench press in one training session independently retained 40 kg × 8 and 55 kg × 8 in the exported workout.
- Replaced the third action with squat, 70 kg × 6, rest 30 s; force-stop, cold start and resume retained all parameters, then saved successfully.
- Background/resume passed. No Android fatal exception, native fatal signal, Flutter error or app ANR was found in the bounded runtime log.
- Current release was not tested on a physical Android device.
- All 141 tracked lib/assets files matched the public product source.

## Publication verification

- GitHub assets expose the APK and source hashes above.
- Official download was downloaded again and its SHA-256 matched the APK above.
- `/latest.json` advertises version 1.11.7, product build 11178 and the official download route.
- Website build and 40 existing website checks passed; privacy page remained HTTP 200.

# Release Checklist

This checklist standardizes evidence collection for every Yours iOS or Android release. It does not replace platform-specific signing, App Store Connect, or GitHub Release work; it fixes the minimum proof that must exist before a binary is treated as an official release artifact.

## Release boundaries

Treat each step as separate. Do not describe a later step as complete until it has been checked directly.

- Build created locally or in CI.
- App Store Connect upload accepted and visible.
- TestFlight group assignment completed.
- Beta review submitted or approved.
- App Store review submitted or approved.
- Android APK attached to GitHub Release or another public channel.
- Source archive and release notes published.

This project does not require all platforms to ship at the same time, but every shipped platform must have its own evidence in the release record.

## Before building

1. Confirm the working tree is clean.
2. Confirm `pubspec.yaml` contains the intended `version+build` value.
3. Confirm `CHANGELOG.md` has a section for the version or that the release is still intentionally tracked under `Unreleased`.
4. Choose the immutable release tag name, normally `v<version>+<build>`.
5. Run the release readiness check:

```sh
dart run tool/check_release_ready.dart --version <version> --build <build> --tag <tag>
```

The check is read-only. It must not be used as proof that signing, upload, review, or publication has happened.

## iOS release evidence

Record the following in a release record before claiming an iOS release is complete:

- App display version and iOS build number.
- Source commit and release tag.
- IPA path, if the IPA is archived locally.
- IPA SHA-256, if the IPA is available.
- App Store Connect app ID.
- App Store version state.
- Attached build ID and processing state.
- TestFlight group name, if distributed to testers.
- Beta review or App Store review state, if submitted.

Use `--ios-ipa <path>` when a local IPA should be hashed:

```sh
dart run tool/check_release_ready.dart --version <version> --build <build> --tag <tag> --ios-ipa <path>
```

## Android release evidence

Record the following before claiming an Android release is complete:

- App display version and Android versionCode.
- Source commit and release tag.
- APK path.
- APK SHA-256.
- Android emulator model/API/ABI and cold-start result.
- USB device model/API/ABI and upgrade-install result, when a device is available.
- Runtime log result and screenshots for Home, Plans, Exercises, Profile, and updated critical flows.
- GitHub Release URL or other public download URL.
- Source archive URL.

Use `--android-apk <path>` when a local APK should be hashed:

```sh
dart run tool/check_release_ready.dart --version <version> --build <build> --tag <tag> --android-apk <path>
```

### Android runtime acceptance

Static APK metadata and signing checks are necessary but not sufficient. The exact APK that will be handed to a tester must pass runtime acceptance before it is described as a candidate:

1. Run the release build without `--no-pub` so Flutter refreshes the release plugin registrant and excludes dev-only plugins correctly.
2. Verify package name, versionCode, versionName, ABI contents, signature, and SHA-256.
3. Install that exact APK on an Android emulator matching the APK ABI. Clear emulator app data, cold-start the launcher activity, confirm the process remains alive, and scan `logcat` for Java, Flutter, and native fatal errors.
4. Visually verify Home, Plans, Exercises, Profile, and every critical flow changed by the release. Keep screenshots as evidence.
5. Force-stop and cold-start the app a second time, then verify background/resume behavior.
6. When a USB Android device is available, use `adb install -r` to preserve its app data and repeat cold start, navigation, background/resume, and fatal-log checks on the device.

Do not hand off or publish an APK when only build, `aapt`, or `apksigner` checks have passed. A successful install without a successful cold start is a failed candidate.

## After publishing

1. Fill out `docs/release-record-template.md` for the actual release.
2. Link the completed record from release notes or the public release page.
3. Verify that the published binary, checksum, source commit, and tag all match the record.
4. Keep platform status wording exact: uploaded, visible in ASC, assigned to TestFlight group, submitted for beta review, submitted for App Store review, approved, or released.

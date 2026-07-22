# Release Record: <version>+<build>

## Identity

- App version: `<x.y.z>`
- Build number / versionCode: `<number>`
- Source commit: `<full commit sha>`
- Release tag: `<tag>`
- Source archive URL: `<url>`
- Release owner: `<name>`
- Record date: `<yyyy-mm-dd>`

## Artifacts

| Platform | Artifact path | SHA-256 | Public URL |
| --- | --- | --- | --- |
| iOS | `<path or n/a>` | `<sha256 or n/a>` | `<App Store or TestFlight link>` |
| Android | `<path or n/a>` | `<sha256 or n/a>` | `<GitHub Release or download URL>` |

## Platform status

### iOS

- App Store Connect app ID: `<id>`
- ASC upload visible: `<yes/no/n/a>`
- Attached build ID: `<id or n/a>`
- Build processing state: `<state or n/a>`
- TestFlight group: `<group or n/a>`
- Beta review state: `<state or n/a>`
- App Store review state: `<state or n/a>`
- App Store release state: `<state or n/a>`

### Android

- APK published: `<yes/no/n/a>`
- Emulator model/API/ABI: `<value or n/a>`
- Emulator install and cold starts: `<pass/fail/n/a>`
- USB device model/API/ABI: `<value or n/a>`
- USB upgrade install and cold starts: `<pass/fail/n/a>`
- Main navigation visual check: `<pass/fail/n/a>`
- Updated critical flows checked: `<flows and result>`
- Runtime fatal log check: `<pass/fail/n/a>`
- GitHub Release URL: `<url or n/a>`
- Download URL: `<url or n/a>`
- Source archive attached: `<yes/no/n/a>`

## Verification

Record command results exactly enough that the release can be audited later.

```sh
dart run tool/check_release_ready.dart --version <version> --build <build> --tag <tag> --android-apk <path> --ios-ipa <path>
```

Result: `<pass/fail>`

```sh
flutter analyze
flutter test
dart run tool/check_ui_guard.dart --strict
```

Result: `<pass/fail>`

## Notes

- Release boundary notes: `<upload / ASC visible / TestFlight group / review / public release details>`
- Known retained risks: `<risks or n/a>`
- Follow-up tasks: `<tasks or n/a>`

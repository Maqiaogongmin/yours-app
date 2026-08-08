# Yours

**Your training. Your data. Your AI.**

Yours is a local-first, open-source workout tracker for iOS and Android, designed around **AI-native customization**.

The app handles the part that should stay reliable and close to the user: training plans, set-by-set logging, weight, reps, rest, notes, and the real history of what happened in training.

For customization and analysis, Yours takes a different approach from apps that bundle a proprietary AI coach. Through **Yours Vault** and **Yours Skills**, users can bring their own AI agents to create exercises, build training plans, read workout records, and analyze long-term training data.

Core workout logging works without a mandatory online account.

## How Yours works

Yours separates **training execution** from **training intelligence**.

```text
Goals · schedule · equipment · preferences
                    ↓
              Your AI agent
                    +
              Yours Skill
                    ↓
              Yours Vault
                    ↓
        Exercises and training plan
                    ↓
                Yours App
                    ↓
          Real workout records
                    ↓
              Yours Vault
                    ↓
        Analysis and next cycle
```

Yours intentionally ships with only a small built-in exercise set. Users can build an exercise library that matches how they actually train instead of depending on a giant universal catalog.

Creating exercises and plans one item at a time can be tedious. Yours Skills are designed to move that repetitive setup work to AI: give an agent access to Yours Vault, load the Yours Skill, describe your goals and constraints, and let it follow the Skill to prepare compatible exercises or training plans.

After training, the same workflow can be used to read exported records, analyze progress, and help prepare the next training cycle.

**AI plans and analyzes. Yours records reality.**

## Core principles

- **Local-first** — workout data is written to local SQLite first and core logging does not depend on an online account.
- **User-controlled data** — backup, restore, Yours Vault export, and optional self-hosted sync are available.
- **Open source** — the main Flutter app source is published in this repository.
- **AI-native customization** — users can bring their own AI tools instead of depending on a proprietary built-in coach.
- **Reviewable integration** — external tools work through structured files or the public sync protocol instead of modifying the app database directly.
- **Mobile-first** — iOS and Android are the officially maintained targets.

## Features

- Training plans and training days
- Set-by-set workout logging
- Weight, reps, completion status, and notes
- Rest timer
- Custom exercise library
- Standard and free-form activity logging
- Training history
- Local backup and restore
- Yours Vault import/export workflows
- Yours Skills for AI-guided exercise creation, planning, and analysis
- Optional self-hosted sync
- Simplified Chinese, English, and Japanese interfaces

## Downloads

### iPhone

Yours is available on the App Store:

https://apps.apple.com/app/id6772104994

### Android

Android builds are distributed through the official website and GitHub Releases:

https://yours-app.uk

https://github.com/Maqiaogongmin/YoursVault/releases

For APK installs, use the official sources above and verify the published SHA-256 checksum when available.

## Repository map

Yours is split into several public repositories with different responsibilities:

- **Main app — this repository**  
  Flutter source code for the iOS and Android app.  
  https://github.com/Maqiaogongmin/yours-app

- **YoursVault**  
  Releases, download information, version notes, the Yours Vault file protocol, and Agent Skills.  
  https://github.com/Maqiaogongmin/YoursVault

- **Yours Sync Server**  
  Optional self-hosted synchronization server.  
  https://github.com/Maqiaogongmin/yours-sync-server

## Yours Vault and Yours Skills

**Yours Vault** is the structured exchange layer between the app and external tools.

It supports:

- backup and restore
- training-plan import and export
- exercise-library import and export
- training-record export and analysis
- reviewable `inbox/` imports

**Yours Skills** are Markdown-based instructions that teach AI agents how to work with this structure.

A typical workflow is simple:

```text
User asks an AI agent to access Yours Vault
        ↓
Agent loads the Yours Skill
        ↓
Agent follows the Skill to generate exercises / plans
or read and analyze training records
        ↓
Generated files are placed in the Vault / inbox
        ↓
Yours validates and imports them
```

The app's internal database is not an external integration API. External tools should work through Yours Vault or the published sync protocol rather than modifying the app database directly.

## Development

Requirements:

- Flutter stable
- Dart `>=3.10.0 <4.0.0`
- macOS and Xcode for iOS builds
- Android SDK for Android builds

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Main directories:

- `lib/redesign/` — current app, data layer, and screens
- `assets/data/` — built-in exercise seed data and blank demo data
- `tool/yours_cli/` — local tooling for Yours Vault and agent workflows
- `test/` — data, sync, platform, and UI behavior tests

`pubspec.yaml` keeps `publish_to: "none"` to prevent accidental publication to pub.dev.

## Supported platforms

Officially maintained and released:

- iOS
- Android

Optional self-hosted synchronization uses:

- `protocolVersion: 2`
- `identityMode: syncId`

Unused desktop runners without an official release history are not part of the supported scope of this repository.

## License

This project as a whole is released under the **GNU Affero General Public License v3.0 or later**, together with the [App Store Additional Permission](APP_STORE_EXCEPTION.md).

The official App Store build may be distributed commercially. This does not remove a recipient's AGPL rights to obtain, modify, and redistribute the corresponding source code.

See:

- [SOURCE_RELEASE_POLICY.md](SOURCE_RELEASE_POLICY.md)
- [NOTICE.md](NOTICE.md)
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Yours originally grew from code and engineering practices in the open-source [wger](https://github.com/wger-project/flutter) fitness project, followed by substantial restructuring, rewriting, and a different product direction. Attribution and third-party notices are documented in the files above.

## Contributing

Bug reports and feature suggestions are welcome through GitHub Issues.

Pull requests may be submitted, but the project does not currently guarantee review or merge. See [CONTRIBUTING.md](CONTRIBUTING.md).

For security issues, follow [SECURITY.md](SECURITY.md) and report them privately. Do not publish secrets, authentication bypasses, or sensitive data-exposure details in public issues.

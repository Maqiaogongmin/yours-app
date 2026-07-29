#!/bin/bash
set -euo pipefail

echo "Xcode Cloud: preparing Flutter dependencies"

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_HOME="${HOME}/flutter"

cd "$REPO_ROOT"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter precache --ios
flutter pub get

cd "$REPO_ROOT/ios"
pod install --repo-update

echo "Xcode Cloud: Flutter dependencies ready"

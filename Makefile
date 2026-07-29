FLUTTER_OH_HOME ?= $(HOME)/Developer/flutter-oh/flutter_oh_3_41_9
DEVECO_SDK_HOME ?= /Applications/DevEco-Studio.app/Contents/sdk
HARMONY_PUB_CACHE ?= .dart_tool/pub-cache-ohos

yours-cli-install:
	@mkdir -p "$$HOME/.local/bin"
	@ln -sf "$(CURDIR)/tool/yours_cli/yours_cli.py" "$$HOME/.local/bin/yours-cli"
	@chmod +x "$(CURDIR)/tool/yours_cli/yours_cli.py"
	@echo "Installed yours-cli to $$HOME/.local/bin/yours-cli"

l10n-generate:
	dart run localization/tools/generate.dart
	flutter gen-l10n

l10n-check:
	dart run localization/tools/validate.dart
	dart run localization/tools/generate.dart
	flutter gen-l10n
	@git diff --exit-code -- lib/l10n lib/redesign/localization/generated_language_registry.dart lib/redesign/localization/generated_built_in_exercises.dart ios/Runner android/app/src/main/res ohos/AppScope/resources ohos/entry/src/main/resources

harmony-flutter-check:
	dart run tool/check_harmony_flutter_ready.dart

harmony-flutter-bootstrap-deps:
	dart run tool/bootstrap_harmony_flutter_deps.dart

harmony-flutter-pub-get: harmony-flutter-bootstrap-deps
	FLUTTER_GIT_URL=https://atomgit.com/openharmony-tpc/flutter_flutter.git \
	PATH="$(FLUTTER_OH_HOME)/bin:$$PATH" \
	DEVECO_SDK_HOME="$(DEVECO_SDK_HOME)" \
	PUB_CACHE="$(HARMONY_PUB_CACHE)" \
	flutter pub get

harmony-flutter-patch-deps:
	PUB_CACHE="$(HARMONY_PUB_CACHE)" dart run tool/patch_harmony_pub_cache.dart

harmony-flutter-build-debug:
	FLUTTER_GIT_URL=https://atomgit.com/openharmony-tpc/flutter_flutter.git \
	PATH="$(FLUTTER_OH_HOME)/bin:$$PATH" \
	DEVECO_SDK_HOME="$(DEVECO_SDK_HOME)" \
	PUB_CACHE="$(HARMONY_PUB_CACHE)" \
	flutter build hap --debug --no-codesign

harmony-flutter-build-release:
	FLUTTER_GIT_URL=https://atomgit.com/openharmony-tpc/flutter_flutter.git \
	PATH="$(FLUTTER_OH_HOME)/bin:$$PATH" \
	DEVECO_SDK_HOME="$(DEVECO_SDK_HOME)" \
	PUB_CACHE="$(HARMONY_PUB_CACHE)" \
	flutter build hap --release --no-codesign

harmony-flutter-run:
	FLUTTER_GIT_URL=https://atomgit.com/openharmony-tpc/flutter_flutter.git \
	PATH="$(FLUTTER_OH_HOME)/bin:$$PATH" \
	DEVECO_SDK_HOME="$(DEVECO_SDK_HOME)" \
	PUB_CACHE="$(HARMONY_PUB_CACHE)" \
	flutter run -d 127.0.0.1:5555

harmony-release-app:
	python3 tool/harmony_release_pipeline.py --allow-dirty --note "local HarmonyOS release build"

harmony-release-app-clean:
	python3 tool/harmony_release_pipeline.py --note "clean HarmonyOS release build"

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
	@git diff --exit-code -- lib/l10n lib/redesign/localization/generated_language_registry.dart lib/redesign/localization/generated_built_in_exercises.dart ios/Runner android/app/src/main/res

library;

import 'package:flutter/widgets.dart';
import 'package:yours/l10n/app_localizations.dart';

extension YoursLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

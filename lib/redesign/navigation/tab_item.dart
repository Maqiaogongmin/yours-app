/// Defines the four main navigation tabs.
library;

import 'package:yours/l10n/app_localizations.dart';

enum TabItem {
  home(
    iconAsset: 'assets/icons/tab_home.svg',
  ),
  plan(
    iconAsset: 'assets/icons/tab_plan.svg',
  ),
  exercises(
    iconAsset: 'assets/icons/tab_library.svg',
  ),
  profile(
    iconAsset: 'assets/icons/tab_profile.svg',
  )
  ;

  const TabItem({
    required this.iconAsset,
  });

  final String iconAsset;

  String label(AppLocalizations l10n) => switch (this) {
    TabItem.home => l10n.tabHome,
    TabItem.plan => l10n.tabPlan,
    TabItem.exercises => l10n.tabExercises,
    TabItem.profile => l10n.tabProfile,
  };
}

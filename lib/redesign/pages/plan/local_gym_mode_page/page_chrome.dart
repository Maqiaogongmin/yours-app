part of '../local_gym_mode_page.dart';

String _formatLocalGymDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

PreferredSizeWidget _localGymAppBar(
  BuildContext context,
  String title, {
  required LocalGymSessionController session,
  required VoidCallback onBack,
  required VoidCallback onEnd,
}) {
  final palette = context.yoursPalette;
  return AppBar(
    backgroundColor: palette.surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: Border(bottom: BorderSide(color: palette.border)),
    foregroundColor: Colors.white,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.fg),
      onPressed: onBack,
    ),
    title: Text(
      title,
      style: context
          .yoursText(YoursTextRole.body)
          .copyWith(color: palette.fg, fontWeight: FontWeight.w700),
    ),
    actions: [
      if (session.hasActions && !session.isFinished)
        IconButton(
          tooltip: context.l10n.workoutEnd,
          icon: Icon(Icons.close, color: palette.fg, size: 28),
          onPressed: session.isSaving ? null : onEnd,
        ),
    ],
  );
}

part of 'yours_workout_share_poster_page.dart';

class _BackgroundSection extends StatelessWidget {
  const _BackgroundSection({
    required this.selected,
    required this.hasPhoto,
    required this.expanded,
    required this.onToggle,
    required this.onPresetSelected,
    required this.onPhotoSelected,
  });

  final YoursSharePosterPreset? selected;
  final bool hasPhoto;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<YoursSharePosterPreset> onPresetSelected;
  final VoidCallback onPhotoSelected;

  @override
  Widget build(BuildContext context) {
    return _CollapsibleShareSection(
      title: context.l10n.sharePosterBackground,
      expanded: expanded,
      onToggle: onToggle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final preset in YoursSharePosterPreset.values)
            _ShareChoiceChip(
              label: Text(_presetLabel(context.l10n, preset)),
              selected: selected == preset && !hasPhoto,
              onSelected: () => onPresetSelected(preset),
            ),
          _ShareChoiceChip(
            avatar: Icons.photo_outlined,
            label: Text(
              hasPhoto ? context.l10n.sharePosterPhotoSelected : context.l10n.sharePosterUsePhoto,
            ),
            selected: hasPhoto,
            onSelected: onPhotoSelected,
          ),
        ],
      ),
    );
  }
}

class _ComponentSection extends StatelessWidget {
  const _ComponentSection({
    required this.data,
    required this.options,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<YoursSharePosterOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final noteAvailable = data.note.trim().isNotEmpty;
    return _CollapsibleShareSection(
      title: l10n.sharePosterComponents,
      expanded: expanded,
      onToggle: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SwitchRow(
            label: l10n.sharePosterWorkoutName,
            value: options.showWorkoutName,
            onChanged: (value) => onChanged(options.copyWith(showWorkoutName: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterDate,
            value: options.showDate,
            onChanged: (value) => onChanged(options.copyWith(showDate: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterDuration,
            value: options.showDuration,
            onChanged: (value) => onChanged(options.copyWith(showDuration: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterExerciseCount,
            value: options.showExerciseCount,
            onChanged: (value) => onChanged(options.copyWith(showExerciseCount: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterSetCount,
            value: options.showSetCount,
            onChanged: (value) => onChanged(options.copyWith(showSetCount: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterTotalVolume,
            value: options.showVolume,
            onChanged: (value) => onChanged(options.copyWith(showVolume: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterNote,
            value: options.showNote && noteAvailable,
            enabled: noteAvailable,
            onChanged: (value) => onChanged(options.copyWith(showNote: value)),
          ),
          _SwitchRow(
            label: l10n.sharePosterBrand,
            value: options.showBrand,
            onChanged: (value) => onChanged(options.copyWith(showBrand: value)),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleShareSection extends StatelessWidget {
  const _CollapsibleShareSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return YoursSurfaceCard(
      role: YoursSurfaceRole.controlOverlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.input)),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: context.yoursTextOnSurface(
                          YoursSurfaceRole.controlOverlay,
                          YoursTextRole.cardTitle,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.yoursSurfaceMuted(YoursSurfaceRole.controlOverlay),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: child,
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ShareChoiceChip extends StatelessWidget {
  const _ShareChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? avatar;

  @override
  Widget build(BuildContext context) {
    final surface = context.yoursSurface(YoursSurfaceRole.controlOverlay);
    final fg = context.yoursSurfaceForeground(YoursSurfaceRole.controlOverlay);
    final muted = context.yoursSurfaceMuted(YoursSurfaceRole.controlOverlay);
    final accent = context.yoursTone(YoursTone.accent);
    final border = context.yoursSurfaceBorder(YoursSurfaceRole.controlOverlay);
    return ChoiceChip(
      avatar: avatar == null ? null : Icon(avatar, size: 18, color: selected ? accent : muted),
      label: DefaultTextStyle.merge(
        style: context
            .yoursTextOnSurface(YoursSurfaceRole.controlOverlay, YoursTextRole.button)
            .copyWith(color: selected ? accent : fg),
        child: label,
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: surface,
      selectedColor: accent.withValues(alpha: 0.14),
      disabledColor: surface,
      side: BorderSide(color: selected ? accent.withValues(alpha: 0.52) : border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.status)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: context.yoursTextOnSurface(YoursSurfaceRole.controlOverlay, YoursTextRole.body),
      ),
      activeThumbColor: context.yoursTone(YoursTone.accent),
      inactiveThumbColor: context.yoursSurfaceMuted(YoursSurfaceRole.controlOverlay),
      inactiveTrackColor: context.yoursSurfaceBorder(YoursSurfaceRole.controlOverlay),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

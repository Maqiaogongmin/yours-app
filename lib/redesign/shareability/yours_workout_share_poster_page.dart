import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yours/l10n/app_localizations.dart';
import 'package:yours/redesign/data/local_training_models.dart';
import 'package:yours/redesign/data/local_training_repository.dart';
import 'package:yours/redesign/design_system/yours_design_system.dart';
import 'package:yours/redesign/localization/localization.dart';
import 'package:yours/redesign/shareability/yours_share_models.dart';
import 'package:yours/redesign/shareability/yours_share_platform.dart';

class YoursWorkoutSharePosterPage extends StatefulWidget {
  const YoursWorkoutSharePosterPage({
    super.key,
    required this.data,
    this.platform,
    this.exportPosterBytes,
  });

  final YoursWorkoutShareData data;
  final YoursSharePlatform? platform;
  final Future<Uint8List> Function(GlobalKey posterKey, BuildContext context)? exportPosterBytes;

  @override
  State<YoursWorkoutSharePosterPage> createState() => _YoursWorkoutSharePosterPageState();
}

class _YoursWorkoutSharePosterPageState extends State<YoursWorkoutSharePosterPage> {
  final _posterKey = GlobalKey();
  late final YoursSharePlatform _platform;
  var _options = const YoursSharePosterOptions();
  var _saving = false;
  var _backgroundExpanded = false;
  var _componentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _platform = widget.platform ?? YoursSharePlatform();
    final note = widget.data.note.trim();
    if (note.isEmpty) {
      _options = _options.copyWith(showNote: false);
    }
  }

  Future<void> _pickPhotoBackground() async {
    try {
      final path = await _platform.pickPosterBackground();
      if (!mounted || path == null || path.trim().isEmpty) {
        return;
      }
      setState(() {
        _options = _options.copyWith(photoPath: path, preset: YoursSharePosterPreset.deepPurple);
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.sharePosterPhotoFailed(error.message ?? error.code));
    }
  }

  Future<void> _savePoster() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final bytes = await (widget.exportPosterBytes ?? _defaultExportPosterBytes)(
        _posterKey,
        context,
      );
      await _platform.savePosterToPhotos(bytes);
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.sharePosterSavedToPhotos);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.sharePosterSaveFailed('$error'));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<Uint8List> _defaultExportPosterBytes(GlobalKey posterKey, BuildContext context) async {
    final renderFailed = context.l10n.sharePosterRenderFailed;
    final boundary = posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.size.isEmpty) {
      throw StateError(renderFailed);
    }
    final pixelRatio = 1080 / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw StateError(renderFailed);
    }
    return bytes;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewMatte = context.yoursSharePreviewMatte;
    final previewForeground = Theme.of(context).brightness == Brightness.light
        ? context.yoursSurfaceForeground(YoursSurfaceRole.page)
        : Colors.white;
    return Scaffold(
      backgroundColor: previewMatte,
      appBar: AppBar(
        backgroundColor: previewMatte,
        foregroundColor: previewForeground,
        elevation: 0,
        title: Text(
          context.l10n.sharePosterTitle,
          style: context.yoursText(YoursTextRole.cardTitle).copyWith(color: previewForeground),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.sharePosterSaveToPhotos,
            onPressed: _saving ? null : _savePoster,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: RepaintBoundary(
                key: _posterKey,
                child: YoursWorkoutSharePoster(data: widget.data, options: _options),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _BackgroundSection(
            selected: _options.hasPhotoBackground ? null : _options.preset,
            hasPhoto: _options.hasPhotoBackground,
            expanded: _backgroundExpanded,
            onToggle: () => setState(() => _backgroundExpanded = !_backgroundExpanded),
            onPresetSelected: (preset) {
              setState(() => _options = _options.copyWith(preset: preset, clearPhotoPath: true));
            },
            onPhotoSelected: _pickPhotoBackground,
          ),
          const SizedBox(height: 14),
          _ComponentSection(
            data: widget.data,
            options: _options,
            expanded: _componentsExpanded,
            onToggle: () => setState(() => _componentsExpanded = !_componentsExpanded),
            onChanged: (options) => setState(() => _options = options),
          ),
          const SizedBox(height: 18),
          YoursTonalAction(
            icon: Icons.file_download_outlined,
            label: _saving ? context.l10n.sharePosterSaving : context.l10n.sharePosterSaveToPhotos,
            onPressed: _saving ? null : _savePoster,
          ),
        ],
      ),
    );
  }
}

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

Future<void> openWorkoutSharePoster({
  required BuildContext context,
  required LocalTrainingRepository repository,
  required DateTime date,
  LocalTrainingDailyRecord? record,
}) async {
  final month = DateTime(date.year, date.month);
  final dayKey = DateTime(date.year, date.month, date.day);
  final records = await repository.getDailyRecordsForMonth(month);
  final dailyRecord = record ?? records[dayKey];
  if (!context.mounted || dailyRecord == null) {
    return;
  }
  final sessions = await repository.getWorkoutSessionsForDate(dayKey);
  if (!context.mounted) {
    return;
  }
  final data = YoursWorkoutShareData.fromRecord(
    record: dailyRecord,
    sessions: sessions,
    fallbackName: context.l10n.homeDefaultRecordName,
  );
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => YoursWorkoutSharePosterPage(data: data)),
  );
}

String _presetLabel(AppLocalizations l10n, YoursSharePosterPreset preset) {
  return switch (preset) {
    YoursSharePosterPreset.deepPurple => l10n.sharePosterPresetDeepPurple,
    YoursSharePosterPreset.warmPaper => l10n.sharePosterPresetWarmPaper,
    YoursSharePosterPreset.ember => l10n.sharePosterPresetEmber,
    YoursSharePosterPreset.forest => l10n.sharePosterPresetForest,
  };
}

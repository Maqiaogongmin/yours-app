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

part 'yours_workout_share_poster_sections.dart';

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

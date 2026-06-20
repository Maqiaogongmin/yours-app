import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yours/redesign/shareability/yours_share_models.dart';

class YoursWorkoutSharePoster extends StatelessWidget {
  const YoursWorkoutSharePoster({
    super.key,
    required this.data,
    required this.options,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;

  @override
  Widget build(BuildContext context) {
    final style = _PosterStyle.resolve(options);
    final palette = style.palette;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 1080,
            height: 1920,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (options.hasPhotoBackground)
                  _PhotoBackground(path: options.photoPath!, overlay: palette.photoOverlay)
                else
                  _PosterBackground(palette: palette),
                Padding(
                  padding: const EdgeInsets.fromLTRB(88, 128, 88, 110),
                  child: _PosterContent(data: data, options: options, style: style),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterContent extends StatelessWidget {
  const _PosterContent({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    final note = data.note.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PosterHeader(data: data, options: options, style: style),
        const SizedBox(height: 196),
        if (options.showWorkoutName) _PosterHero(data: data, style: style),
        const SizedBox(height: 104),
        _PosterMetrics(data: data, options: options, style: style),
        if (options.showNote && note.isNotEmpty) ...[
          const SizedBox(height: 34),
          _PosterNoteBlock(
            style: style,
            note: note,
          ),
        ],
        const Spacer(),
        if (options.showBrand) _PosterFooter(style: style),
      ],
    );
  }
}

class _PosterHeader extends StatelessWidget {
  const _PosterHeader({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.showBrand) ...[
          Row(
            children: [
              _PosterMark(style: style),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yours', style: style.brandName),
                  const SizedBox(height: 8),
                  Text('有思', style: style.brandSub),
                ],
              ),
            ],
          ),
        ],
        const Spacer(),
        if (options.showDate)
          Text(
            '${data.recordLabel}\n${_posterDate(data.date)}',
            textAlign: TextAlign.right,
            style: style.recordMeta,
          ),
      ],
    );
  }
}

class _PosterHero extends StatelessWidget {
  const _PosterHero({required this.data, required this.style});

  final YoursWorkoutShareData data;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.recordLabel, style: style.eyebrow),
        const SizedBox(height: 22),
        Text(
          data.workoutName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.title,
        ),
      ],
    );
  }
}

class _PosterMetrics extends StatelessWidget {
  const _PosterMetrics({
    required this.data,
    required this.options,
    required this.style,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;
  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      if (options.showDuration)
        _MetricCard(
          label: '总用时',
          value: '${data.duration.inMinutes}',
          unit: '分钟',
          style: style,
        ),
      if (options.showExerciseCount)
        _MetricCard(
          label: '动作数',
          value: '${data.exerciseCount}',
          unit: '个动作',
          style: style,
        ),
      if (options.showSetCount)
        _MetricCard(label: '总组数', value: '${data.setCount}', unit: '组', style: style),
    ];
    final showVolume = options.showVolume;
    if (metrics.isEmpty && !showVolume) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (metrics.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        if (showVolume) ...[
          if (metrics.isNotEmpty) const SizedBox(height: 16),
          _MetricCard(
            label: '总容量',
            value: _formatVolume(data.totalVolume),
            unit: 'kg',
            style: style,
            wide: true,
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.style,
    this.wide = false,
  });

  final String label;
  final String value;
  final String unit;
  final _PosterStyle style;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final valueText = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, style: wide ? style.wideMetricValue : style.metricValue),
          ),
        ),
        const SizedBox(width: 10),
        Text(unit, style: style.metricUnit),
      ],
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: wide ? 132 : 126),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(label, style: style.metricLabel),
                ),
                const Spacer(),
                Expanded(
                  flex: 4,
                  child: Align(alignment: Alignment.bottomRight, child: valueText),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(label, style: style.metricLabel),
                const SizedBox(height: 20),
                valueText,
              ],
            ),
    );
  }
}

class _PosterNoteBlock extends StatelessWidget {
  const _PosterNoteBlock({
    required this.style,
    required this.note,
  });

  final _PosterStyle style;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            style.softTextBackdrop,
            style.softTextBackdrop.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 44, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRAINING NOTE', style: style.noteLabel),
            const SizedBox(height: 18),
            Text(note, maxLines: 4, overflow: TextOverflow.ellipsis, style: style.noteText),
          ],
        ),
      ),
    );
  }
}

class _PosterFooter extends StatelessWidget {
  const _PosterFooter({required this.style});

  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '完成',
                    style: TextStyle(color: style.accent),
                  ),
                  const TextSpan(text: ' · 由有思记录'),
                ],
              ),
              style: style.footerTitle,
            ),
            const SizedBox(height: 12),
            Text('Recorded with Yours', style: style.footerSub),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Text('清晰记录，长期保存', style: style.miniRow),
          ],
        ),
      ],
    );
  }
}

class _PosterMark extends StatelessWidget {
  const _PosterMark({required this.style});

  final _PosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: style.markShadow, blurRadius: 42, offset: const Offset(0, 16)),
        ],
      ),
      child: CustomPaint(painter: _PosterMarkPainter(style.accent)),
    );
  }
}

class _PosterMarkPainter extends CustomPainter {
  const _PosterMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.31, size.height * 0.68)
      ..lineTo(size.width * 0.31, size.height * 0.51)
      ..lineTo(size.width * 0.50, size.height * 0.30)
      ..lineTo(size.width * 0.69, size.height * 0.51)
      ..lineTo(size.width * 0.69, size.height * 0.68);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.24),
      size.width * 0.045,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PosterMarkPainter oldDelegate) => oldDelegate.color != color;
}

class _PosterGrain extends StatelessWidget {
  const _PosterGrain({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PosterGrainPainter(color));
  }
}

class _PosterGrainPainter extends CustomPainter {
  const _PosterGrainPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, size.height * 0.09), Offset(x, size.height * 0.92), paint);
    }
    for (double y = size.height * 0.09; y < size.height * 0.92; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PosterGrainPainter oldDelegate) => oldDelegate.color != color;
}

class _PhotoBackground extends StatelessWidget {
  const _PhotoBackground({required this.path, required this.overlay});

  final String path;
  final Color overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(path), fit: BoxFit.cover),
        DecoratedBox(decoration: BoxDecoration(color: overlay)),
      ],
    );
  }
}

class _PosterBackground extends StatelessWidget {
  const _PosterBackground({required this.palette});

  final YoursSharePosterPalette palette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: palette.baseGradient)),
        for (final glow in palette.glows)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: glow.center,
                radius: glow.radius,
                colors: [glow.color, glow.color.withValues(alpha: 0)],
                stops: const [0, 1],
              ),
            ),
          ),
        if (palette.showGrain) _PosterGrain(color: palette.grain),
      ],
    );
  }
}

@immutable
class YoursSharePosterPalette {
  const YoursSharePosterPalette({
    required this.baseGradient,
    required this.glows,
    required this.panel,
    required this.border,
    required this.fg,
    required this.muted,
    required this.accent,
    required this.shadow,
    required this.markShadow,
    required this.grain,
    required this.photoOverlay,
    required this.textShadow,
    required this.softTextBackdrop,
    required this.showGrain,
  });

  final Gradient baseGradient;
  final List<YoursSharePosterGlow> glows;
  final Color panel;
  final Color border;
  final Color fg;
  final Color muted;
  final Color accent;
  final Color shadow;
  final Color markShadow;
  final Color grain;
  final Color photoOverlay;
  final Color textShadow;
  final Color softTextBackdrop;
  final bool showGrain;
}

class YoursSharePosterGlow {
  const YoursSharePosterGlow({
    required this.center,
    required this.radius,
    required this.color,
  });

  final AlignmentGeometry center;
  final double radius;
  final Color color;
}

class _PosterStyle {
  const _PosterStyle({required this.palette});

  final YoursSharePosterPalette palette;

  Color get panel => palette.panel;
  Color get border => palette.border;
  Color get fg => palette.fg;
  Color get muted => palette.muted;
  Color get accent => palette.accent;
  Color get shadow => palette.shadow;
  Color get markShadow => palette.markShadow;
  Color get softTextBackdrop => palette.softTextBackdrop;
  List<Shadow> get textShadow => [
    Shadow(color: palette.textShadow, blurRadius: 18, offset: const Offset(0, 6)),
  ];

  static _PosterStyle resolve(YoursSharePosterOptions options) {
    if (options.hasPhotoBackground) {
      return _dark(_deepPurpleBase(), showGrain: false, glows: const [], panelOpacity: 0.84);
    }
    return switch (options.preset) {
      YoursSharePosterPreset.warmPaper => _light(),
      YoursSharePosterPreset.deepPurple => _dark(_deepPurpleBase()),
      YoursSharePosterPreset.ember => _dark(
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171012), Color(0xFF37201A), Color(0xFF724126)],
          stops: [0, 0.48, 1],
        ),
        showGrain: false,
        glows: const [],
      ),
      YoursSharePosterPreset.forest => _dark(
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1412), Color(0xFF17231F), Color(0xFF2C4635)],
          stops: [0, 0.46, 1],
        ),
        showGrain: false,
        glows: const [],
      ),
    };
  }

  static LinearGradient _deepPurpleBase() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101016), Color(0xFF171720), Color(0xFF241B28)],
    stops: [0, 0.52, 1],
  );

  static List<YoursSharePosterGlow> _sampleGlows({bool light = false}) => [
    YoursSharePosterGlow(
      center: const Alignment(0.74, -0.78),
      radius: 0.78,
      color: (light ? const Color(0x66F0A05A) : const Color(0x59F08A42)),
    ),
    YoursSharePosterGlow(
      center: const Alignment(-0.86, 0.62),
      radius: 0.7,
      color: (light ? const Color(0x2FD8B58A) : const Color(0x22F1D9AE)),
    ),
  ];

  static _PosterStyle _light() => _PosterStyle(
    palette: YoursSharePosterPalette(
      baseGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF9EF), Color(0xFFF8F3EA), Color(0xFFEFE5D8)],
        stops: [0, 0.47, 1],
      ),
      glows: _sampleGlows(light: true),
      panel: const Color(0xE8FFFDF8),
      border: const Color(0xEBE8DED2),
      fg: const Color(0xFF1F1A17),
      muted: const Color(0xFF746A60),
      accent: const Color(0xFFD86F32),
      shadow: const Color(0x141F1A17),
      markShadow: const Color(0x1A1F1A17),
      grain: const Color(0x071F1A17),
      photoOverlay: const Color(0x88000000),
      textShadow: const Color(0x1CFFF8EC),
      softTextBackdrop: const Color(0x12FFF8EC),
      showGrain: true,
    ),
  );

  static _PosterStyle _dark(
    Gradient background, {
    double panelOpacity = 0.84,
    bool showGrain = true,
    List<YoursSharePosterGlow>? glows,
  }) => _PosterStyle(
    palette: YoursSharePosterPalette(
      baseGradient: background,
      glows: glows ?? _sampleGlows(),
      panel: const Color(0xFF242431).withValues(alpha: panelOpacity),
      border: const Color(0xF2383747),
      fg: const Color(0xFFF2F0ED),
      muted: const Color(0xFFAAA5B6),
      accent: const Color(0xFFE8793A),
      shadow: const Color(0x33000000),
      markShadow: const Color(0x38000000),
      grain: const Color(0x09F2F0ED),
      photoOverlay: const Color(0xA3000000),
      textShadow: const Color(0x7A000000),
      softTextBackdrop: const Color(0x18000000),
      showGrain: showGrain,
    ),
  );

  TextStyle get brandName =>
      TextStyle(fontSize: 31, height: 1.05, fontWeight: FontWeight.w800, color: fg);
  TextStyle get brandSub =>
      TextStyle(fontSize: 17, height: 1, fontWeight: FontWeight.w700, color: muted);
  TextStyle get recordMeta =>
      TextStyle(fontSize: 18, height: 1.55, fontWeight: FontWeight.w700, color: muted);
  TextStyle get eyebrow =>
      TextStyle(fontSize: 22, height: 1, fontWeight: FontWeight.w800, color: muted);
  TextStyle get title => TextStyle(
    fontSize: 100,
    height: 1.04,
    fontWeight: FontWeight.w900,
    color: fg,
    letterSpacing: 0,
  );
  TextStyle get summary =>
      TextStyle(fontSize: 28, height: 1.48, fontWeight: FontWeight.w600, color: muted);
  TextStyle get metricLabel =>
      TextStyle(fontSize: 19, height: 1, fontWeight: FontWeight.w800, color: muted);
  TextStyle get metricValue => TextStyle(
    fontFamily: 'RobotoCondensed',
    fontSize: 76,
    height: 0.92,
    fontWeight: FontWeight.w900,
    color: fg,
    letterSpacing: 0,
    shadows: textShadow,
  );
  TextStyle get wideMetricValue => TextStyle(
    fontFamily: 'RobotoCondensed',
    fontSize: 98,
    height: 0.92,
    fontWeight: FontWeight.w900,
    color: fg,
    letterSpacing: 0,
    shadows: textShadow,
  );
  TextStyle get metricUnit =>
      TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: muted, shadows: textShadow);
  TextStyle get noteLabel =>
      TextStyle(fontSize: 18, height: 1, fontWeight: FontWeight.w800, color: muted);
  TextStyle get noteText => TextStyle(
    fontSize: 30,
    height: 1.52,
    fontWeight: FontWeight.w600,
    color: fg,
    shadows: textShadow,
  );
  TextStyle get footerTitle =>
      TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, color: fg);
  TextStyle get footerSub =>
      TextStyle(fontSize: 18, height: 1, fontWeight: FontWeight.w700, color: muted);
  TextStyle get miniRow => TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: muted);
}

String _posterDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}

String _formatVolume(num value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

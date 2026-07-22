part of 'yours_share_poster.dart';

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

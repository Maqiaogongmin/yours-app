part of 'yours_share_poster.dart';

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

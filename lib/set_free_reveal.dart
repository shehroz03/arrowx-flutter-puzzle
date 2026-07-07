import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'shape_masks.dart';

/// "Set It Free" — after the last arrow flies out, the level's shape
/// re-assembles from glowing cells and comes alive: birds/planes fly away,
/// hearts beat, flowers bloom, gems shine, bells swing. Pseudo-3D via
/// perspective transforms.
class SetFreeReveal extends StatefulWidget {
  final String shapeName;       // display name from levels.json ('' = none)
  final Set<String> customMask; // used instead of shapeName when non-empty
  final int gridSize;
  final VoidCallback onFinished;

  const SetFreeReveal({
    super.key,
    required this.shapeName,
    required this.gridSize,
    required this.onFinished,
    this.customMask = const {},
  });

  @override
  State<SetFreeReveal> createState() => _SetFreeRevealState();
}

class _RevealCell {
  final double nx, ny; // normalized 0..1 inside the shape's bounding box
  final int colorIdx;
  final double rank;   // 0..1 distance-from-center order for the ignite wave
  _RevealCell(this.nx, this.ny, this.colorIdx, this.rank);
}

class _SetFreeRevealState extends State<SetFreeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_RevealCell> _cells = [];
  double _aspect = 1; // shape width / height
  late String _archetype;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _archetype = widget.customMask.isNotEmpty ? 'flyAway' : archetypeFor(widget.shapeName);
    _prepareCells();
    if (_cells.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished());
    } else {
      _ctrl.forward().whenComplete(() {
        if (mounted) widget.onFinished();
      });
    }
  }

  void _prepareCells() {
    final mask = widget.customMask.isNotEmpty
        ? widget.customMask
        : maskForShape(widget.shapeName, widget.gridSize);
    if (mask.isEmpty) return;
    int minX = 1 << 30, minY = 1 << 30, maxX = -1, maxY = -1;
    final pts = <List<int>>[];
    for (final c in mask) {
      final p = c.split(',');
      final x = int.parse(p[0]), y = int.parse(p[1]);
      pts.add([x, y]);
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    final w = (maxX - minX + 1).toDouble(), h = (maxY - minY + 1).toDouble();
    _aspect = w / h;
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    final maxD = math.sqrt(w * w + h * h) / 2;
    for (final p in pts) {
      final d = math.sqrt(math.pow(p[0] - cx, 2) + math.pow(p[1] - cy, 2)) / maxD;
      _cells.add(_RevealCell(
        (p[0] - minX) / w,
        (p[1] - minY) / h,
        ((p[0] * 7 + p[1] * 13) % 5),
        d.clamp(0.0, 1.0),
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cells.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => CustomPaint(
        size: Size.infinite,
        painter: _RevealPainter(
          t: _ctrl.value,
          cells: _cells,
          aspect: _aspect,
          archetype: _archetype,
        ),
      ),
    );
  }
}

class _RevealPainter extends CustomPainter {
  static const palette = [
    Color(0xFFE5B142),
    Color(0xFF4A90E2),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFF2ECC71),
  ];

  final double t;
  final List<_RevealCell> cells;
  final double aspect;
  final String archetype;
  _RevealPainter({required this.t, required this.cells, required this.aspect, required this.archetype});

  double _easeOutBack(double u) {
    const c = 1.70158;
    final v = u - 1;
    return 1 + (c + 1) * v * v * v + c * v * v;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t < 0.88 ? 1.0 : 1.0 - (t - 0.88) / 0.12;

    // Dark scrim so the shape pops
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.55 * math.min(t * 5, 1.0) * fade),
    );

    // Fit the shape's bounding box to ~72% of the screen
    final boxSide = math.min(size.width, size.height) * 0.72;
    final shapeW = aspect >= 1 ? boxSide : boxSide * aspect;
    final shapeH = aspect >= 1 ? boxSide / aspect : boxSide;
    final center = Offset(size.width / 2, size.height * 0.44);
    final u = ((t - 0.42) / 0.46).clamp(0.0, 1.0);

    // Soft halo behind the shape
    final haloR = boxSide * (0.55 + 0.1 * math.sin(u * math.pi));
    canvas.drawCircle(
      center,
      haloR,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.16 * fade),
          Colors.white.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: haloR)),
    );

    // Shine archetype: rotating light rays behind the shape
    if (archetype == 'shine' && u > 0) {
      final rayPaint = Paint()
        ..color = const Color(0xFFFFE082)
            .withValues(alpha: 0.14 * math.sin(u * math.pi) * fade)
        ..strokeWidth = boxSide * 0.09
        ..strokeCap = StrokeCap.round;
      for (int k = 0; k < 10; k++) {
        final a = k * math.pi / 5 + u * 1.6;
        canvas.drawLine(
          center + Offset(math.cos(a), math.sin(a)) * boxSide * 0.35,
          center + Offset(math.cos(a), math.sin(a)) * boxSide * 0.85,
          rayPaint,
        );
      }
    }

    // Archetype transform (pseudo-3D via perspective entries)
    final m = Matrix4.identity()..setEntry(3, 2, 0.0012);
    Offset pivotShift = Offset.zero;
    double extraFade = 1.0;
    switch (archetype) {
      case 'flyAway':
        final u2 = u * u;
        m
          ..translateByDouble(size.width * 0.38 * u2, -size.height * 0.85 * u2, 0, 1)
          ..rotateZ(-0.26 * u)
          ..rotateX(0.55 * u);
        m.scaleByDouble(1 - 0.30 * u, 1 - 0.30 * u, 1, 1);
        break;
      case 'beat':
        final pulse = math.max(0.0, math.sin(u * math.pi * 3)) * (1 - u * 0.5);
        final s = 1 + 0.13 * pulse;
        m
          ..rotateX(0.10 * pulse)
          ..scaleByDouble(s, s, 1, 1);
        break;
      case 'bloom':
        final s = 0.90 + 0.12 * Curves.easeOutBack.transform(u);
        m
          ..rotateZ(0.05 * math.sin(u * math.pi * 2))
          ..scaleByDouble(s, s, 1, 1);
        break;
      case 'shine':
        m
          ..rotateY(0.35 * math.sin(u * math.pi))
          ..scaleByDouble(1 + 0.06 * u, 1 + 0.06 * u, 1, 1);
        break;
      case 'swing':
        pivotShift = Offset(0, -shapeH / 2);
        m.rotateZ(0.30 * math.sin(u * math.pi * 3) * (1 - u));
        break;
      default: // float
        m
          ..translateByDouble(0, -10 * math.sin(u * math.pi * 2), 0, 1)
          ..rotateZ(0.05 * math.sin(u * math.pi * 2));
    }

    final pivot = center + pivotShift;
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.transform(m.storage);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Cells ignite center-out, then travel with the archetype transform
    final cellSide = math.max(shapeW / 40, math.min(shapeW, shapeH) * 0.9 /
        math.max(8, math.sqrt(cells.length)));
    final paint = Paint();
    for (final c in cells) {
      final appear = ((t - c.rank * 0.30) / 0.12).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final s = _easeOutBack(appear).clamp(0.0, 1.3);
      final pos = Offset(
        center.dx - shapeW / 2 + c.nx * shapeW,
        center.dy - shapeH / 2 + c.ny * shapeH,
      );
      paint.color = palette[c.colorIdx].withValues(alpha: (fade * extraFade).clamp(0.0, 1.0));
      final half = cellSide * 0.5 * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: half * 2, height: half * 2),
            Radius.circular(half * 0.45)),
        paint,
      );
    }
    canvas.restore();

    _drawParticles(canvas, size, center, boxSide, u, fade);
  }

  void _drawParticles(Canvas canvas, Size size, Offset center, double boxSide,
      double u, double fade) {
    if (u <= 0) return;
    final rng = math.Random(97);
    for (int i = 0; i < 16; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final speed = 0.4 + rng.nextDouble() * 0.8;
      final delay = rng.nextDouble() * 0.4;
      final pu = ((u - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (pu <= 0) continue;
      final alpha = ((1 - pu) * 0.8 * fade).clamp(0.0, 1.0);
      final col = palette[i % 5].withValues(alpha: alpha);
      final r = 4.0 + rng.nextDouble() * 4;
      Offset pos;
      switch (archetype) {
        case 'beat': // hearts float upward
          pos = center +
              Offset(math.sin(pu * 6 + i) * 20 + (ang - math.pi) * boxSide * 0.12,
                  -pu * boxSide * (0.5 + speed * 0.4));
          _heart(canvas, pos, r, col);
          break;
        case 'bloom': // petals burst outward
          pos = center + Offset(math.cos(ang), math.sin(ang)) * pu * boxSide * (0.45 + speed * 0.3);
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(ang + pu * 4);
          canvas.drawOval(
              Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r), Paint()..color = col);
          canvas.restore();
          break;
        default: // sparkles drifting out
          pos = center + Offset(math.cos(ang), math.sin(ang)) * pu * boxSide * (0.5 + speed * 0.3);
          _sparkle(canvas, pos, r, col, pu * 5);
      }
    }
  }

  void _heart(Canvas canvas, Offset c, double r, Color col) {
    final p = Path()
      ..moveTo(c.dx, c.dy + r * 0.9)
      ..cubicTo(c.dx - r * 1.4, c.dy - r * 0.1, c.dx - r * 0.7, c.dy - r * 1.1, c.dx, c.dy - r * 0.35)
      ..cubicTo(c.dx + r * 0.7, c.dy - r * 1.1, c.dx + r * 1.4, c.dy - r * 0.1, c.dx, c.dy + r * 0.9);
    canvas.drawPath(p, Paint()..color = col);
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color col, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final paint = Paint()
      ..color = col
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      canvas.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * r * 1.4, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RevealPainter old) => old.t != t;
}

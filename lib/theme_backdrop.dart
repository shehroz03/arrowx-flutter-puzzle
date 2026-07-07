import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'settings_provider.dart';

/// Animated backdrop for premium themes: a soft gradient with slowly
/// drifting particles (hearts, petals, sparkles, bubbles, rays or stars).
class PremiumBackdrop extends StatefulWidget {
  final GameTheme theme;
  final int particleCount;
  const PremiumBackdrop({super.key, required this.theme, this.particleCount = 24});

  @override
  State<PremiumBackdrop> createState() => _PremiumBackdropState();
}

class _PremiumBackdropState extends State<PremiumBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.theme.gradient;
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: g == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: g,
                ),
          color: g == null ? widget.theme.bg : null,
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, _) => CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              t: _ctrl.value,
              type: widget.theme.particle ?? 'sparkle',
              color: widget.theme.accent,
              count: widget.particleCount,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final String type;
  final Color color;
  final int count;
  _ParticlePainter({required this.t, required this.type, required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final rng = math.Random(i * 7919 + 3);
      final speed = 0.35 + rng.nextDouble() * 0.9;
      final phase = rng.nextDouble();
      final drift = (t * speed + phase) % 1.0;
      // Rise for airy/energetic particles, sink for petals/snow-like ones.
      final rising = type == 'bubble' || type == 'sparkle' || type == 'ray' ||
          type == 'ember' || type == 'neon';
      final y = rising ? size.height * (1.1 - drift * 1.2) : size.height * (drift * 1.2 - 0.1);
      final sway = math.sin((t * 2 * math.pi * speed) + phase * 6.28) * size.width * 0.03;
      final x = size.width * rng.nextDouble() + sway;
      // Depth: nearer particles (bigger) are brighter and drift a touch more —
      // a cheap parallax that reads as 3D.
      final depth = rng.nextDouble();
      final scale = 0.5 + depth * 1.1;
      final twinkles = type == 'star' || type == 'sparkle' || type == 'gem' ||
          type == 'neon' || type == 'prism';
      final twinkle = twinkles
          ? 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + i))
          : 1.0;
      final edgeFade = (1 - (2 * (y / size.height) - 1).abs()).clamp(0.0, 1.0);
      // Glowing 3D themes read better a little brighter than the soft pastels.
      final base = (type == 'ember' || type == 'neon' || type == 'holo') ? 0.42 : 0.30;
      final alpha = (base * twinkle * (0.4 + 0.6 * edgeFade) * (0.6 + 0.4 * depth))
          .clamp(0.0, 1.0);
      _drawParticle(canvas, Offset(x, y), 7.0 * scale, alpha, rng.nextDouble() * 6.28 + t * 2);
    }
  }

  void _drawParticle(Canvas canvas, Offset c, double r, double alpha, double rot) {
    final paint = Paint()..color = color.withValues(alpha: alpha);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    switch (type) {
      case 'heart':
        canvas.rotate(math.sin(rot) * 0.3);
        final p = Path()
          ..moveTo(0, r * 0.9)
          ..cubicTo(-r * 1.4, -r * 0.1, -r * 0.7, -r * 1.1, 0, -r * 0.35)
          ..cubicTo(r * 0.7, -r * 1.1, r * 1.4, -r * 0.1, 0, r * 0.9);
        canvas.drawPath(p, paint);
        break;
      case 'petal':
        canvas.rotate(rot);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 2.0, height: r * 0.9), paint);
        break;
      case 'sparkle':
        canvas.rotate(rot * 0.5);
        final p = Path();
        for (int k = 0; k < 4; k++) {
          final a = k * math.pi / 2;
          p.moveTo(0, 0);
          p.lineTo(math.cos(a) * r * 1.3, math.sin(a) * r * 1.3);
          p.lineTo(math.cos(a + 0.5) * r * 0.35, math.sin(a + 0.5) * r * 0.35);
          p.close();
        }
        canvas.drawPath(p, paint);
        break;
      case 'bubble':
        canvas.drawCircle(Offset.zero, r,
            Paint()..color = color.withValues(alpha: alpha * 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.6);
        canvas.drawCircle(Offset(-r * 0.35, -r * 0.35), r * 0.22, paint);
        break;
      case 'ray':
        canvas.drawCircle(Offset.zero, r * 1.3,
            Paint()..color = color.withValues(alpha: alpha * 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(Offset.zero, r * 0.5, paint);
        break;
      case 'prism': // rotating glass shard with a facet edge
        canvas.rotate(rot * 0.6);
        final p = Path()
          ..moveTo(0, -r * 1.3)
          ..lineTo(r * 1.1, r * 0.8)
          ..lineTo(-r * 1.1, r * 0.8)
          ..close();
        canvas.drawPath(
            p,
            Paint()
              ..color = color.withValues(alpha: alpha * 0.65)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..strokeJoin = StrokeJoin.round);
        canvas.drawLine(Offset(0, -r * 1.3), Offset(0, r * 0.8),
            Paint()..color = color.withValues(alpha: alpha * 0.4)..strokeWidth = 1.0);
        break;
      case 'ember': // rising glowing spark with a white-hot core
        canvas.drawCircle(
            Offset.zero,
            r * 1.5,
            Paint()
              ..color = color.withValues(alpha: alpha * 0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(Offset.zero, r * 0.55,
            Paint()..color = (Color.lerp(color, Colors.white, 0.55) ?? color).withValues(alpha: alpha));
        break;
      case 'gem': // rotating cut diamond with a shine line
        canvas.rotate(rot * 0.5);
        final p = Path()
          ..moveTo(0, -r * 1.2)
          ..lineTo(r * 0.9, 0)
          ..lineTo(0, r * 1.2)
          ..lineTo(-r * 0.9, 0)
          ..close();
        canvas.drawPath(p, paint);
        canvas.drawLine(Offset(-r * 0.45, -r * 0.3), Offset(r * 0.45, -r * 0.3),
            Paint()..color = Colors.white.withValues(alpha: alpha * 0.7)..strokeWidth = 1.2);
        break;
      case 'neon': // glowing 4-point cross
        final glow = Paint()
          ..color = color.withValues(alpha: alpha * 0.4)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        final core = Paint()
          ..color = color.withValues(alpha: alpha)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2;
        canvas.rotate(rot * 0.3);
        for (final pt in [
          Offset(r * 1.3, 0), Offset(-r * 1.3, 0),
          Offset(0, r * 1.3), Offset(0, -r * 1.3),
        ]) {
          canvas.drawLine(Offset.zero, pt, glow);
          canvas.drawLine(Offset.zero, pt, core);
        }
        break;
      case 'holo': // expanding concentric scan rings
        for (int k = 1; k <= 3; k++) {
          canvas.drawCircle(
              Offset.zero,
              r * 0.5 * k,
              Paint()
                ..color = color.withValues(alpha: (alpha * (1.0 - k * 0.22)).clamp(0.0, 1.0))
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.3);
        }
        break;
      default: // 'star'
        canvas.rotate(rot * 0.4);
        final p = Path();
        for (int k = 0; k < 5; k++) {
          final a = -math.pi / 2 + k * 4 * math.pi / 5;
          final pt = Offset(math.cos(a) * r, math.sin(a) * r);
          k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        p.close();
        canvas.drawPath(p, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

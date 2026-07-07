import 'package:flutter/material.dart';
import 'game_state.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Dot grid background
class GridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final Color dotColor;
  final bool isHardStage;
  final Set<String> occupiedCells;
  final Set<String> revealedCells;

  GridPainter({
    required this.gridSize, 
    required this.cellSize, 
    required this.dotColor, 
    this.isHardStage = false,
    this.occupiedCells = const {},
    this.revealedCells = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHardStage) {
      final linePaint = Paint()
        ..color = dotColor.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;
      
      for (int i = 0; i <= gridSize; i++) {
        canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, gridSize * cellSize), linePaint);
        canvas.drawLine(Offset(0, i * cellSize), Offset(gridSize * cellSize, i * cellSize), linePaint);
      }
    }

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        // ONLY draw dots if the cell is in revealedCells
        if (occupiedCells.contains('$c,$r')) {
           // If we want dots ONLY after arrow is GONE, we check revealedCells.
           // Only show dots after the arrow is gone
        }
        
        if (revealedCells.contains('$c,$r')) {
          canvas.drawCircle(Offset(c * cellSize, r * cellSize), isHardStage ? 1.0 : 2.0, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => 
    old.dotColor != dotColor || 
    old.isHardStage != isHardStage || 
    old.occupiedCells.length != occupiedCells.length;
}

/// Premium Arrow Widget with 'Game Feel' animations
class ArrowWidget extends StatefulWidget {
  final ArrowModel arrow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double cellSize;
  final int offsetX; 
  final int offsetY;
  final Color arrowColor;
  final double? padding;
  final bool isBigArrow;
  final bool isNeon;
  final int trailEffect;
  final int gridSize;

  const ArrowWidget({
    super.key,
    required this.arrow,
    this.onTap,
    this.onLongPress,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.arrowColor,
    this.padding,
    this.isBigArrow = false,
    this.isNeon = false,
    this.trailEffect = 0,
    this.gridSize = 12,
  });

  @override
  State<ArrowWidget> createState() => _ArrowWidgetState();
}

class _ArrowWidgetState extends State<ArrowWidget> with TickerProviderStateMixin {
  late AnimationController _bumpController;
  late AnimationController _flyController;
  late Animation<double> _bumpAnim;
  late Animation<double> _flyAnim;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _bumpAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 50),
    ]).animate(_bumpController);

    _flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _flyAnim = CurvedAnimation(parent: _flyController, curve: Curves.easeInCubic);

    if (widget.arrow.isSolved) {
      _flyController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ArrowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.arrow.hasError && !oldWidget.arrow.hasError) {
      _bumpController.forward(from: 0);
    }
    if (widget.arrow.isSolved && !oldWidget.arrow.isSolved) {
      _flyController.forward(from: 0);
    } else if (!widget.arrow.isSolved && oldWidget.arrow.isSolved) {
      _flyController.reset();
    }
  }

  @override
  void dispose() {
    _bumpController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.onTap == null || widget.arrow.isSolved,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bumpAnim, _flyAnim]),
          builder: (context, child) {
            return CustomPaint(
              painter: ArrowPathPainter(
                arrow: widget.arrow,
                cellSize: widget.cellSize,
                offsetX: widget.offsetX,
                offsetY: widget.offsetY,
                arrowColor: widget.arrowColor,
                flyProgress: _flyAnim.value,
                nudgeProgress: _bumpAnim.value,
                padding: widget.padding,
                isBigArrow: widget.isBigArrow,
                isNeon: widget.isNeon,
                trailEffect: widget.trailEffect,
                gridSize: widget.gridSize,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PathCache {
  final PathMetric metric;
  final double totalArrowLen;
  _PathCache(this.metric, this.totalArrowLen);
}

/// CustomPainter: draws continuous line + arrowhead triangle with slithering animation
class ArrowPathPainter extends CustomPainter {
  static final Map<String, _PathCache> _slitherCache = {};

  final ArrowModel arrow;
  final double cellSize;
  final int offsetX;
  final int offsetY;
  final Color arrowColor;
  final double flyProgress;
  final double nudgeProgress;
  final double? padding;
  final bool isBigArrow;
  final bool isNeon;
  final int trailEffect;
  final int gridSize;

  ArrowPathPainter({
    required this.arrow,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.arrowColor,
    this.flyProgress = 0.0,
    this.nudgeProgress = 0.0,
    this.padding,
    this.isBigArrow = false,
    this.isNeon = false,
    this.trailEffect = 0,
    this.gridSize = 12,
  });

  double get _coreWidth => isBigArrow
      ? (cellSize * 0.3).clamp(4.0, 12.0)
      : (cellSize * 0.15).clamp(2.0, 4.0);

  Offset _toLocal(List<int> point) {
    double pad = padding ?? (cellSize / 2);
    return Offset(
      (point[0] - offsetX) * cellSize + pad,
      (point[1] - offsetY) * cellSize + pad,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color col = (arrow.hasError || arrow.isPermanentError) ? const Color(0xFFE53935) : arrowColor;
    
    final double coreWidth = isBigArrow 
        ? (cellSize * 0.3).clamp(4.0, 12.0) 
        : (cellSize * 0.15).clamp(2.0, 4.0);

    final glowPaint = Paint()
      ..color = col.withValues(alpha: 0.8)
      ..strokeWidth = coreWidth * 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreWidth * 1.5);

    final Color coreColor = isNeon ? (Color.lerp(col, Colors.white, 0.5) ?? col) : col;

    final linePaint = Paint()
      ..color = coreColor
      ..strokeWidth = coreWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillGlowPaint = Paint()
      ..color = col.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreWidth * 1.5);

    final fillPaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;

    if (arrow.path.isEmpty) return;

    // Apply Blocked Bump (Nudge)
    if (nudgeProgress > 0) {
      final dir = arrow.flyDirection;
      double nudgeDist = nudgeProgress * 8.0; // 8 pixels forward
      canvas.translate(dir[0] * nudgeDist, dir[1] * nudgeDist);
    }

    // Build the base path
    final basePath = Path();
    final firstPt = _toLocal(arrow.path.first);
    basePath.moveTo(firstPt.dx, firstPt.dy);
    for (int i = 1; i < arrow.path.length; i++) {
      final pt = _toLocal(arrow.path[i]);
      basePath.lineTo(pt.dx, pt.dy);
    }

    if (flyProgress == 0.0) {
      // Static draw
      if (isNeon) {
        canvas.drawPath(basePath, glowPaint);
      }
      canvas.drawPath(basePath, linePaint);
      if (isNeon) {
        _drawArrowheadAtPoint(canvas, _toLocal(arrow.arrowheadPoint), arrow.flyDirection, fillGlowPaint);
      }
      _drawArrowheadAtPoint(canvas, _toLocal(arrow.arrowheadPoint), arrow.flyDirection, fillPaint);
    } else {
      // SLITHER ANIMATION
      // Extend the path in fly direction
      String cacheKey = '${arrow.id}_${arrow.path.last}_$cellSize';
      _PathCache? cache = _slitherCache[cacheKey];

      if (cache == null) {
        final headPt = _toLocal(arrow.arrowheadPoint);
        final dir = arrow.flyDirection;
        final extendedPath = Path();
        extendedPath.addPath(basePath, Offset.zero);
        
        final endPt = headPt + Offset(dir[0] * cellSize * 50, dir[1] * cellSize * 50);
        extendedPath.lineTo(endPt.dx, endPt.dy);

        final metrics = extendedPath.computeMetrics().first;
        double totalArrowLen = 0;
        for(int i=0; i<arrow.path.length-1; i++) {
          final p1 = arrow.path[i];
          final p2 = arrow.path[i+1];
          totalArrowLen += math.sqrt(math.pow(p2[0]-p1[0], 2) + math.pow(p2[1]-p1[1], 2)) * cellSize;
        }

        cache = _PathCache(metrics, totalArrowLen);
        if (_slitherCache.length > 200) _slitherCache.clear();
        _slitherCache[cacheKey] = cache;
      }

      double currentTravel = flyProgress * (cache.metric.length);
      double start = currentTravel;
      double end = currentTravel + cache.totalArrowLen;

      final subPath = cache.metric.extractPath(start, end);
      // Tail travels 0 -> metric.length while the head stays totalArrowLen ahead.

      // Trail effects drawn beneath the arrow body.
      if (flyProgress > 0 && flyProgress < 1.0) {
        _drawTrailUnder(canvas, cache, col);
      }

      // Portal effect clips the arrow so it visually vanishes into the ring.
      bool clipped = false;
      if (trailEffect == 3 && flyProgress > 0 && flyProgress < 1.0) {
        final portal = _portalGeometry(cache);
        canvas.save();
        canvas.clipRect(portal.clipRect);
        clipped = true;
      }

      if (isNeon) {
        canvas.drawPath(subPath, glowPaint);
      }
      canvas.drawPath(subPath, linePaint);

      // Draw arrowhead at the front of the slithering path
      if (end < cache.metric.length) {
        final tangent = cache.metric.getTangentForOffset(end);
        if (tangent != null) {
          if (isNeon) {
            _drawArrowheadAtTangent(canvas, tangent, fillGlowPaint);
          }
          _drawArrowheadAtTangent(canvas, tangent, fillPaint);
        }
      }

      if (clipped) canvas.restore();

      // Trail effects drawn above the arrow body.
      if (flyProgress > 0 && flyProgress < 1.0) {
        _drawTrailOver(canvas, cache, col);
      }
    }
  }

  // ---------- Fly-trail effects (deterministic, derived from flyProgress) ----------

  void _drawTrailUnder(Canvas canvas, _PathCache cache, Color col) {
    switch (trailEffect) {
      case 0:
        _trailEcho(canvas, cache, col);
        break;
      case 2:
        _trailWarp(canvas, cache, col);
        break;
      case 4:
        _trailRipple(canvas, cache, col);
        break;
    }
  }

  void _drawTrailOver(Canvas canvas, _PathCache cache, Color col) {
    switch (trailEffect) {
      case 1:
        _trailDust(canvas, cache, col);
        break;
      case 3:
        _trailPortal(canvas, cache, col);
        break;
      case 5:
        _trailBolt(canvas, cache, col);
        break;
    }
  }

  Tangent? _tangentAt(_PathCache cache, double offset) {
    final l = cache.metric.length;
    if (l <= 1) return null;
    return cache.metric.getTangentForOffset(offset.clamp(0.0, l - 0.5));
  }

  /// Echo: fading ghost copies of the whole arrow trailing behind.
  void _trailEcho(Canvas canvas, _PathCache cache, Color col) {
    final ghost = Color.lerp(col, Colors.white, 0.20) ?? col;
    for (int k = 4; k >= 1; k--) {
      final gp = flyProgress - k * 0.055;
      if (gp <= 0) continue;
      final s = gp * cache.metric.length;
      final sub = cache.metric.extractPath(s, s + cache.totalArrowLen);
      final paint = Paint()
        ..color = ghost.withValues(alpha: (0.34 - k * 0.07).clamp(0.0, 1.0))
        ..strokeWidth = _coreWidth * (1.0 - k * 0.13)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(sub, paint);
    }
  }

  /// Dust: the arrow disintegrates into tinted squares along its wake.
  void _trailDust(Canvas canvas, _PathCache cache, Color col) {
    final rng = math.Random(arrow.id * 97 + 11);
    final l = cache.metric.length;
    for (int i = 0; i < 24; i++) {
      final b = rng.nextDouble() * 0.75;
      final j1 = rng.nextDouble();
      final j2 = rng.nextDouble();
      final j3 = rng.nextDouble();
      final a = (flyProgress - b) / 0.30;
      if (a <= 0 || a >= 1) continue;
      final tan = _tangentAt(cache, b * l);
      if (tan == null) continue;
      final dirv = tan.vector;
      final perp = Offset(-dirv.dy, dirv.dx);
      final pos = tan.position +
          perp * ((j1 - 0.5) * cellSize * 0.7) -
          dirv * (a * cellSize * 0.9);
      final side = (cellSize * 0.17 * (1 - a * 0.6) * (0.6 + j2 * 0.8))
          .clamp(1.0, cellSize);
      final color = Color.lerp(col, j3 < 0.5 ? Colors.white : Colors.black, j3 * 0.3) ?? col;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(j2 * 6.28 + a * 3.0);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Paint()..color = color.withValues(alpha: (1 - a) * 0.9),
      );
      canvas.restore();
    }
  }

  /// Warp: tight motion ghosts plus anime-style speed lines.
  void _trailWarp(Canvas canvas, _PathCache cache, Color col) {
    final ghost = Color.lerp(col, Colors.white, 0.25) ?? col;
    for (int k = 2; k >= 1; k--) {
      final gp = flyProgress - k * 0.028;
      if (gp <= 0) continue;
      final s = gp * cache.metric.length;
      final sub = cache.metric.extractPath(s, s + cache.totalArrowLen);
      final paint = Paint()
        ..color = ghost.withValues(alpha: k == 1 ? 0.35 : 0.18)
        ..strokeWidth = _coreWidth * (1.0 - k * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(sub, paint);
    }
    final rng = math.Random(arrow.id * 97 + 22);
    final l = cache.metric.length;
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (_coreWidth * 0.45).clamp(1.0, 6.0);
    for (int i = 0; i < 14; i++) {
      final b = rng.nextDouble() * 0.8;
      final j1 = rng.nextDouble();
      final j2 = rng.nextDouble();
      final a = (flyProgress - b) / 0.20;
      if (a <= 0 || a >= 1) continue;
      final tan = _tangentAt(cache, b * l);
      if (tan == null) continue;
      final dirv = tan.vector;
      final perp = Offset(-dirv.dy, dirv.dx);
      final p1 = tan.position + perp * ((j1 - 0.5) * cellSize * 1.3);
      final p2 = p1 - dirv * (cellSize * (0.6 + j2 * 0.9));
      linePaint.color =
          (Color.lerp(col, Colors.white, 0.3) ?? col).withValues(alpha: (1 - a) * 0.5);
      canvas.drawLine(p1, p2, linePaint);
    }
  }

  ({Offset center, double tailOffsetAtPortal, Rect clipRect}) _portalGeometry(
      _PathCache cache) {
    final head = _toLocal(arrow.arrowheadPoint);
    final dir = arrow.flyDirection;
    final pad0 = padding ?? (cellSize / 2);
    const big = 100000.0;
    Offset center;
    Rect clip;
    if (dir[0] == 1) {
      final x = (gridSize - offsetX) * cellSize + pad0;
      center = Offset(x, head.dy);
      clip = Rect.fromLTRB(-big, -big, x, big);
    } else if (dir[0] == -1) {
      final x = (-1 - offsetX) * cellSize + pad0;
      center = Offset(x, head.dy);
      clip = Rect.fromLTRB(x, -big, big, big);
    } else if (dir[1] == 1) {
      final y = (gridSize - offsetY) * cellSize + pad0;
      center = Offset(head.dx, y);
      clip = Rect.fromLTRB(-big, -big, big, y);
    } else {
      final y = (-1 - offsetY) * cellSize + pad0;
      center = Offset(head.dx, y);
      clip = Rect.fromLTRB(-big, y, big, big);
    }
    final tailOffsetAtPortal = cache.totalArrowLen + (center - head).distance;
    return (center: center, tailOffsetAtPortal: tailOffsetAtPortal, clipRect: clip);
  }

  /// Portal: a spinning ring at the board edge swallows the arrow.
  void _trailPortal(Canvas canvas, _PathCache cache, Color col) {
    final portal = _portalGeometry(cache);
    final grow = (flyProgress / 0.10).clamp(0.0, 1.0);
    final close = ((flyProgress * cache.metric.length - portal.tailOffsetAtPortal) /
            (cellSize * 2))
        .clamp(0.0, 1.0);
    final radius = cellSize * 1.05 * grow * (1 - close);
    if (radius < 1.5) return;
    final c = portal.center;
    final halo = Paint()
      ..color = (Color.lerp(col, Colors.white, 0.4) ?? col).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _coreWidth * 1.6;
    canvas.drawCircle(c, radius + _coreWidth, halo);
    final fill = Paint()..color = col.withValues(alpha: 0.12);
    canvas.drawCircle(c, radius, fill);
    final arcPaint = Paint()
      ..color = col.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (_coreWidth * 0.7).clamp(2.0, 8.0);
    final spin = flyProgress * 14.0;
    final rect = Rect.fromCircle(center: c, radius: radius);
    for (int k = 0; k < 3; k++) {
      canvas.drawArc(rect, spin + k * 2.094, 1.5, false, arcPaint);
    }
    final dot = Paint()..color = col.withValues(alpha: 0.55 * (1 - close));
    for (int i = 0; i < 6; i++) {
      final ang = i * 1.047 + flyProgress * 16.0;
      canvas.drawCircle(
        c + Offset(math.cos(ang), math.sin(ang)) * (radius * 1.25),
        (_coreWidth * 0.35).clamp(1.2, 4.0),
        dot,
      );
    }
  }

  /// Ripple: grid dots along the wake swell up in the arrow's color and fade.
  void _trailRipple(Canvas canvas, _PathCache cache, Color col) {
    final l = cache.metric.length;
    final pad0 = padding ?? (cellSize / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final b = i / 12 * 0.8;
      final a = (flyProgress - b) / 0.35;
      if (a <= 0 || a >= 1) continue;
      final tan = _tangentAt(cache, b * l);
      if (tan == null) continue;
      final center = tan.position;
      final fx = ((center.dx - pad0) / cellSize).floor();
      final fy = ((center.dy - pad0) / cellSize).floor();
      for (int dx = 0; dx <= 1; dx++) {
        for (int dy = 0; dy <= 1; dy++) {
          final dot = Offset(
            (fx + dx) * cellSize + pad0,
            (fy + dy) * cellSize + pad0,
          );
          final w = ((1 - (dot - center).distance / (cellSize * 1.5)).clamp(0.0, 1.0)) *
              (1 - a);
          if (w < 0.03) continue;
          paint.color = col.withValues(alpha: (w * 0.85).clamp(0.0, 1.0));
          canvas.drawCircle(dot, 1.6 + w * cellSize * 0.14, paint);
        }
      }
    }
  }

  /// Bolt: a flickering lightning streak from the launch point to the tail.
  void _trailBolt(Canvas canvas, _PathCache cache, Color col) {
    final l = cache.metric.length;
    final t0 = _tangentAt(cache, 0);
    final t1 = _tangentAt(cache, flyProgress * l);
    if (t0 == null || t1 == null) return;
    final start = t0.position;
    final tail = t1.position;
    final span = tail - start;
    final dist = span.distance;
    if (dist < cellSize * 0.8) return;
    final unit = span / dist;
    final perp = Offset(-unit.dy, unit.dx);
    final n = (dist / (cellSize * 0.7)).ceil().clamp(2, 40);
    final flick = math.Random(arrow.id * 131 + (flyProgress * 18).floor());
    final pts = <Offset>[start];
    for (int i = 1; i < n; i++) {
      final t = i / n;
      pts.add(start + span * t + perp * ((flick.nextDouble() - 0.5) * cellSize * 0.55));
    }
    pts.add(tail);
    final bolt = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      bolt.lineTo(pts[i].dx, pts[i].dy);
    }
    final glowAlpha = 0.30 + 0.20 * math.sin(flyProgress * 40).abs();
    canvas.drawPath(
      bolt,
      Paint()
        ..color = col.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (_coreWidth * 0.9).clamp(2.0, 9.0),
    );
    canvas.drawPath(
      bolt,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (_coreWidth * 0.35).clamp(1.0, 4.0),
    );
  }

  void _drawArrowheadAtPoint(Canvas canvas, Offset pos, List<int> dir, Paint paint) {
    double sz = isBigArrow 
        ? (cellSize * 0.8).clamp(18.0, 35.0) 
        : (cellSize * 0.55).clamp(10.0, 22.0);
    final angle = math.atan2(dir[1].toDouble(), dir[0].toDouble());
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    _drawTriangle(canvas, sz, paint);
    canvas.restore();
  }

  void _drawArrowheadAtTangent(Canvas canvas, Tangent tangent, Paint paint) {
    double sz = isBigArrow 
        ? (cellSize * 0.8).clamp(18.0, 35.0) 
        : (cellSize * 0.55).clamp(10.0, 22.0);
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle); 
    // Actually, PathTangent.angle is the angle of the tangent vector.
    // Let's test standard angle.
    _drawTriangle(canvas, sz, paint);
    canvas.restore();
  }

  void _drawTriangle(Canvas canvas, double sz, Paint paint) {
    Path tri = Path();
    tri.moveTo(sz * 0.7, 0);
    tri.lineTo(-sz * 0.3, -sz * 0.5);
    tri.lineTo(-sz * 0.3, sz * 0.5);
    tri.close();
    canvas.drawPath(tri, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowPathPainter old) {
    return old.arrow.hasError != arrow.hasError ||
           old.arrow.isSolved != arrow.isSolved ||
           old.arrowColor != arrowColor ||
           old.flyProgress != flyProgress ||
           old.nudgeProgress != nudgeProgress ||
           old.trailEffect != trailEffect;
  }
}


class GuidelinePainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final Color color;

  GuidelinePainter({required this.gridSize, required this.cellSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, gridSize * cellSize), paint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(gridSize * cellSize, i * cellSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GuidelinePainter old) => old.color != color;
}

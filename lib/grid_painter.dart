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

    _flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
  });

  Offset _toLocal(List<int> point) {
    double pad = padding ?? (cellSize / 2);
    return Offset(
      (point[0] - offsetX) * cellSize + pad,
      (point[1] - offsetY) * cellSize + pad,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color col = arrow.hasError ? const Color(0xFFE53935) : arrowColor;
    
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
      // Actually, we want the "tail" to move from 0 and "head" to move from totalArrowLen.
      // So at flyProgress 0: tail is at 0, head is at totalArrowLen.
      // At flyProgress 1: tail is at metrics.length, head is at metrics.length + totalArrowLen.
      
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
    }
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
           old.nudgeProgress != nudgeProgress;
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

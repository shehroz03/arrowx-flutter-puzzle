import 'package:flutter/material.dart';
import 'game_state.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// Dot grid background
class GridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final Color dotColor;

  GridPainter({required this.gridSize, required this.cellSize, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.dotColor != dotColor;
}

/// Arrow segment widget
class ArrowSegmentWidget extends StatelessWidget {
  final ArrowModel arrow;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double cellSize;
  final int offsetX; 
  final int offsetY;
  final Color arrowColor;
  final double flyProgress;

  const ArrowSegmentWidget({
    super.key,
    required this.arrow,
    required this.onTap,
    this.onLongPress,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.arrowColor,
    this.flyProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: ArrowPathPainter(
          arrow: arrow,
          cellSize: cellSize,
          offsetX: offsetX,
          offsetY: offsetY,
          arrowColor: arrowColor,
          flyProgress: flyProgress,
        ),
      ),
    );
  }
}

/// CustomPainter: draws continuous line + arrowhead triangle with slithering animation
class ArrowPathPainter extends CustomPainter {
  final ArrowModel arrow;
  final double cellSize;
  final int offsetX;
  final int offsetY;
  final Color arrowColor;
  final double flyProgress;

  ArrowPathPainter({
    required this.arrow,
    required this.cellSize,
    required this.offsetX,
    required this.offsetY,
    required this.arrowColor,
    this.flyProgress = 0.0,
  });

  Offset _toLocal(List<int> point) {
    double pad = cellSize / 2;
    return Offset(
      (point[0] - offsetX) * cellSize + pad,
      (point[1] - offsetY) * cellSize + pad,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color col = arrow.hasError ? const Color(0xFFE53935) : arrowColor;

    final linePaint = Paint()
      ..color = col
      ..strokeWidth = 3.0 // Slightly thicker for better visibility
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = col
      ..style = PaintingStyle.fill;

    if (arrow.path.isEmpty) return;

    // Build the base path
    final p = Path();
    final firstPt = _toLocal(arrow.path.first);
    p.moveTo(firstPt.dx, firstPt.dy);
    for (int i = 1; i < arrow.path.length; i++) {
        final pt = _toLocal(arrow.path[i]);
        p.lineTo(pt.dx, pt.dy);
    }

    // FALLBACK: If not flying, draw simple static path
    if (flyProgress <= 0.0) {
      canvas.drawPath(p, linePaint);
      _drawStaticArrowhead(canvas, fillPaint);
      return;
    }

    // 1. Build the full track (Original Path + Huge Exit Ray)
    final headPt = _toLocal(arrow.arrowheadPoint);
    final dir = arrow.flyDirection;
    final double extension = cellSize * 200; // Far off screen
    p.lineTo(headPt.dx + (dir[0] * extension), headPt.dy + (dir[1] * extension));

    ui.PathMetrics pathMetrics = p.computeMetrics();
    if (pathMetrics.isEmpty) return;
    ui.PathMetric metric = pathMetrics.first;

    // Calculate length logic
    double arrowPixelLength = metric.length - extension; // The part on the grid
    if (arrowPixelLength <= 0) arrowPixelLength = (arrow.path.length - 1) * cellSize;

    // The distance it has traveled along the track
    double travelDist = flyProgress * (cellSize * 60); 
    double start = travelDist;
    double end = math.min(travelDist + arrowPixelLength, metric.length);

    if (start < metric.length) {
      Path segment = metric.extractPath(start, end);
      canvas.drawPath(segment, linePaint);

      ui.Tangent? tangent = metric.getTangentForOffset(end);
      if (tangent != null) {
        _drawArrowheadAtTangent(canvas, fillPaint, tangent);
      }
    }
  }

  void _drawStaticArrowhead(Canvas canvas, Paint paint) {
    final head = _toLocal(arrow.arrowheadPoint);
    final dir = arrow.flyDirection;
    double sz = cellSize * 0.4;
    
    final angle = math.atan2(dir[1].toDouble(), dir[0].toDouble());
    
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(angle);
    Path tri = Path();
    tri.moveTo(sz * 0.6, 0);
    tri.lineTo(-sz * 0.2, -sz * 0.5);
    tri.lineTo(-sz * 0.2, sz * 0.5);
    tri.close();
    canvas.drawPath(tri, paint);
    canvas.restore();
  }

  void _drawArrowheadAtTangent(Canvas canvas, Paint paint, ui.Tangent tangent) {
    final pos = tangent.position;
    final vec = tangent.vector;
    final angle = math.atan2(vec.dy, vec.dx);
    double sz = cellSize * 0.4;
    
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    Path tri = Path();
    tri.moveTo(sz * 0.6, 0);
    tri.lineTo(-sz * 0.2, -sz * 0.5);
    tri.lineTo(-sz * 0.2, sz * 0.5);
    tri.close();
    canvas.drawPath(tri, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowPathPainter old) {
    return old.arrow.hasError != arrow.hasError || 
           old.arrow.isSolved != arrow.isSolved || 
           old.arrowColor != arrowColor ||
           old.flyProgress != flyProgress;
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

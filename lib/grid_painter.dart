import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final double cellSize;
  final List<Offset> currentPath;

  GridPainter({
    required this.rows, 
    required this.columns, 
    required this.cellSize,
    required this.currentPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Dotted Background
    final dotPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= rows; r++) {
      for (int c = 0; c <= columns; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 1.5, dotPaint);
      }
    }

    // 2. Draw The Path Line
    if (currentPath.isNotEmpty) {
      final linePaint = Paint()
        ..color = const Color(0xFFB52B22) // Game theme red color
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      
      // Line ko cell ke center se start karo (cellSize / 2)
      path.moveTo(
        (currentPath[0].dx * cellSize) + (cellSize / 2),
        (currentPath[0].dy * cellSize) + (cellSize / 2),
      );

      for (int i = 1; i < currentPath.length; i++) {
        path.lineTo(
          (currentPath[i].dx * cellSize) + (cellSize / 2),
          (currentPath[i].dy * cellSize) + (cellSize / 2),
        );
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Sirf tab repaint karo jab path update ho taake performance lag na aaye
    return oldDelegate.currentPath != currentPath;
  }
}

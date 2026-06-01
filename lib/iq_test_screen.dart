// ─────────────────────────────────────────────────────────────
// IQ TEST — Flutter / Dart
// Drop this file in your lib/ folder.
// Add to pubspec.yaml:
//   dependencies:
//     shared_preferences: ^2.2.2
// Then call: Navigator.push(context, MaterialPageRoute(builder: (_) => const IQTestScreen()));
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════════
//  CONSTANTS
// ══════════════════════════════════════════════════════════════
const _kPrimary   = Color(0xFF7C5CFC);
const _kPrimary2  = Color(0xFFA78BFA);
const _kDark      = Color(0xFF2A2A5A);
const _kBg        = Color(0xFFEEF0FE);
const _kCellBg    = Color(0xFFF7F6FF);
const _kCellBd    = Color(0xFFE8E4FF);

const _diffColors = {
  'easy':   [Color(0xFFdcfce7), Color(0xFF16a34a)],
  'medium': [Color(0xFFfef9c3), Color(0xFFd97706)],
  'hard':   [Color(0xFFfee2e2), Color(0xFFdc2626)],
  'expert': [Color(0xFFede9fe), Color(0xFF7c3aed)],
};

// ══════════════════════════════════════════════════════════════
//  SHAPE MODEL & PAINTER
// ══════════════════════════════════════════════════════════════
enum SType { circle, square, triangle, diamond, pent, hex, hept }

class ShapeSpec {
  final SType t;
  final double cx, cy, size;
  final bool filled;
  final double rot; // degrees

  const ShapeSpec(this.t, {
    this.cx = 0.5, this.cy = 0.5, this.size = 0.28,
    this.filled = true, this.rot = 0,
  });
}

class ShapePainter extends CustomPainter {
  final List<ShapeSpec> shapes;
  ShapePainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      final px = s.cx * size.width;
      final py = s.cy * size.height;
      final r  = s.size * min(size.width, size.height);
      final paint = Paint()
        ..color = _kDark
        ..style = s.filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2;

      switch (s.t) {
        case SType.circle:
          canvas.drawCircle(Offset(px, py), r, paint);
        case SType.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(px, py), width: r * 2, height: r * 2),
              const Radius.circular(2),
            ),
            paint,
          );
        case SType.triangle:
        case SType.diamond:
        case SType.pent:
        case SType.hex:
        case SType.hept:
          final int n = {
            SType.triangle: 3, SType.diamond: 4,
            SType.pent: 5, SType.hex: 6, SType.hept: 7,
          }[s.t]!;
          final double startAngle = (s.rot - 90) * pi / 180;
          final path = Path();
          for (int i = 0; i < n; i++) {
            final a = startAngle + i * 2 * pi / n;
            final x = px + r * cos(a);
            final y = py + r * sin(a);
            i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          path.close();
          canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ShapePainter old) => false;
}

// ShapeCell widget
Widget _shapeCell(List<ShapeSpec> shapes, {double w = 88, double h = 72}) {
  return Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: _kCellBg, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kCellBd, width: 1.5),
    ),
    child: CustomPaint(painter: ShapePainter(shapes)),
  );
}

Widget _qBox({double w = 88, double h = 72}) {
  return Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: _kPrimary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kPrimary, width: 2.5,
          style: BorderStyle.solid),
    ),
    child: const Center(
      child: Text('?', style: TextStyle(fontSize: 26, color: _kPrimary,
          fontWeight: FontWeight.w900)),
    ),
  );
}

// Clock painter
class ClockPainter extends CustomPainter {
  final int hour, minute;
  ClockPainter(this.hour, this.minute);

  @override
  void paint(Canvas canvas, Size size) {
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = size.width / 2 - 5;
    final p  = Paint()..color = _kDark..style = PaintingStyle.stroke..strokeWidth = 2;
    final pF = Paint()..color = _kDark..style = PaintingStyle.fill;

    canvas.drawCircle(c, r, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(c, r, p);

    for (int i = 0; i < 12; i++) {
      final a = (i * 30 - 90) * pi / 180;
      final big = i % 3 == 0;
      canvas.drawLine(
        Offset(c.dx + (r - (big ? 8 : 5)) * cos(a), c.dy + (r - (big ? 8 : 5)) * sin(a)),
        Offset(c.dx + r * cos(a), c.dy + r * sin(a)),
        Paint()..color = _kDark..strokeWidth = big ? 2 : 1,
      );
    }

    final ha = ((hour % 12 + minute / 60) * 30 - 90) * pi / 180;
    final ma = (minute * 6 - 90) * pi / 180;
    canvas.drawLine(c, Offset(c.dx + r * .55 * cos(ha), c.dy + r * .55 * sin(ha)),
        Paint()..color = _kDark..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawLine(c, Offset(c.dx + r * .78 * cos(ma), c.dy + r * .78 * sin(ma)),
        Paint()..color = _kDark..strokeWidth = 2..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 3, pF);
  }

  @override
  bool shouldRepaint(ClockPainter old) => false;
}

Widget _clock(int h, int m, {double size = 70}) {
  return Container(
    width: size, height: size,
    decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCellBd, width: 1.5)),
    child: CustomPaint(painter: ClockPainter(h, m)),
  );
}

// Rain painter
class RainPainter extends CustomPainter {
  final int rows, cols;
  final double ang;
  RainPainter(this.rows, this.cols, this.ang);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _kDark..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    const sp = 12.0, len = 9.0;
    final rad = ang * pi / 180;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = 8.0 + c * sp;
        final y = 8.0 + r * sp;
        canvas.drawLine(Offset(x, y),
            Offset(x + sin(rad) * len, y + cos(rad) * len), p);
      }
    }
  }

  @override
  bool shouldRepaint(RainPainter old) => false;
}

Widget _rain(int rows, int cols, double ang, {double w = 88, double h = 72}) {
  return Container(
    width: w, height: h,
    decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCellBd, width: 1)),
    child: CustomPaint(painter: RainPainter(rows, cols, ang)),
  );
}

// Dot grid
Widget _dots(int cols, int rows, {double w = 88, double h = 72}) {
  final sp = w / (cols + 1);
  return Container(
    width: w, height: h,
    decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCellBd, width: 1)),
    child: CustomPaint(
      painter: _DotPainter(cols, rows, sp),
    ),
  );
}

class _DotPainter extends CustomPainter {
  final int c, r;
  final double sp;
  _DotPainter(this.c, this.r, this.sp);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _kDark;
    final hsp = size.height / (r + 1);
    for (int rr = 0; rr < r; rr++) for (int cc = 0; cc < c; cc++)
      canvas.drawCircle(Offset(sp * (cc + 1), hsp * (rr + 1)), 2, p);
  }
  @override bool shouldRepaint(_DotPainter o) => false;
}

// Custom dot positions
class _CustomDotPainter extends CustomPainter {
  final List<Offset> positions; // relative 0-1
  _CustomDotPainter(this.positions);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _kDark;
    for (final pos in positions)
      canvas.drawCircle(Offset(pos.dx * size.width, pos.dy * size.height), 3.5, p);
  }
  @override bool shouldRepaint(_CustomDotPainter o) => false;
}

Widget _dotPattern(List<Offset> positions, {double w = 110, double h = 110}) {
  return Container(
    width: w, height: h,
    decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCellBd, width: 1.5)),
    child: CustomPaint(painter: _CustomDotPainter(positions)),
  );
}

// Layout helpers
Widget _g3(List<Widget?> cells) {
  return GridView.count(
    crossAxisCount: 3, shrinkWrap: true,
    mainAxisSpacing: 6, crossAxisSpacing: 6,
    childAspectRatio: 88 / 72,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    children: cells.map((c) => c ?? _qBox()).toList(),
  );
}

Widget _row(List<Widget?> cells) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: c ?? _qBox(w: 84, h: 60),
      )).toList(),
    ),
  );
}

Widget _row5(List<Widget?> cells) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Wrap(
      spacing: 5, runSpacing: 5, alignment: WrapAlignment.center,
      children: cells.map((c) => c ?? _qBox(w: 68, h: 54)).toList(),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  QUESTION MODEL
// ══════════════════════════════════════════════════════════════
enum QType { agree, num, visual, ms }

class Question {
  final int id;
  final QType type;
  final String? diff;
  final String? label;
  // agree
  final String? text;
  // num
  final List<String>? nums;
  final List<String>? numOpts;
  // visual
  final Widget Function()? qWidget;
  final List<Widget Function()>? opts;
  // ms
  final int? pct;
  final String? msTitle;
  final String? msSub;
  final int? correct;

  const Question({
    required this.id, required this.type,
    this.diff, this.label, this.text,
    this.nums, this.numOpts,
    this.qWidget, this.opts,
    this.pct, this.msTitle, this.msSub,
    this.correct,
  });
}

// ══════════════════════════════════════════════════════════════
//  QUESTIONS LIST
// ══════════════════════════════════════════════════════════════
List<Question> _buildQuestions() {
  // Helper shorthand
  c(List<ShapeSpec> s, {double w=88, double h=72}) => _shapeCell(s, w: w, h: h);

  return [
    Question(id:1, type: QType.agree, text:"You easily connect with new people"),
    Question(id:2, type: QType.agree, text:"You prefer planning over being spontaneous"),

    // Q3 EASY: Size grows
    Question(id:3, type: QType.visual, diff:'easy', label:"What comes next?",
      qWidget: () => _row([
        c([const ShapeSpec(SType.square, size:.12)]),
        c([const ShapeSpec(SType.square, size:.22)]),
        c([const ShapeSpec(SType.square, size:.32)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.square, size:.42)]),
        () => c([const ShapeSpec(SType.square, size:.32)]),
        () => c([const ShapeSpec(SType.square, size:.37)]),
        () => c([const ShapeSpec(SType.circle, size:.42)]),
        () => c([const ShapeSpec(SType.square, size:.42, filled:false)]),
        () => c([const ShapeSpec(SType.triangle, size:.42)]),
      ], correct:0),

    // Q4 EASY: Polygon sides
    Question(id:4, type: QType.visual, diff:'easy', label:"How many sides next?",
      qWidget: () => _row5([
        c([const ShapeSpec(SType.triangle, size:.28)]),
        c([const ShapeSpec(SType.square,   size:.28)]),
        c([const ShapeSpec(SType.pent,     size:.28)]),
        c([const ShapeSpec(SType.hex,      size:.28)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.hept,     size:.28)]),
        () => c([const ShapeSpec(SType.hex,      size:.28)]),
        () => c([const ShapeSpec(SType.triangle, size:.28)]),
        () => c([const ShapeSpec(SType.diamond,  size:.28)]),
        () => c([const ShapeSpec(SType.pent,     size:.28)]),
        () => c([const ShapeSpec(SType.square,   size:.28)]),
      ], correct:0),

    // Q5 EASY: ×2 number
    Question(id:5, type: QType.num, diff:'easy', label:"What comes next?",
      nums:['3','6','12','24','?'],
      numOpts:['48','36','42','40','32','50'], correct:0),

    Question(id:-1, type: QType.ms, pct:94,
      msTitle:"You are faster than 94% participants!",
      msSub:"Quick thinking helps you adapt faster."),

    // Q6 MEDIUM: Triangle rotation 90° each step
    Question(id:6, type: QType.visual, diff:'medium', label:"Triangle rotation?",
      qWidget: () => _row5([
        c([const ShapeSpec(SType.triangle, rot:270)]),
        c([const ShapeSpec(SType.triangle, rot:0)]),
        c([const ShapeSpec(SType.triangle, rot:90)]),
        c([const ShapeSpec(SType.triangle, rot:180)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle, rot:270)]),
        () => c([const ShapeSpec(SType.triangle, rot:0)]),
        () => c([const ShapeSpec(SType.triangle, rot:90)]),
        () => c([const ShapeSpec(SType.triangle, filled:false, rot:270)]),
        () => c([const ShapeSpec(SType.diamond)]),
        () => c([const ShapeSpec(SType.triangle, rot:180)]),
      ], correct:0),

    // Q7 MEDIUM: Position shifts column
    Question(id:7, type: QType.visual, diff:'medium', label:"Position pattern?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle, cx:.27)]),
        c([const ShapeSpec(SType.circle, cx:.27, filled:false)]),
        c([const ShapeSpec(SType.circle, cx:.27)]),
        c([const ShapeSpec(SType.circle, cx:.5)]),
        c([const ShapeSpec(SType.circle, cx:.5, filled:false)]),
        c([const ShapeSpec(SType.circle, cx:.5)]),
        c([const ShapeSpec(SType.circle, cx:.73)]),
        c([const ShapeSpec(SType.circle, cx:.73, filled:false)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.circle, cx:.73)]),
        () => c([const ShapeSpec(SType.circle, cx:.5)]),
        () => c([const ShapeSpec(SType.circle, cx:.27)]),
        () => c([const ShapeSpec(SType.circle, cx:.73, filled:false)]),
        () => c([const ShapeSpec(SType.square, cx:.73)]),
        () => c([const ShapeSpec(SType.circle, cx:.73), const ShapeSpec(SType.circle, cx:.27)]),
      ], correct:0),

    // Q8 MEDIUM: Fibonacci
    Question(id:8, type: QType.num, diff:'medium', label:"Find missing:",
      nums:['1','1','2','3','5','?'],
      numOpts:['8','6','7','9','10','5'], correct:0),

    Question(id:-2, type: QType.ms, pct:87,
      msTitle:"You are smarter than 87% of test takers!",
      msSub:"Your pattern recognition is in the top tier."),

    // Q9 MEDIUM: Seesaw
    Question(id:9, type: QType.visual, diff:'medium', label:"Seesaw rule?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle, cx:.28, size:.32), const ShapeSpec(SType.square, cx:.72, size:.13)]),
        c([const ShapeSpec(SType.circle, cx:.28, size:.22), const ShapeSpec(SType.square, cx:.72, size:.22)]),
        c([const ShapeSpec(SType.circle, cx:.28, size:.13), const ShapeSpec(SType.square, cx:.72, size:.32)]),
        c([const ShapeSpec(SType.triangle, cx:.28, size:.32), const ShapeSpec(SType.diamond, cx:.72, size:.13)]),
        c([const ShapeSpec(SType.triangle, cx:.28, size:.22), const ShapeSpec(SType.diamond, cx:.72, size:.22)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle, cx:.28, size:.13), const ShapeSpec(SType.diamond, cx:.72, size:.32)]),
        () => c([const ShapeSpec(SType.triangle, cx:.28, size:.32), const ShapeSpec(SType.diamond, cx:.72, size:.13)]),
        () => c([const ShapeSpec(SType.triangle, cx:.28, size:.22), const ShapeSpec(SType.diamond, cx:.72, size:.22)]),
        () => c([const ShapeSpec(SType.circle,   cx:.28, size:.13), const ShapeSpec(SType.square,  cx:.72, size:.32)]),
        () => c([const ShapeSpec(SType.triangle, cx:.28, size:.13, filled:false), const ShapeSpec(SType.diamond, cx:.72, size:.32, filled:false)]),
        () => c([const ShapeSpec(SType.triangle, size:.22)]),
      ], correct:0),

    // Q10 MEDIUM: Clock +3h
    Question(id:10, type: QType.visual, diff:'medium', label:"Clock time?",
      qWidget: () => _row([_clock(3,0), _clock(6,0), _clock(9,0), null]),
      opts: [
        () => _clock(12, 0),
        () => _clock(11, 0),
        () => _clock(10, 0),
        () => _clock(3, 0),
        () => _clock(6, 30),
        () => _clock(9, 0),
      ], correct:0),

    // Q11 MEDIUM: n²
    Question(id:11, type: QType.num, diff:'medium', label:"What replaces?",
      nums:['1','4','9','16','?'],
      numOpts:['25','20','24','30','18','22'], correct:0),

    // Q12 HARD: Count decreases
    Question(id:12, type: QType.visual, diff:'hard', label:"Count decreases?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle,cx:.18),const ShapeSpec(SType.circle,cx:.4),const ShapeSpec(SType.circle,cx:.62),const ShapeSpec(SType.circle,cx:.84)]),
        c([const ShapeSpec(SType.circle,cx:.23),const ShapeSpec(SType.circle,cx:.5),const ShapeSpec(SType.circle,cx:.77)]),
        c([const ShapeSpec(SType.circle,cx:.32),const ShapeSpec(SType.circle,cx:.68)]),
        c([const ShapeSpec(SType.square,cx:.18),const ShapeSpec(SType.square,cx:.4),const ShapeSpec(SType.square,cx:.62),const ShapeSpec(SType.square,cx:.84)]),
        c([const ShapeSpec(SType.square,cx:.23),const ShapeSpec(SType.square,cx:.5),const ShapeSpec(SType.square,cx:.77)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.square,cx:.32),const ShapeSpec(SType.square,cx:.68)]),
        () => c([const ShapeSpec(SType.square,cx:.23),const ShapeSpec(SType.square,cx:.5),const ShapeSpec(SType.square,cx:.77)]),
        () => c([const ShapeSpec(SType.square)]),
        () => c([const ShapeSpec(SType.circle,cx:.32),const ShapeSpec(SType.circle,cx:.68)]),
        () => c([const ShapeSpec(SType.square,cx:.18),const ShapeSpec(SType.square,cx:.4),const ShapeSpec(SType.square,cx:.62)]),
        () => c([const ShapeSpec(SType.triangle,cx:.32),const ShapeSpec(SType.triangle,cx:.68)]),
      ], correct:0),

    // Q13 HARD: Dot L-pattern
    Question(id:13, type: QType.visual, diff:'hard', label:"Dot L-pattern?",
      qWidget: () => _g3([
        _dotPattern([const Offset(.2,.2),const Offset(.2,.5),const Offset(.2,.8),const Offset(.5,.8),const Offset(.8,.8)]),
        _dotPattern([const Offset(.8,.2),const Offset(.8,.5),const Offset(.8,.8),const Offset(.5,.2),const Offset(.2,.2)]),
        _dotPattern([const Offset(.2,.2),const Offset(.5,.2),const Offset(.8,.2),const Offset(.2,.5),const Offset(.2,.8)]),
        null,
      ]),
      opts: [
        () => _dotPattern([const Offset(.8,.2),const Offset(.8,.5),const Offset(.8,.8),const Offset(.5,.8),const Offset(.2,.8)]),
        () => _dotPattern([const Offset(.2,.2),const Offset(.2,.5),const Offset(.2,.8),const Offset(.5,.8),const Offset(.8,.8)]),
        () => _dotPattern([const Offset(.2,.2),const Offset(.5,.2),const Offset(.8,.2),const Offset(.8,.5),const Offset(.8,.8)]),
        () => _dotPattern([const Offset(.2,.2),const Offset(.5,.5),const Offset(.8,.8),const Offset(.2,.8),const Offset(.8,.2)]),
        () => _dotPattern([const Offset(.2,.8),const Offset(.5,.5),const Offset(.8,.2),const Offset(.5,.8),const Offset(.5,.2)]),
        () => _dotPattern([const Offset(.2,.2),const Offset(.5,.2),const Offset(.8,.2),const Offset(.5,.5),const Offset(.5,.8)]),
      ], correct:0),

    Question(id:-3, type: QType.ms, pct:91,
      msTitle:"You're in the top 9%!",
      msSub:"Exceptional logical reasoning speed."),

    // Q14 HARD: Rotation + fill invert
    Question(id:14, type: QType.visual, diff:'hard', label:"Rotation + fill?",
      qWidget: () => _row5([
        c([const ShapeSpec(SType.triangle, filled:true,  rot:270)]),
        c([const ShapeSpec(SType.triangle, filled:false, rot:0)]),
        c([const ShapeSpec(SType.triangle, filled:true,  rot:90)]),
        c([const ShapeSpec(SType.triangle, filled:false, rot:180)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle, filled:true,  rot:270)]),
        () => c([const ShapeSpec(SType.triangle, filled:false, rot:270)]),
        () => c([const ShapeSpec(SType.triangle, filled:true,  rot:0)]),
        () => c([const ShapeSpec(SType.triangle, filled:false, rot:0)]),
        () => c([const ShapeSpec(SType.triangle, filled:true,  rot:180)]),
        () => c([const ShapeSpec(SType.diamond)]),
      ], correct:0),

    // Q15 HARD: Primes
    Question(id:15, type: QType.num, diff:'hard', label:"Find primes:",
      nums:['2','3','5','7','11','?'],
      numOpts:['13','12','14','15','17','10'], correct:0),

    // Q16 HARD: Row×Col rule
    Question(id:16, type: QType.visual, diff:'hard', label:"Row × Col rule?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle)]),
        c([const ShapeSpec(SType.square)]),
        c([const ShapeSpec(SType.triangle)]),
        c([const ShapeSpec(SType.circle,  filled:false)]),
        c([const ShapeSpec(SType.square,  filled:false)]),
        c([const ShapeSpec(SType.triangle,filled:false)]),
        c([const ShapeSpec(SType.circle,  cx:.35), const ShapeSpec(SType.circle,  cx:.65)]),
        c([const ShapeSpec(SType.square,  cx:.35), const ShapeSpec(SType.square,  cx:.65)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle,cx:.35),const ShapeSpec(SType.triangle,cx:.65)]),
        () => c([const ShapeSpec(SType.triangle,filled:false)]),
        () => c([const ShapeSpec(SType.triangle)]),
        () => c([const ShapeSpec(SType.circle,cx:.35),const ShapeSpec(SType.circle,cx:.65)]),
        () => c([const ShapeSpec(SType.triangle,cx:.35,filled:false),const ShapeSpec(SType.triangle,cx:.65,filled:false)]),
        () => c([const ShapeSpec(SType.diamond,cx:.35),const ShapeSpec(SType.diamond,cx:.65)]),
      ], correct:0),

    Question(id:-4, type: QType.ms, pct:96,
      msTitle:"Almost there! You beat 96%!",
      msSub:"Elite-level problem solving speed."),

    // Q17 EXPERT: 3-corner rotation
    Question(id:17, type: QType.visual, diff:'expert', label:"3-corner rotation?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle,cx:.25,cy:.3),const ShapeSpec(SType.square,cx:.75,cy:.3),const ShapeSpec(SType.triangle,cy:.75)]),
        c([const ShapeSpec(SType.triangle,cx:.25,cy:.3),const ShapeSpec(SType.circle,cx:.75,cy:.3),const ShapeSpec(SType.square,cy:.75)]),
        c([const ShapeSpec(SType.square,cx:.25,cy:.3),const ShapeSpec(SType.triangle,cx:.75,cy:.3),const ShapeSpec(SType.circle,cy:.75)]),
        c([const ShapeSpec(SType.circle,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.square,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.triangle,cy:.75,filled:false)]),
        c([const ShapeSpec(SType.triangle,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.circle,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.square,cy:.75,filled:false)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.square,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.triangle,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.circle,cy:.75,filled:false)]),
        () => c([const ShapeSpec(SType.circle,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.square,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.triangle,cy:.75,filled:false)]),
        () => c([const ShapeSpec(SType.square,cx:.25,cy:.3,filled:true),const ShapeSpec(SType.triangle,cx:.75,cy:.3,filled:true),const ShapeSpec(SType.circle,cy:.75,filled:true)]),
        () => c([const ShapeSpec(SType.triangle,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.circle,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.square,cy:.75,filled:false)]),
        () => c([const ShapeSpec(SType.circle,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.triangle,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.square,cy:.75,filled:false)]),
        () => c([const ShapeSpec(SType.square,cx:.25,cy:.3,filled:false),const ShapeSpec(SType.circle,cx:.75,cy:.3,filled:false),const ShapeSpec(SType.triangle,cy:.75,filled:false)]),
      ], correct:0),

    // Q18 EXPERT: Rain matrix
    Question(id:18, type: QType.visual, diff:'expert', label:"Rain matrix?",
      qWidget: () => _g3([
        _rain(2,3,0), _rain(2,3,20), _rain(2,3,40),
        _rain(3,3,0), _rain(3,3,20), null,
      ]),
      opts: [
        () => _rain(3,3,40),
        () => _rain(2,3,40),
        () => _rain(4,3,40),
        () => _rain(3,3,20),
        () => _rain(3,3,0),
        () => _rain(3,4,40),
      ], correct:0),

    // Q19 EXPERT: n(n+1)
    Question(id:19, type: QType.num, diff:'expert', label:"Find missing:",
      nums:['2','6','12','20','30','?'],
      numOpts:['42','36','40','44','38','48'], correct:0),

    // Q20 EXPERT: Outer+Inner independent
    Question(id:20, type: QType.visual, diff:'expert', label:"Outer + inner?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:true), const ShapeSpec(SType.triangle,size:.13,filled:false)]),
        () => c([const ShapeSpec(SType.circle,  size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.circle,  size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13,filled:false)]),
        () => c([const ShapeSpec(SType.square,  size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
      ], correct:0),

    // Q21 EXPERT: Factorial
    Question(id:21, type: QType.num, diff:'expert', label:"Factorials?",
      nums:['1','2','6','24','?'],
      numOpts:['120','48','100','60','96','72'], correct:0),

    // Q22 EXPERT: Split doubling
    Question(id:22, type: QType.visual, diff:'expert', label:"Split doubling?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle,size:.32)]),
        c([const ShapeSpec(SType.circle,cx:.32,size:.2),const ShapeSpec(SType.circle,cx:.68,size:.2)]),
        c([const ShapeSpec(SType.circle,cx:.23,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.5,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.77,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.37,cy:.68,size:.13)]),
        c([const ShapeSpec(SType.triangle,size:.32)]),
        c([const ShapeSpec(SType.triangle,cx:.32,size:.2),const ShapeSpec(SType.triangle,cx:.68,size:.2)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle,cx:.23,cy:.36,size:.13),const ShapeSpec(SType.triangle,cx:.5,cy:.36,size:.13),const ShapeSpec(SType.triangle,cx:.77,cy:.36,size:.13),const ShapeSpec(SType.triangle,cx:.37,cy:.68,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,cx:.32,size:.2),const ShapeSpec(SType.triangle,cx:.68,size:.2)]),
        () => c([const ShapeSpec(SType.triangle,size:.32)]),
        () => c([const ShapeSpec(SType.circle,cx:.23,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.5,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.77,cy:.36,size:.13),const ShapeSpec(SType.circle,cx:.37,cy:.68,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,cx:.23,cy:.36,size:.13,filled:false),const ShapeSpec(SType.triangle,cx:.5,cy:.36,size:.13,filled:false),const ShapeSpec(SType.triangle,cx:.77,cy:.36,size:.13,filled:false),const ShapeSpec(SType.triangle,cx:.37,cy:.68,size:.13,filled:false)]),
        () => c([const ShapeSpec(SType.triangle,cx:.23,size:.13),const ShapeSpec(SType.triangle,cx:.5,size:.13)]),
      ], correct:0),

    // Q23 EXPERT: Triple axis
    Question(id:23, type: QType.visual, diff:'expert', label:"Triple axis?",
      qWidget: () => _g3([
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.circle,size:.13)]),
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        null,
      ]),
      opts: [
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:true),const ShapeSpec(SType.triangle,size:.13,filled:false)]),
        () => c([const ShapeSpec(SType.circle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.square,size:.13)]),
        () => c([const ShapeSpec(SType.triangle,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13,filled:false)]),
        () => c([const ShapeSpec(SType.square,size:.32,filled:false),const ShapeSpec(SType.triangle,size:.13)]),
      ], correct:0),
  ];
}

// ══════════════════════════════════════════════════════════════
//  MAIN ENTRY SCREEN
// ══════════════════════════════════════════════════════════════
class IQTestScreen extends StatefulWidget {
  const IQTestScreen({super.key});
  @override State<IQTestScreen> createState() => _IQTestScreenState();
}

class _IQTestScreenState extends State<IQTestScreen> {
  String _screen = 'start';
  int _idx = 0;
  int _score = 0;
  int _timeLeft = 1200;
  final List<Map<String, dynamic>> _answers = [];
  late final List<Question> _qs;

  @override
  void initState() {
    super.initState();
    _qs = _buildQuestions();
  }

  List<Question> get _nonMs => _qs.where((q) => q.type != QType.ms).toList();
  int get _qNum => _qs.take(_idx + 1).where((q) => q.type != QType.ms).length;

  void _advance() {
    final next = _idx + 1;
    if (next >= _qs.length) { setState(() => _screen = 'result'); return; }
    setState(() { _idx = next; if (_qs[next].type == QType.ms) _screen = 'ms'; });
  }

  void _onAnswer(int i) {
    final q = _qs[_idx];
    bool correct = false;
    if (q.type == QType.agree) { correct = true; _score++; }
    else if (i == q.correct) { correct = true; _score++; }
    _answers.add({'type': q.type.name, 'diff': q.diff, 'correct': correct});
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: switch (_screen) {
        'start'  => _StartScreen(onStart: () => setState(() { _screen = 'quiz'; _idx = 0; _score = 0; _answers.clear(); _timeLeft = 1200; })),
        'ms'     => _MsScreen(q: _qs[_idx], onNext: () { final next = _idx + 1; setState(() { if (next >= _qs.length) { _screen = 'result'; } else { _idx = next; _screen = 'quiz'; } }); }),
        'result' => _ResultScreen(score: _score, total: _nonMs.length, timeLeft: _timeLeft, answers: _answers),
        _        => _QuestionScreen(
            key: ValueKey(_idx),
            q: _qs[_idx], qNum: _qNum, total: _nonMs.length,
            timeLeft: _timeLeft, onAnswer: _onAnswer,
            onBack: () { if (_idx > 0) setState(() => _idx--); },
            onTick: () => setState(() { if (_timeLeft > 0) _timeLeft--; }),
          ),
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  START SCREEN
// ══════════════════════════════════════════════════════════════
class _StartScreen extends StatefulWidget {
  final VoidCallback onStart;
  const _StartScreen({required this.onStart});
  @override State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  String? _gender;
  Map<String, dynamic>? _record;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final r = prefs.getString('iq_best');
    final h = prefs.getString('iq_history');
    setState(() {
      _record  = r != null ? jsonDecode(r) : null;
      _history = h != null ? jsonDecode(h) : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 10),
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _kPrimary.withOpacity(.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Center(child: Text('🧠', style: TextStyle(fontSize: 26)))),
          const SizedBox(height: 12),
          const Text('IQ Test', style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e))),
          const Text('23 questions · 4 difficulty levels', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 14),

          if (_record != null) _RecordCard(record: _record!),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HistoryCard(history: _history),
          ],
          const SizedBox(height: 12),

          const Text('Gender', style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700, color: Color(0xFF1a1a2e), fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            for (final g in ['Male', 'Female']) Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == 'Male' ? 6 : 0, left: g == 'Female' ? 6 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: _gender == g ? const LinearGradient(colors: [_kPrimary, _kPrimary2], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                      color: _gender == g ? null : _kPrimary.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(g, style: TextStyle(fontWeight: FontWeight.w700, color: _gender == g ? Colors.white : _kPrimary, fontSize: 14))),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _gender != null ? widget.onStart : null,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: _gender != null ? const LinearGradient(colors: [_kPrimary, _kPrimary2], begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
                color: _gender == null ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _gender != null ? [BoxShadow(color: _kPrimary.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 8))] : null,
              ),
              child: Center(child: Text(_record != null ? 'Beat Record 🔥' : 'Start Test', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            ),
          ),
          const SizedBox(height: 20),
        ]),
        ),
        Positioned(
          top: 0, left: 0,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ]),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _RecordCard({required this.record});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Column(children: [
          Text('${record['iq']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.white, height: 1)),
          const Text('Best', style: TextStyle(fontSize: 9, color: Colors.white60)),
        ]),
        const SizedBox(width: 14),
        Container(width: 1, height: 40, color: Colors.white30),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🏆 Record', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            _pill('✅ ${record['score']}/${record['total']}'),
            const SizedBox(width: 6),
            _pill('${record['cat']}'),
          ]),
        ]),
      ]),
    );
  }

  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
  );
}

class _HistoryCard extends StatelessWidget {
  final List<dynamic> history;
  const _HistoryCard({required this.history});
  @override
  Widget build(BuildContext context) {
    final recent = history.reversed.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 Recent', style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700, color: Color(0xFF1a1a2e), fontSize: 11)),
        const SizedBox(height: 7),
        for (int i = 0; i < recent.length; i++) ...[
          if (i > 0) const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${recent[i]['iq']}', style: const TextStyle(fontWeight: FontWeight.w800, color: _kPrimary, fontSize: 14)),
              Text('✅ ${recent[i]['score']}/${recent[i]['total']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MILESTONE SCREEN
// ══════════════════════════════════════════════════════════════
class _MsScreen extends StatelessWidget {
  final Question q;
  final VoidCallback onNext;
  const _MsScreen({required this.q, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎉', style: TextStyle(fontSize: 70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2]), borderRadius: BorderRadius.circular(99)),
            child: Text('Top ${100 - q.pct!}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(height: 14),
          Text(q.msTitle!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF1a1a2e), height: 1.3)),
          const SizedBox(height: 10),
          Text(q.msSub!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onNext,
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2]), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  QUESTION SCREEN
// ══════════════════════════════════════════════════════════════
class _QuestionScreen extends StatefulWidget {
  final Question q;
  final int qNum, total, timeLeft;
  final void Function(int) onAnswer;
  final VoidCallback onBack, onTick;
  const _QuestionScreen({super.key, required this.q, required this.qNum, required this.total,
    required this.timeLeft, required this.onAnswer, required this.onBack, required this.onTick});
  @override State<_QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<_QuestionScreen> {
  int? _sel;

  void _pick(int i) {
    if (_sel != null) return;
    setState(() => _sel = i);
    Future.delayed(const Duration(milliseconds: 360), () => widget.onAnswer(i));
  }

  Color get _timerColor {
    if (widget.timeLeft > 300) return const Color(0xFF16a34a);
    if (widget.timeLeft > 120) return const Color(0xFFd97706);
    return const Color(0xFFdc2626);
  }

  Color get _timerBg {
    if (widget.timeLeft > 300) return const Color(0xFFdcfce7);
    if (widget.timeLeft > 120) return const Color(0xFFfef3c7);
    return const Color(0xFFfee2e2);
  }

  String get _timerText {
    final m = (widget.timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (widget.timeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dc = widget.q.diff != null ? _diffColors[widget.q.diff!] : null;
    return SafeArea(
      child: Column(children: [
        // Header
        Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14)]),
          child: Row(children: [
            GestureDetector(onTap: widget.onBack,
              child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chevron_left, color: Color(0xFF1a1a2e)))),
            const SizedBox(width: 10),
            Expanded(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2]), borderRadius: BorderRadius.circular(99)),
                  child: Text('${widget.qNum}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                const SizedBox(width: 6),
                Text('/ ${widget.total}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (dc != null) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: dc[0], borderRadius: BorderRadius.circular(99)),
                    child: Text(widget.q.diff!.toUpperCase(), style: TextStyle(color: dc[1], fontWeight: FontWeight.w700, fontSize: 9))),
                ],
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: widget.qNum / widget.total, minHeight: 4,
                  backgroundColor: _kBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                )),
            ])),
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: _timerBg, borderRadius: BorderRadius.circular(99)),
              child: Row(children: [
                Icon(Icons.access_time, color: _timerColor, size: 14),
                const SizedBox(width: 4),
                Text(_timerText, style: TextStyle(color: _timerColor, fontWeight: FontWeight.w700, fontSize: 13)),
              ])),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.close, color: Color(0xFFdc2626), size: 18))),
          ])),

        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: [
          // Question body
          if (widget.q.type == QType.agree) ...[
            Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
              child: Column(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('💭', style: TextStyle(fontSize: 22)))),
                const SizedBox(height: 10),
                Text(widget.q.text!, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1a1a2e), height: 1.35)),
              ])),
            for (int i = 0; i < 5; i++) ...[
              const SizedBox(height: 8),
              _AgreeOpt(idx: i, sel: _sel, onTap: () => _pick(i)),
            ],
          ],

          if (widget.q.type == QType.num) ...[
            Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                Text(widget.q.label!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: widget.q.nums!.map((n) => Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: n == '?' ? const LinearGradient(colors: [_kPrimary, _kPrimary2]) : null,
                    color: n == '?' ? null : _kCellBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(n, style: TextStyle(fontWeight: FontWeight.w800, fontSize: n == '?' ? 20 : 17, color: n == '?' ? Colors.white : const Color(0xFF1a1a2e)))),
                )).toList()),
              ])),
            Text('Select answer:', style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xFF1a1a2e).withOpacity(.8), fontSize: 13)),
            const SizedBox(height: 8),
            GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.4,
              children: List.generate(6, (i) => GestureDetector(
                onTap: () => _pick(i),
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: _sel == i ? const LinearGradient(colors: [_kPrimary, _kPrimary2]) : null,
                    color: _sel == i ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)],
                  ),
                  child: Center(child: Text(widget.q.numOpts![i], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _sel == i ? Colors.white : const Color(0xFF1a1a2e)))),
                ),
              ))),
          ],

          if (widget.q.type == QType.visual) ...[
            Container(margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
              child: widget.q.qWidget!()),
            Text(widget.q.label!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1a1a2e), fontSize: 13)),
            const SizedBox(height: 10),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 88 / 72,
              children: List.generate(6, (i) => GestureDetector(
                onTap: () => _pick(i),
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _sel == i ? _kPrimary.withOpacity(.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sel == i ? _kPrimary : Colors.transparent, width: 2.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)],
                  ),
                  child: Center(child: widget.q.opts![i]()),
                ),
              ))),
          ],
          const SizedBox(height: 20),
        ]))),
      ]),
    );
  }
}

class _AgreeOpt extends StatelessWidget {
  final int idx;
  final int? sel;
  final VoidCallback onTap;
  static const _emojis = ['✅', '👍', '😐', '👎', '❌'];
  static const _labels = ['Completely Agree', 'Agree', 'Neutral', 'Disagree', 'Completely Disagree'];
  const _AgreeOpt({required this.idx, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = sel == idx;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(colors: [_kPrimary, _kPrimary2]) : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: active ? _kPrimary.withOpacity(.25) : Colors.black.withOpacity(.04), blurRadius: active ? 16 : 8)],
        ),
        child: Row(children: [
          Text(_emojis[idx], style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(_labels[idx], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: active ? Colors.white : const Color(0xFF1a1a2e))),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RESULT SCREEN
// ══════════════════════════════════════════════════════════════
class _ResultScreen extends StatefulWidget {
  final int score, total, timeLeft;
  final List<Map<String, dynamic>> answers;
  const _ResultScreen({required this.score, required this.total, required this.timeLeft, required this.answers});
  @override State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen> with SingleTickerProviderStateMixin {
  late int _iq, _pct;
  late String _cat;
  bool _isBest = false, _showReview = false;
  late AnimationController _ctrl;
  late Animation<int> _iqAnim;

  @override
  void initState() {
    super.initState();
    final ratio = widget.score / widget.total;
    _iq  = (90 + ratio * 46 + Random().nextInt(5)).round();
    _pct = min(99, (62 + ratio * 33).round());
    _cat = _iq >= 130 ? 'Gifted' : _iq >= 120 ? 'Superior' : _iq >= 110 ? 'Above Avg' : 'Average';
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _iqAnim = IntTween(begin: 0, end: _iq).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _saveRecord();
  }

  Future<void> _saveRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final newRec = {'iq': _iq, 'score': widget.score, 'total': widget.total, 'cat': _cat};
    final best = prefs.getString('iq_best');
    final bestRec = best != null ? jsonDecode(best) : null;
    if (bestRec == null || _iq > bestRec['iq']) {
      await prefs.setString('iq_best', jsonEncode(newRec));
      setState(() => _isBest = true);
    }
    final hist = prefs.getString('iq_history');
    final history = hist != null ? (jsonDecode(hist) as List) : [];
    history.add(newRec);
    await prefs.setString('iq_history', jsonEncode(history.length > 20 ? history.sublist(history.length - 20) : history));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_showReview) return _ReviewScreen(answers: widget.answers, iq: _iq, score: widget.score, total: widget.total, onBack: () => setState(() => _showReview = false));
    final nonAgree = widget.answers.where((a) => a['type'] != 'agree').toList();
    final m = (widget.timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (widget.timeLeft % 60).toString().padLeft(2, '0');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          const SizedBox(height: 10),
          if (_isBest) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF84cc16)]), borderRadius: BorderRadius.circular(99)),
            child: const Text('🏆 PERSONAL BEST!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),

          AnimatedBuilder(animation: _iqAnim, builder: (_, __) => Container(
            width: 110, height: 110,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: _kPrimary.withOpacity(.35), blurRadius: 36, offset: const Offset(0, 10))]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${_iqAnim.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36, height: 1)),
              const Text('IQ', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          )),
          const SizedBox(height: 10),
          Text('Better than $_pct% of participants', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.7,
            children: [
              _statTile('✅', 'Correct', '${widget.score}/${widget.total}'),
              _statTile('⏱️', 'Time', '$m:$s'),
              _statTile('🏆', 'Percentile', 'Top ${100 - _pct}%'),
              _statTile('🎯', 'Category', _cat),
            ]),
          const SizedBox(height: 14),

          // Quick overview grid
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 5, runSpacing: 5, children: nonAgree.asMap().entries.map((e) => Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: e.value['correct'] == true ? const Color(0xFFdcfce7) : const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(7)),
                child: Center(child: Text(e.value['correct'] == true ? '✅' : '❌', style: const TextStyle(fontSize: 14))),
              )).toList()),
            ])),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => setState(() => _showReview = true),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary, width: 2)),
              child: const Center(child: Text('📋 View Full Review', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 14)))),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const IQTestScreen())),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2]), borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _kPrimary.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Center(child: Text('Try Again 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)))),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _statTile(String e, String l, String v) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: _kCellBg, borderRadius: BorderRadius.circular(14)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(e, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 3),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1a1a2e))),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
//  REVIEW SCREEN
// ══════════════════════════════════════════════════════════════
class _ReviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> answers;
  final int iq, score, total;
  final VoidCallback onBack;
  const _ReviewScreen({required this.answers, required this.iq, required this.score, required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final nonAgree = answers.where((a) => a['type'] != 'agree').toList();
    final agree    = answers.where((a) => a['type'] == 'agree').toList();

    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        GestureDetector(onTap: onBack, child: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.chevron_left, color: Color(0xFF1a1a2e)))),
        const SizedBox(width: 10),
        const Text('Question Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1a1a2e))),
      ])),

      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
        // Summary bar
        Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kPrimary, _kPrimary2]), borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(children: [Text('$iq', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, height: 1)), const Text('IQ', style: TextStyle(color: Colors.white60, fontSize: 9))]),
            _mini('${nonAgree.where((a) => a['correct'] == true).length}', 'Correct'),
            _mini('${nonAgree.where((a) => a['correct'] != true).length}', 'Wrong'),
          ])),

        const Text('LOGIC QUESTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey, letterSpacing: .5)),
        const SizedBox(height: 8),

        for (int i = 0; i < nonAgree.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          _ReviewTile(num: i + 1, data: nonAgree[i], label: 'Q'),
        ],

        const SizedBox(height: 14),
        const Text('PERSONALITY QUESTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey, letterSpacing: .5)),
        const SizedBox(height: 8),

        for (int i = 0; i < agree.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          _ReviewTile(num: i + 1, data: agree[i], label: 'P'),
        ],
        const SizedBox(height: 20),
      ]))
    ]));
  }

  Widget _mini(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1)),
    Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

class _ReviewTile extends StatelessWidget {
  final int num;
  final Map<String, dynamic> data;
  final String label;
  const _ReviewTile({required this.num, required this.data, required this.label});
  
  @override
  Widget build(BuildContext context) {
    bool correct = data['correct'] == true;
    bool isAgree = data['type'] == 'agree';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: const Color(0xFFf8f9fa), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('$label$num', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAgree ? 'Personality' : 'Logic (Difficulty: ${data['diff']})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1a1a2e))),
        ])),
        if (!isAgree)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: correct ? const Color(0xFFdcfce7) : const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(6)),
            child: Text(correct ? 'Correct' : 'Wrong', style: TextStyle(color: correct ? const Color(0xFF16a34a) : const Color(0xFFdc2626), fontWeight: FontWeight.w700, fontSize: 10))),
      ]),
    );
  }
}
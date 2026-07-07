import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'shape_masks.dart';

/// Runtime port of the level generator: fills any mask with clean,
/// guaranteed-solvable arrows. Powers "Apna Maze" (name → playable level).

class MazeBuildResult {
  final int gridSize;
  final List<ArrowModel> arrows;
  final Set<String> mask;
  MazeBuildResult(this.gridSize, this.arrows, this.mask);
}

/// Renders [text] into a grid mask, then fills it with arrows.
/// Returns null when the text is unusable (too little ink / unsolvable).
Future<MazeBuildResult?> buildNameMaze(String text) async {
  final clean = text.trim().toUpperCase();
  if (clean.isEmpty) return null;

  // Long names wrap onto two lines so every letter stays big and readable.
  String rendered = clean;
  if (clean.length > 4) {
    int split = (clean.length / 2).ceil();
    final spaceIdx = clean.indexOf(' ');
    if (spaceIdx > 0 && spaceIdx < clean.length - 1) split = spaceIdx;
    rendered =
        '${clean.substring(0, split).trim()}\n${clean.substring(split).trim()}';
  }
  final maxLine =
      rendered.split('\n').map((l) => l.length).reduce(max);

  // Resolution scales with the widest line: ~16 cells per letter keeps
  // strokes 3-4 cells thick, so the alphabet reads clearly.
  final gs = (maxLine * 16 + 12).clamp(44, 96);

  final mask = await _maskFromText(rendered, gs);
  if (mask.length < 50) return null;
  for (int attempt = 0; attempt < 10; attempt++) {
    final arrows = _fillMask(mask, gs, clean.hashCode * 31 + attempt);
    if (arrows != null) return MazeBuildResult(gs, arrows, mask);
  }
  return null;
}

/// Builds a playable maze from any library shape (used by Daily Challenge).
MazeBuildResult? buildShapeMaze(String shapeName, {int seed = 0, int gs = 36}) {
  final mask = maskForShape(shapeName, gs);
  if (mask.length < 50) return null;
  for (int attempt = 0; attempt < 10; attempt++) {
    final arrows = _fillMask(mask, gs, seed * 31 + attempt);
    if (arrows != null) return MazeBuildResult(gs, arrows, mask);
  }
  return null;
}

Future<Set<String>> _maskFromText(String text, int gs) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 100,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 12,
        height: 1.15,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  if (tp.width <= 0 || tp.height <= 0) return {};
  final scale = min((gs - 2) / tp.width, (gs * 0.9) / tp.height);
  canvas.scale(scale);
  tp.paint(
    canvas,
    Offset((gs / scale - tp.width) / 2, (gs / scale - tp.height) / 2),
  );
  final img = await recorder.endRecording().toImage(gs, gs);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  if (data == null) return {};
  final mask = <String>{};
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      if (data.getUint8((y * gs + x) * 4 + 3) > 100) mask.add('$x,$y');
    }
  }
  return mask;
}

/// Same center-out fill as the level generator, tuned for thin letter
/// strokes (short arrows). Returns null when the result is not solvable
/// or leaves too many holes.
List<ArrowModel>? _fillMask(Set<String> mask, int gs, int seed) {
  final rand = Random(seed);
  final maskList = mask.toList();
  final occupied = <String>{};
  final arrows = <Map<String, dynamic>>[];
  int idGen = 1;

  bool free(int x, int y) =>
      x >= 0 && x < gs && y >= 0 && y < gs &&
      mask.contains('$x,$y') && !occupied.contains('$x,$y');

  bool rayClear(int hx, int hy, int dx, int dy) {
    int nx = hx + dx, ny = hy + dy;
    while (nx >= 0 && nx < gs && ny >= 0 && ny < gs) {
      if (occupied.contains('$nx,$ny')) return false;
      nx += dx;
      ny += dy;
    }
    return true;
  }

  bool commit(List<List<int>> path) {
    if (path.length < 2) return false;
    var h = path.last, n = path[path.length - 2];
    if (!rayClear(h[0], h[1], h[0] - n[0], h[1] - n[1])) {
      h = path.first;
      n = path[1];
      if (!rayClear(h[0], h[1], h[0] - n[0], h[1] - n[1])) return false;
      path = path.reversed.toList();
    }
    arrows.add({'id': idGen++, 'path': path, 'colorIndex': rand.nextInt(5)});
    for (final p in path) {
      occupied.add('${p[0]},${p[1]}');
    }
    return true;
  }

  int runLen(int x, int y, int dx, int dy) {
    int n = 0;
    int cx = x + dx, cy = y + dy;
    while (free(cx, cy) && n < 10) {
      n++;
      cx += dx;
      cy += dy;
    }
    return n;
  }

  // Prefer the direction with the longest open run, so arrows lie ALONG the
  // letter strokes (vertical stems get vertical arrows) and stay readable.
  List<List<int>> strokeDirs(int x, int y) {
    final dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    dirs.shuffle(rand);
    dirs.sort((a, b) =>
        runLen(x, y, b[0], b[1]).compareTo(runLen(x, y, a[0], a[1])));
    return dirs;
  }

  List<List<int>>? walk(int sx, int sy, int dx, int dy, int steps) {
    if (!free(sx, sy)) return null;
    final path = [[sx, sy]];
    int cx = sx, cy = sy;
    for (int s = 0; s < steps; s++) {
      final nx = cx + dx, ny = cy + dy;
      if (!free(nx, ny)) return path;
      cx = nx;
      cy = ny;
      path.add([cx, cy]);
    }
    return path;
  }

  double rOf(String c) {
    final p = c.split(',');
    final dx = int.parse(p[0]) + 0.5 - gs / 2;
    final dy = int.parse(p[1]) + 0.5 - gs / 2;
    return dx * dx + dy * dy;
  }

  final ordered = maskList.toList()
    ..shuffle(rand)
    ..sort((a, b) => rOf(a).compareTo(rOf(b)));

  // Straight arrows only, laid along the letter strokes; up to 8 cells long
  // so a stem becomes one or two clean arrows instead of clutter.
  for (int pass = 0; pass < 6; pass++) {
    for (final cell in ordered) {
      final pt = cell.split(',');
      final sx = int.parse(pt[0]), sy = int.parse(pt[1]);
      if (!free(sx, sy)) continue;
      for (final d in strokeDirs(sx, sy)) {
        final path = walk(sx, sy, d[0], d[1], 3 + rand.nextInt(5));
        if (path != null && path.length >= 3 && commit(path)) break;
      }
    }
  }
  for (final len in [3, 2]) {
    for (final cell in ordered) {
      final pt = cell.split(',');
      final sx = int.parse(pt[0]), sy = int.parse(pt[1]);
      if (!free(sx, sy)) continue;
      for (final d in strokeDirs(sx, sy)) {
        final path = walk(sx, sy, d[0], d[1], len - 1);
        if (path != null && path.length == len && commit(path)) break;
      }
    }
  }

  if (occupied.length / mask.length < 0.70) return null;
  if (!_isSolvable(arrows, gs)) return null;

  return arrows
      .map((a) => ArrowModel(
            id: a['id'] as int,
            path: (a['path'] as List<List<int>>),
            arrowAtEnd: true,
            colorIndex: a['colorIndex'] as int,
          ))
      .toList();
}

bool _isSolvable(List<Map<String, dynamic>> arrows, int gs) {
  final remaining = <int, List<List<int>>>{};
  final occ = <String>{};
  for (final a in arrows) {
    final path = a['path'] as List<List<int>>;
    remaining[a['id'] as int] = path;
    for (final p in path) {
      occ.add('${p[0]},${p[1]}');
    }
  }
  bool progress = true;
  while (progress && remaining.isNotEmpty) {
    progress = false;
    for (final id in remaining.keys.toList()) {
      final path = remaining[id]!;
      final h = path.last, n = path[path.length - 2];
      final dx = h[0] - n[0], dy = h[1] - n[1];
      int x = h[0] + dx, y = h[1] + dy;
      bool clear = true;
      while (x >= 0 && x < gs && y >= 0 && y < gs) {
        if (occ.contains('$x,$y') && !path.any((p) => p[0] == x && p[1] == y)) {
          clear = false;
          break;
        }
        x += dx;
        y += dy;
      }
      if (clear) {
        for (final p in path) {
          occ.remove('${p[0]},${p[1]}');
        }
        remaining.remove(id);
        progress = true;
      }
    }
  }
  return remaining.isEmpty;
}

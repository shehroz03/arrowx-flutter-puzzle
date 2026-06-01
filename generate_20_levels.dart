// 20 Level Generator — 5 arrows on level 1, +5 per level (Level 20 = 100 arrows)
// Run with: dart generate_20_levels.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

int _nextId = 1;

void main() {
  final levels = <Map<String, dynamic>>[];

  for (int lvl = 1; lvl <= 20; lvl++) {
    _nextId = 1;
    final int targetArrows = lvl * 5; // 5, 10, 15, ... 100

    // Grid size: enough room for all arrows with spacing
    // Each arrow takes 2 cells; checkerboard means ~25% of grid usable
    // We want at least targetArrows * 4 cells total → gs = sqrt(targetArrows * 4) + some padding
    int gs = (sqrt(targetArrows * 5).ceil() + 2);
    if (gs < 10) gs = 10;
    if (gs % 2 != 0) gs++;   // keep even

    final arrows = _generateArrows(gs, targetArrows, lvl);

    levels.add({
      'level': lvl,
      'gridSize': gs,
      'arrows': arrows,
      'isHardStage': lvl % 5 == 0,
    });
  }

  // Verify all levels
  print('\n═══ VERIFICATION ═══');
  bool allGood = true;
  for (var lvl in levels) {
    final ok = _verify(lvl);
    if (!ok) allGood = false;
  }

  if (allGood) {
    // Write to file
    final encoder = JsonEncoder.withIndent('  ');
    File('assets/levels.json').writeAsStringSync(encoder.convert(levels));
    print('\n✅ Generated ${levels.length} levels → assets/levels.json');
  } else {
    print('\n❌ Some levels failed verification — not writing file!');
  }
}

/// Place [target] arrows on a [gs]×[gs] grid pointing outward from center.
/// Uses checkerboard pattern so no two arrows overlap.
List<Map<String, dynamic>> _generateArrows(int gs, int target, int lvlNum) {
  final List<Map<String, dynamic>> arrows = [];
  final Set<String> occupied = {};
  double cx = (gs - 1) / 2.0;
  double cy = (gs - 1) / 2.0;

  // Score each checkerboard cell by distance from centre (varied by level shape)
  final List<Map<String, dynamic>> candidates = [];

  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      if ((x + y) % 2 != 0) continue; // checkerboard: only even cells

      final double dx = x - cx;
      final double dy = y - cy;

      // Direction: point away from center
      List<int> dir;
      if (dx.abs() >= dy.abs()) {
        dir = dx >= 0 ? [1, 0] : [-1, 0];
      } else {
        dir = dy >= 0 ? [0, 1] : [0, -1];
      }

      final int nx = x + dir[0];
      final int ny = y + dir[1];

      // Must fit in grid
      if (nx < 0 || nx >= gs || ny < 0 || ny >= gs) continue;

      // Score: concentric rings (closer to a ring at radius gs/3, gs/4, etc.)
      double radius = sqrt(dx * dx + dy * dy);
      double ring = (gs / 3.0);
      // Vary ring target by level to get different visual shapes
      switch (lvlNum % 6) {
        case 0: ring = gs / 2.2; break; // outer ring
        case 1: ring = gs / 3.0; break; // medium ring
        case 2: ring = min(dx.abs(), dy.abs()); break; // cross
        case 3: ring = gs / 4.0; break; // inner ring
        case 4: ring = (dx.abs() - dy.abs()).abs(); break; // X shape
        case 5: ring = gs / 2.5; break; // diamond-ish
      }
      double score = (radius - ring).abs();

      candidates.add({'x': x, 'y': y, 'dir': dir, 'score': score});
    }
  }

  // Sort by score (best-fit cells first)
  candidates.sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));

  int colorIdx = 0;
  for (var c in candidates) {
    if (arrows.length >= target) break;

    final int x = c['x'] as int;
    final int y = c['y'] as int;
    final List<int> dir = c['dir'] as List<int>;
    final int nx = x + dir[0];
    final int ny = y + dir[1];

    final String k1 = '$x,$y';
    final String k2 = '$nx,$ny';
    if (occupied.contains(k1) || occupied.contains(k2)) continue;

    occupied.add(k1);
    occupied.add(k2);

    arrows.add({
      'id': _nextId++,
      'path': [[x, y], [nx, ny]],
      'arrowhead': 'last',
      'colorIndex': colorIdx % 5,
    });
    colorIdx++;
  }

  return arrows;
}

/// Verify a level is solvable (at least one arrow can exit at any given time)
bool _verify(Map<String, dynamic> lvl) {
  final int level = lvl['level'] as int;
  final int gs = lvl['gridSize'] as int;
  final List arrowsRaw = lvl['arrows'] as List;

  // Build arrow models
  final arrows = arrowsRaw.map((a) {
    final path = (a['path'] as List).map((pt) {
      final p = pt as List;
      return [(p[0] as num).toInt(), (p[1] as num).toInt()];
    }).toList();

    final head = path.last;
    final prev = path[path.length - 2];
    final dir = [(head[0] - prev[0]).sign, (head[1] - prev[1]).sign];

    return {
      'id': a['id'],
      'path': path,
      'dir': dir,
      'solved': false,
    };
  }).toList();

  // Check overlaps
  final Set<String> cells = {};
  bool hasOverlap = false;
  for (var a in arrows) {
    for (var p in a['path'] as List) {
      final pt = p as List;
      final k = '${pt[0]},${pt[1]}';
      if (cells.contains(k)) {
        hasOverlap = true;
      }
      cells.add(k);
    }
  }

  // Simulate solving
  int solved = 0;
  for (int round = 0; round < arrows.length; round++) {
    bool progress = false;
    for (var a in arrows) {
      if (a['solved'] == true) continue;

      final Set<String> blocked = {};
      for (var o in arrows) {
        if (o['id'] == a['id'] || o['solved'] == true) continue;
        for (var p in o['path'] as List) {
          final pt = p as List;
          blocked.add('${pt[0]},${pt[1]}');
        }
      }

      final path = a['path'] as List;
      final head = path.last as List;
      final dir = a['dir'] as List;
      int x = (head[0] as int) + (dir[0] as int);
      int y = (head[1] as int) + (dir[1] as int);
      bool isBlocked = false;
      while (x >= 0 && x < gs && y >= 0 && y < gs) {
        if (blocked.contains('$x,$y')) { isBlocked = true; break; }
        x += dir[0] as int;
        y += dir[1] as int;
      }
      if (!isBlocked) {
        a['solved'] = true;
        solved++;
        progress = true;
      }
    }
    if (!progress) break;
  }

  final int arrowCount = arrows.length;
  if (solved == arrowCount) {
    print('✅ Level $level: SOLVABLE ($arrowCount arrows, ${gs}x$gs)${hasOverlap ? " ⚠️ OVERLAPS" : ""}');
    return true;
  } else {
    print('❌ Level $level: IMPOSSIBLE! ${arrowCount - solved} stuck');
    return false;
  }
}

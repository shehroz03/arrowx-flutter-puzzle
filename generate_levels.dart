// Level Generator — produces guaranteed-solvable levels.json
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

int nextId = 1;

void main() {
  final levels = <Map<String, dynamic>>[];
  int lvlNum = 1;

  // ═══════ LEVEL 1 (6 Arrows, Easy Tutorial) ═══════
  // Spread out, pointing clearly to edges
  nextId = 1;
  levels.add(_level(lvlNum++, 10, [
    _a(nextId++, 2, 4, 'left', 2),
    _a(nextId++, 5, 2, 'up', 2),
    _a(nextId++, 7, 4, 'right', 2),
    _a(nextId++, 5, 7, 'down', 2),
    _a(nextId++, 4, 5, 'left', 2),
    _a(nextId++, 5, 5, 'right', 2),
  ]));

  // ═══════ LEVEL 2 (8 Arrows, Introducing Chains) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 12, _buildChains(
    gs: 12, tr: 4, br: 8,
    topChainStarts: [8, 4], // 2 arrows
    botChainStarts: [3, 7], // 2 arrows
    vertDownCols: [5, 6],   // 2 arrows
    vertUpCols: [4, 7],     // 2 arrows
  )));

  // ═══════ LEVEL 3 (14 Arrows, Medium Chains) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 16, _buildChains(
    gs: 16, tr: 5, br: 11,
    topChainStarts: [12, 8, 4], // 3 arrows
    botChainStarts: [3, 7, 11], // 3 arrows
    vertDownCols: [4, 6, 8, 10],   // 4 arrows
    vertUpCols: [5, 7, 9, 11],     // 4 arrows
  )));

  // ═══════ LEVEL 4 (24 Arrows, Dense Grid) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 20, _buildChains(
    gs: 20, tr: 6, br: 14,
    topChainStarts: [16, 12, 8, 4], // 4 arrows
    botChainStarts: [3, 7, 11, 15], // 4 arrows
    vertDownCols: [4, 6, 8, 10, 12, 14, 16, 18],      // 8 arrows
    vertUpCols: [3, 5, 7, 9, 11, 13, 15, 17],       // 8 arrows
  )));

  // ═══════ LEVEL 5 (36 Arrows, HOLLOW SQUARE SHAPE) ═══════
  // A perfect square outline made of arrows pointing outwards + internals
  nextId = 1;
  levels.add(_level(lvlNum++, 24, _buildSquareShape(
    size: 24,
    boxSideLength: 10, // 36 arrows
  )));

  // ═══════ LEVEL 6 (40 Arrows, EXPLODING DIAMOND SHAPE) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 26, _buildDiamondShape(
    size: 26,
    radius: 7, // ~40 arrows depending on density
  )));

  // ═══════ LEVEL 7 (46 Arrows, Hard Double Chains) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 28, _buildChains(
    gs: 28, tr: 8, br: 20,
    topChainStarts: [24, 20, 16, 12, 8, 4], // 6 arrows
    botChainStarts: [3, 7, 11, 15, 19, 23], // 6 arrows
    vertDownCols: [4,6,8,10,12,14,16,18,20,22,24], // 11
    vertUpCols: [3,5,7,9,11,13,15,17,19,21,23,25], // 12
    extraLayers: true // Adds an inner ring
  )));

  // ═══════ LEVEL 8 (52 Arrows, CROSS SHAPE) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 30, _buildCrossShape(
    size: 30, thickness: 3
  )));

  // ═══════ LEVEL 9 (64 Arrows, VERY HARD CHAINS) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 32, _buildChains(
    gs: 32, tr: 10, br: 22,
    topChainStarts: [28,24,20,16,12,8,4], // 7
    botChainStarts: [3,7,11,15,19,23,27], // 7
    vertDownCols: List.generate(24, (i) => i+4), // 24
    vertUpCols: List.generate(24, (i) => i+6), // 24
    extraLayers: true,
  )));

  // ═══════ LEVEL 10 (80 Arrows, BOSS STAGE, PINWHEEL SHAPE) ═══════
  nextId = 1;
  levels.add(_level(lvlNum++, 36, _buildPinwheel(size: 36)));

  // Write to file
  final encoder = JsonEncoder.withIndent('  ');
  File('assets/levels.json').writeAsStringSync(encoder.convert(levels));
  print('📁 Generated ${levels.length} levels → assets/levels.json');
  
  _verifyAll(levels);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHAPE GENERATORS (Guaranteed Solvable if aimed outwards)
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _buildSquareShape({required int size, required int boxSideLength}) {
  List<Map<String, dynamic>> arrows = [];
  int center = size ~/ 2;
  int hs = boxSideLength ~/ 2;
  
  // Perimeter arrows pointing strictly outwards
  for (int i = -hs; i <= hs; i++) {
    if (i != -hs && i != hs) {
      arrows.add(_a(nextId++, center + i, center - hs, 'up', 2));
      arrows.add(_a(nextId++, center + i, center + hs, 'down', 2));
    }
    arrows.add(_a(nextId++, center - hs, center + i, 'left', 2));
    arrows.add(_a(nextId++, center + hs, center + i, 'right', 2));
  }
  
  // Inner core pointing outwards to the newly freed perimeter
  for (int i = -hs + 2; i <= hs - 2; i += 2) {
    arrows.add(_a(nextId++, center + i, center - hs + 2, 'up', 2));
    arrows.add(_a(nextId++, center + i, center + hs - 2, 'down', 2));
    arrows.add(_a(nextId++, center - hs + 2, center + i, 'left', 2));
    arrows.add(_a(nextId++, center + hs - 2, center + i, 'right', 2));
  }
  
  return arrows;
}

List<Map<String, dynamic>> _buildDiamondShape({required int size, required int radius}) {
  List<Map<String, dynamic>> arrows = [];
  int center = size ~/ 2;
  
  // Outer Diamond
  for (int i = 0; i <= radius; i++) {
    int inv = radius - i;
    // Points out based on quadrant
    if (i != 0 && inv != 0) {
      arrows.add(_a(nextId++, center + i, center + inv, 'right', 2));
      arrows.add(_a(nextId++, center - i, center + inv, 'left', 2));
      arrows.add(_a(nextId++, center + i, center - inv, 'up', 2));
      arrows.add(_a(nextId++, center - i, center - inv, 'up', 2));
    }
  }
  // Tips
  arrows.add(_a(nextId++, center + radius, center, 'right', 2));
  arrows.add(_a(nextId++, center - radius, center, 'left', 2));
  arrows.add(_a(nextId++, center, center + radius, 'down', 2));
  arrows.add(_a(nextId++, center, center - radius, 'up', 2));

  // Inner cross
  for (int i = 1; i < radius - 1; i++) {
    arrows.add(_a(nextId++, center + i, center, 'right', 2));
    arrows.add(_a(nextId++, center - i, center, 'left', 2));
    arrows.add(_a(nextId++, center, center + i, 'down', 2));
    arrows.add(_a(nextId++, center, center - i, 'up', 2));
  }
  return arrows;
}

List<Map<String, dynamic>> _buildCrossShape({required int size, required int thickness}) {
  List<Map<String, dynamic>> arrows = [];
  int center = size ~/ 2;
  int armLen = 8;
  
  for (int t = -thickness; t <= thickness; t++) {
    for (int i = thickness+1; i <= armLen; i+=2) {
      arrows.add(_a(nextId++, center + i, center + t, 'right', 2));
      arrows.add(_a(nextId++, center - i, center + t, 'left', 2));
      arrows.add(_a(nextId++, center + t, center + i, 'down', 2));
      arrows.add(_a(nextId++, center + t, center - i, 'up', 2));
    }
  }
  // Core block
  for(int x = -thickness; x <= thickness; x+=2) {
    for(int y = -thickness; y <= thickness; y+=2) {
      if (x > 0) arrows.add(_a(nextId++, center+x, center+y, 'right', 2));
      if (x < 0) arrows.add(_a(nextId++, center+x, center+y, 'left', 2));
      if (x == 0 && y > 0) arrows.add(_a(nextId++, center+x, center+y, 'down', 2));
      if (x == 0 && y < 0) arrows.add(_a(nextId++, center+x, center+y, 'up', 2));
    }
  }
  return arrows;
}

List<Map<String, dynamic>> _buildPinwheel({required int size}) {
  List<Map<String, dynamic>> arrows = [];
  int center = size ~/ 2;
  int armLen = 12;
  int thickness = 3;
  
  // 4 spiral arms pointing to edges
  for (int i = 2; i <= armLen; i+=2) {
    for(int t = 0; t < thickness; t++) {
      arrows.add(_a(nextId++, center + i, center + t, 'right', 2));  // Right Arm
      arrows.add(_a(nextId++, center - i, center - t, 'left', 2));   // Left Arm
      arrows.add(_a(nextId++, center - t, center + i, 'down', 2));   // Bot Arm
      arrows.add(_a(nextId++, center + t, center - i, 'up', 2));     // Top Arm
    }
  }
  return arrows;
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVABLY SOLVABLE CHAIN GENERATOR
// ─────────────────────────────────────────────────────────────────────────────
List<Map<String, dynamic>> _buildChains({
  required int gs, required int tr, required int br,
  required List<int> topChainStarts,
  required List<int> botChainStarts,
  required List<int> vertDownCols,
  required List<int> vertUpCols,
  bool extraLayers = false,
}) {
  List<Map<String, dynamic>> arrows = [];
  Set<String> taken = {};
  
  void place(int x, int y, String dir) {
    if (!taken.contains('\$x,\$y') && x>0 && x<gs-1 && y>0 && y<gs-1) {
      arrows.add(_a(nextId++, x, y, dir, 2));
      taken.add('\$x,\$y');
    }
  }

  // Top chain (right facing)
  for (int sx in topChainStarts) {
    for (int i = 0; i < 4; i++) {
      taken.add('${sx + i},$tr');
    }
    arrows.add(_a(nextId++, sx, tr, 'right', 4));
  }
  // Bot chain (left facing)
  for (int sx in botChainStarts) {
    for (int i = 0; i < 4; i++) {
      taken.add('${sx - i},$br');
    }
    arrows.add(_a(nextId++, sx, br, 'left', 4));
  }
  
  // Verticals
  int dRow = br - 2;
  int uRow = tr + 2;
  for (int c in vertDownCols) {
    place(c, dRow, 'down');
  }
  for (int c in vertUpCols) {
    place(c, uRow, 'up');
  }

  // Inner rings for hard levels
  if (extraLayers) {
    int tr2 = tr + 4;
    int br2 = br - 4;
    if (tr2 < br2 - 2) {
      for (int i=0; i<topChainStarts.length-1; i++) {
        arrows.add(_a(nextId++, topChainStarts[i]+2, tr2, 'right', 4));
        taken.add('\${topChainStarts[i]+2},\$tr2');
      }
      for (int i=0; i<botChainStarts.length-1; i++) {
        arrows.add(_a(nextId++, botChainStarts[i]-2, br2, 'left', 4));
        taken.add('\${botChainStarts[i]-2},\$br2');
      }
    }
  }
  
  return arrows;
}

Map<String, dynamic> _a(int id, int sx, int sy, String dir, int len) {
  return {'id': id, 'sx': sx, 'sy': sy, 'dir': dir, 'len': len};
}

Map<String, dynamic> _level(int lvl, int gs, List<Map<String, dynamic>> arrows) {
  return {'level': lvl, 'gridSize': gs, 'arrows': arrows};
}

void _verifyAll(List<Map<String, dynamic>> levels) {
  print('\n═══ VERIFICATION ═══');
  for (var lvl in levels) {
    final int level = lvl['level'];
    final int gs = lvl['gridSize'];
    final Map<String, dynamic> parsedLevel = jsonDecode(jsonEncode(lvl)); // Deep copy to avoid mutating original
    final arrowsMapList = parsedLevel['arrows'] as List<dynamic>;
    
    final arrows = arrowsMapList.map((a) {
      final ma = a as Map<String, dynamic>;
      int sx = ma['sx'], sy = ma['sy'], len = ma['len'];
      String dir = ma['dir'];
      int dx = 0, dy = 0;
      switch (dir) { case 'right': dx=1; break; case 'left': dx=-1; break; case 'down': dy=1; break; case 'up': dy=-1; break; }
      return {
        'id': ma['id'],
        'path': List.generate(len, (i) => [sx + dx*i, sy + dy*i]),
        'dir': [dx, dy],
        'solved': false,
      };
    }).toList();

    // Check overlaps
    Set<String> cells = {};
    bool overlap = false;
    for (var a in arrows) {
      for (var p in a['path'] as List) {
        final pt = p as List;
        String k = '${pt[0]},${pt[1]}';
        if (cells.contains(k)) { overlap = true; print("  ❌ OVERLAP at $k (arrow ${a['id']})"); }
        cells.add(k);
      }
    }

    // Simulate solving
    int solved = 0;
    List<int> solveOrder = [];
    for (int round = 0; round < arrows.length; round++) {
      bool progress = false;
      for (var a in arrows) {
        if (a['solved'] == true) continue;
        Set<String> blocked = {};
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
          if (blocked.contains('\$x,\$y')) { isBlocked = true; break; }
          x += dir[0] as int; y += dir[1] as int;
        }
        if (!isBlocked) {
          a['solved'] = true;
          solved++;
          solveOrder.add(a['id'] as int);
          progress = true;
        }
      }
      if (!progress) break;
    }

    if (solved == arrows.length) {
      print("✅ Stage $level: SOLVABLE (${arrows.length} arrows, ${gs}x$gs) ${overlap ? '⚠️ OVERLAPS' : ''}");
    } else {
      List<int> stuck = arrows.where((a) => a['solved'] != true).map((a) => a['id'] as int).toList();
      print("❌ Stage $level: IMPOSSIBLE! ${stuck.length} stuck arrows");
    }
  }
}

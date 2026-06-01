// Standalone level solvability verifier — run with: dart run verify_levels.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/levels.json');
  final data = json.decode(file.readAsStringSync()) as List;

  for (var lvl in data) {
    final int level = lvl['level'];
    final int gs = lvl['gridSize'];
    final arrows = (lvl['arrows'] as List).map((a) {
      List<List<int>> arrowPath;
      List<int> flyDir;
      if (a.containsKey('path')) {
        arrowPath = (a['path'] as List).map((pt) {
          final p = pt as List;
          return [(p[0] as num).toInt(), (p[1] as num).toInt()];
        }).toList();
        
        if (arrowPath.length < 2) {
          flyDir = [0, -1];
        } else {
          final head = arrowPath.last;
          final prev = arrowPath[arrowPath.length - 2];
          flyDir = [(head[0] - prev[0]).sign, (head[1] - prev[1]).sign];
        }
      } else {
        int sx = a['sx'], sy = a['sy'], len = a['len'];
        String dir = a['dir'];
        int dx = 0, dy = 0;
        switch (dir) { case 'right': dx=1; break; case 'left': dx=-1; break; case 'down': dy=1; break; case 'up': dy=-1; break; }
        arrowPath = List.generate(len, (i) => [sx + dx*i, sy + dy*i]);
        flyDir = [dx, dy];
      }
      return {
        'id': a['id'],
        'path': arrowPath,
        'dir': flyDir,
        'solved': false,
      };
    }).toList();

    // Check for cell overlaps in initial state
    Set<String> allCells = {};
    bool hasOverlap = false;
    for (var a in arrows) {
      for (var p in a['path'] as List) {
        String key = '${(p as List)[0]},${p[1]}';
        if (allCells.contains(key)) {
          print('  ❌ OVERLAP at $key (arrow ${a['id']})');
          hasOverlap = true;
        }
        allCells.add(key);
      }
    }

    // Simulate solving
    int solved = 0;
    int maxIterations = arrows.length * arrows.length; // Prevent infinite loop
    int iterations = 0;

    while (solved < arrows.length && iterations < maxIterations) {
      iterations++;
      bool progress = false;

      for (var arrow in arrows) {
        if (arrow['solved'] == true) continue;

        // Build blocked set from unsolved arrows
        Set<String> blocked = {};
        for (var other in arrows) {
          if (other['id'] == arrow['id'] || other['solved'] == true) continue;
          for (var p in other['path'] as List) {
            blocked.add('${(p as List)[0]},${p[1]}');
          }
        }

        // Raycast from head
        final path = arrow['path'] as List;
        final head = path.last as List;
        final dir = arrow['dir'] as List;
        int x = (head[0] as int) + (dir[0] as int);
        int y = (head[1] as int) + (dir[1] as int);
        bool isBlocked = false;

        while (x >= 0 && x < gs && y >= 0 && y < gs) {
          if (blocked.contains('$x,$y')) { isBlocked = true; break; }
          x += dir[0] as int;
          y += dir[1] as int;
        }

        if (!isBlocked) {
          arrow['solved'] = true;
          solved++;
          progress = true;
        }
      }

      if (!progress) break; // No arrow could be freed this round
    }

    // Report
    if (solved == arrows.length) {
      print('✅ Level $level: SOLVABLE (${arrows.length} arrows, ${gs}x$gs grid)${hasOverlap ? " ⚠️ HAS OVERLAPS" : ""}');
    } else {
      int remaining = arrows.length - solved;
      List<int> stuckIds = arrows.where((a) => a['solved'] != true).map((a) => a['id'] as int).toList();
      print('❌ Level $level: IMPOSSIBLE! $remaining stuck arrows: $stuckIds');
    }
  }
}

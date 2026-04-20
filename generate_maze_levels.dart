// Guaranteed solvable Maze Generator - Expanded to 50 Levels
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final file = File('assets/levels.json');
  final data = json.decode(file.readAsStringSync()) as List;

  // Keep levels 1 to 4 (Tutorials/Intro)
  final newLevels = data.where((lvl) => lvl['level'] < 5).toList();

  final List<Map<String, dynamic>> configs = [];
  
  // Generating configs for stage 5 to 50
  for (int i = 5; i <= 50; i++) {
    int gridSize;
    if (i <= 10) {
      gridSize = 12 + (i - 5); // 12 to 17
    } else if (i <= 20) {
      gridSize = 18 + (i - 11); // 18 to 27
    } else if (i <= 35) {
      gridSize = 28 + ((i - 21) ~/ 2); // 28 to 35
    } else {
      gridSize = 36 + ((i - 36) ~/ 3); // 36 to 40
    }
    
    // Level 5 is a bit easier, 6+ are high-density "Boss" levels
    configs.add({
      'lvl': i, 
      'gs': gridSize, 
      'arrows': i == 5 ? 15 : 0 // 0 means fill until max
    });
  }

  final rand = Random(1234); // Reproducible high-quality maps

  for (var cfg in configs) {
    int gs = cfg['gs'] as int;
    int targetArrows = cfg['arrows'] as int;
    int lvlNum = cfg['lvl'] as int;

    List<Map<String, dynamic>> arrows = [];
    Set<String> allCells = {};

    bool isFree(int x, int y) {
      if (x < 0 || x >= gs || y < 0 || y >= gs) return false;
      return !allCells.contains('$x,$y');
    }

    bool raycastHits(int hx, int hy, int dx, int dy) {
      int nx = hx + dx, ny = hy + dy;
      while (nx >= 0 && nx < gs && ny >= 0 && ny < gs) {
        if (allCells.contains('$nx,$ny')) return true;
        nx += dx; ny += dy;
      }
      return false;
    }

    Map<int, List<String>> arrowRays = {};
    int idGen = 1;

    bool isExtreme = lvlNum >= 15;
    int loopLimit = lvlNum >= 6 ? 100000 : targetArrows;
    int consecutiveFails = 0;

    for (int i = 0; i < loopLimit; i++) {
        bool placed = false;
        int maxAttempts = isExtreme ? 100000 : 5000;
        
        for(int attempt = 0; attempt < maxAttempts; attempt++) {
            if (allCells.length >= (gs * gs) - 2) break; 

            int sx = rand.nextInt(gs);
            int sy = rand.nextInt(gs);
            if (!isFree(sx, sy)) continue;

            List<List<int>> path = [[sx, sy]];
            Set<String> tempCells = {'$sx,$sy'};
            
            int cx = sx, cy = sy;
            var dirs = [[1,0], [-1,0], [0,1], [0,-1]];
            int cdIdx = rand.nextInt(4);
            
            // Incremental complexity: Longer and more winding paths as levels increase
            int baseLen = 3 + (lvlNum ~/ 4) + rand.nextInt(5 + (lvlNum ~/ 10));
            if (lvlNum > 30) baseLen += rand.nextInt(10);
            
            int totalLen = baseLen; 
            
            for (int step = 0; step < totalLen; step++) {
                double turnProb = 0.3 + (lvlNum / 150); // Becomes more "wiggly" over time
                if (rand.nextDouble() < turnProb) {
                    cdIdx = (cdIdx + (rand.nextBool() ? 1 : 3)) % 4;
                }

                int nx = cx + dirs[cdIdx][0];
                int ny = cy + dirs[cdIdx][1];
                
                if (isFree(nx, ny) && !tempCells.contains('$nx,$ny')) {
                    path.add([nx, ny]);
                    tempCells.add('$nx,$ny');
                    cx = nx; cy = ny;
                } else {
                    if (lvlNum < 10) break; // Earlier levels allow shorter paths if stuck
                }
            }
            
            if (path.length < 3) continue;

            var head = path.last;
            var neck = path[path.length-2];
            int dx = head[0] - neck[0];
            int dy = head[1] - neck[1];

            if (raycastHits(head[0], head[1], dx, dy)) continue; 

            bool trapsSomething = false;
            for (var rayCells in arrowRays.values) {
               for (String cell in tempCells) {
                   if (rayCells.contains(cell)) {
                       trapsSomething = true;
                       break;
                   }
               }
               if (trapsSomething) break;
            }

            // Stronger preference for "trapping" placements in higher levels
            int trapThreshold = lvlNum > 20 ? 3000 : 1000;
            if (arrows.length > 5 && !trapsSomething && attempt < trapThreshold) {
                continue; 
            }

            arrows.add({
                'id': idGen,
                'path': path,
                'arrowhead': 'last'
            });
            allCells.addAll(tempCells);

            List<String> ray = [];
            int rx = head[0] + dx, ry = head[1] + dy;
            while(rx >= 0 && rx < gs && ry >= 0 && ry < gs) {
                ray.add('$rx,$ry');
                rx += dx; ry += dy;
            }
            arrowRays[idGen] = ray;

            for (int olderId in arrowRays.keys) {
                List<String> oldRay = arrowRays[olderId]!;
                for (int rIndex=0; rIndex < oldRay.length; rIndex++) {
                    if (tempCells.contains(oldRay[rIndex])) {
                        arrowRays[olderId] = oldRay.sublist(0, rIndex);
                        break;
                    }
                }
            }

            idGen++;
            placed = true;
            break;
        }

        if (!placed) {
            consecutiveFails++;
            if (consecutiveFails >= 5 || allCells.length >= (gs * gs) - 6) {
                print('Stage $lvlNum generated with ${arrows.length} arrows. (${allCells.length}/${gs*gs} dots used)');
                break;
            }
        } else {
            consecutiveFails = 0;
        }
    }

    newLevels.add({
        'level': lvlNum,
        'gridSize': gs,
        'difficulty': lvlNum >= 40 ? 'Insane' : lvlNum >= 25 ? 'Extreme' : lvlNum >= 15 ? 'Hard' : 'Medium',
        'arrows': arrows
    });
  }

  File('assets/levels.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(newLevels));
  print('✅ Successfully generated stages 1 to 50!');
  
  _verifyAll(newLevels);
}

void _verifyAll(List<dynamic> levels) {
  for (var lvl in levels) {
    if (lvl['level'] < 5) continue;
    int gs = lvl['gridSize'];
    final arrowsMapList = lvl['arrows'] as List<dynamic>;
    
    final arrows = arrowsMapList.map((a) {
      final ma = a as Map<String, dynamic>;
      final path = ma['path'] as List;
      final head = path.last as List;
      final neck = path[path.length - 2] as List;
      return {
        'id': ma['id'], 'path': path,
        'dir': [(head[0] as int) - (neck[0] as int), (head[1] as int) - (neck[1] as int)],
        'solved': false,
      };
    }).toList();

    int solved = 0;
    while(true) {
      bool progress = false;
      for (var a in arrows) {
        if (a['solved'] == true) continue;
        Set<String> blocked = {};
        for (var o in arrows) {
          if (o['id'] == a['id'] || o['solved'] == true) continue;
          for (var p in o['path'] as List) {
            blocked.add('${p[0]},${p[1]}');
          }
        }
        final List head = a['path'].last;
        int x = (head[0] as int) + (a['dir'][0] as int), y = (head[1] as int) + (a['dir'][1] as int);
        bool isBlocked = false;
        while (x >= 0 && x < gs && y >= 0 && y < gs) {
          if (blocked.contains('$x,$y')) { isBlocked = true; break; }
          x += a['dir'][0] as int; y += a['dir'][1] as int;
        }
        if (!isBlocked) { a['solved'] = true; solved++; progress = true; }
      }
      if (!progress) break;
    }

    if (solved == arrows.length) {
      // print('✅ Stage ${lvl['level']}: SOLVABLE (${arrows.length} arrows)');
    } else {
      print('❌ Stage ${lvl['level']}: IMPOSSIBLE! ${arrows.length - solved} stuck');
    }
  }
  print('🏁 Verification complete.');
}

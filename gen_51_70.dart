// ignore_for_file: avoid_print, unused_local_variable, curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  // Remove existing 51-70 (which had deadlocks or didn't exist)
  levels.removeWhere((l) => l['level'] >= 51 && l['level'] <= 70);

  final rand = Random();

  for (int stage = 51; stage <= 70; stage++) {
    // Increase grid size progressively, extremely large!
    int gridSize = 50 + (stage - 50) * 2; 

    Set<String> mask = _getMask(stage, gridSize);
    String shapeName = _getShapeName(stage);

    List<Map<String, dynamic>> arrows = [];
    Set<String> allCells = {};
    Map<int, List<String>> arrowRays = {};
    int idGen = 1;

    bool isAllowed(int x, int y) {
      if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) return false;
      if (!mask.contains('$x,$y')) return false;
      return !allCells.contains('$x,$y');
    }

    bool raycastHits(int hx, int hy, int dx, int dy) {
      int nx = hx + dx, ny = hy + dy;
      while (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
        if (allCells.contains('$nx,$ny')) return true;
        nx += dx; ny += dy;
      }
      return false;
    }

    int maxAttempts = 300000;
    double targetFill = 0.95;

    for (int i = 0; i < maxAttempts; i++) {
      if (allCells.length >= mask.length * targetFill) break;

      var maskList = mask.toList();
      if (maskList.isEmpty) break;
      String point = maskList[rand.nextInt(maskList.length)];
      var parts = point.split(',');
      int sx = int.parse(parts[0]);
      int sy = int.parse(parts[1]);
      
      if (!isAllowed(sx, sy)) continue;

      bool isBig = rand.nextDouble() < 0.4; // 40% chance of massive arrows
      int minL = isBig ? 10 : 3;
      int maxL = isBig ? 30 : 10;
      
      List<List<int>> path = [[sx, sy]];
      Set<String> tempCells = {'$sx,$sy'};
      int cx = sx, cy = sy;
      var dirs = [[1,0], [-1,0], [0,1], [0,-1]];
      int cdIdx = rand.nextInt(4);
      int currentTargetLen = minL + rand.nextInt(maxL - minL + 1);
      
      for (int step = 0; step < currentTargetLen; step++) {
        if (rand.nextDouble() < 0.3) {
          cdIdx = (cdIdx + (rand.nextBool() ? 1 : 3)) % 4;
        }
        int nx = cx + dirs[cdIdx][0];
        int ny = cy + dirs[cdIdx][1];
        if (isAllowed(nx, ny) && !tempCells.contains('$nx,$ny')) {
          path.add([nx, ny]);
          tempCells.add('$nx,$ny');
          cx = nx; cy = ny;
        } else {
          bool turned = false;
          for (int opt in [1, 3]) {
            int ndIdx = (cdIdx + opt) % 4;
            int nnx = cx + dirs[ndIdx][0];
            int nny = cy + dirs[ndIdx][1];
            if (isAllowed(nnx, nny) && !tempCells.contains('$nnx,$nny')) {
              cdIdx = ndIdx; cx = nnx; cy = nny;
              path.add([cx, cy]); tempCells.add('$cx,$cy');
              turned = true; break;
            }
          }
          if (!turned) break;
        }
      }
      
      if (path.length < 3) continue;
      var head = path.last;
      var neck = path[path.length-2];
      int dx = head[0] - neck[0];
      int dy = head[1] - neck[1];

      if (raycastHits(head[0], head[1], dx, dy)) continue; 

      arrows.add({
        'id': idGen,
        'path': path,
        'arrowhead': 'last',
        'colorIndex': rand.nextInt(5),
      });
      allCells.addAll(tempCells);

      List<String> ray = [];
      int rx = head[0] + dx, ry = head[1] + dy;
      while(rx >= 0 && rx < gridSize && ry >= 0 && ry < gridSize) {
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
    }

    print('Stage $stage: [$shapeName] ${arrows.length} arrows, Grid: $gridSize');

    levels.add({
      'level': stage,
      'gridSize': gridSize,
      'shapeName': shapeName,
      'isHardStage': true, // Always true for 51-70
      'arrows': arrows
    });
  }

  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected Levels 51-70 successfully!');
}

String _getShapeName(int stage) {
  const names = [
    "Epic Labyrinth", "The Great Divide", "Chaos Theory", "Infinity Matrix", "Fractal Web",
    "Abyssal Zone", "Titan's Grid", "Quantum Entanglement", "Shattered Reality", "The Void",
    "Galactic Spiral", "Nebula", "Event Horizon", "Cosmic Web", "Supernova",
    "Black Hole", "Dark Matter", "Hypercube", "Tesseract", "Singularity"
  ];
  return names[(stage - 51) % names.length];
}

Set<String> _getMask(int stage, int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  int type = (stage - 51) % 5;
  
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double dx = x - mid;
      double dy = y - mid;
      double r = sqrt(dx*dx + dy*dy);
      
      bool add = false;
      if (type == 0) {
        // Massive Dense Square
        add = dx.abs() < gs*0.45 && dy.abs() < gs*0.45;
      } else if (type == 1) {
        // Thick X Cross
        add = (dx - dy).abs() < gs*0.2 || (dx + dy).abs() < gs*0.2;
      } else if (type == 2) {
        // Dense Diamond
        add = dx.abs() + dy.abs() < gs*0.48;
      } else if (type == 3) {
        // Concentric Rings
        add = (r > gs*0.1 && r < gs*0.2) || (r > gs*0.3 && r < gs*0.45);
      } else if (type == 4) {
        // Checkerboard zones (dense clusters)
        add = ((x ~/ 10) + (y ~/ 10)) % 2 == 0 && r < gs*0.48;
      }
      
      if (add) mask.add('$x,$y');
    }
  }
  return mask;
}

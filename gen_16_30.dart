// ignore_for_file: avoid_print, unused_local_variable, curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  levels.removeWhere((l) => l['level'] >= 16 && l['level'] <= 30);

  final rand = Random();

  for (int stage = 16; stage <= 30; stage++) {
    int gridSize = 22 + (stage - 16) ~/ 2;
    if (gridSize > 30) gridSize = 30;

    Set<String> mask = _getMask(stage - 16, gridSize);
    String shapeName = _getShapeName(stage - 16);

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

    int maxAttempts = 200000;
    double targetFill = 0.90;

    for (int i = 0; i < maxAttempts; i++) {
      if (allCells.length >= mask.length * targetFill) break;

      var maskList = mask.toList();
      if (maskList.isEmpty) break;
      String point = maskList[rand.nextInt(maskList.length)];
      var parts = point.split(',');
      int sx = int.parse(parts[0]);
      int sy = int.parse(parts[1]);
      
      if (!isAllowed(sx, sy)) continue;

      bool isBig = rand.nextDouble() < 0.3;
      int minL = isBig ? 6 : 2;
      int maxL = isBig ? 15 : 6;
      
      List<List<int>> path = [[sx, sy]];
      Set<String> tempCells = {'$sx,$sy'};
      int cx = sx, cy = sy;
      var dirs = [[1,0], [-1,0], [0,1], [0,-1]];
      int cdIdx = rand.nextInt(4);
      int currentTargetLen = minL + rand.nextInt(maxL - minL + 1);
      
      for (int step = 0; step < currentTargetLen; step++) {
        if (rand.nextDouble() < 0.5) {
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
      
      if (path.length < 2) continue;
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
      'isHardStage': stage % 5 == 0,
      'arrows': arrows
    });
  }

  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected Levels 16-30 successfully!');
}

String _getShapeName(int index) {
  const names = [
    "Full Square", "Circle", "Triangle", "Hexagon", "Star",
    "Plus", "Ring", "X-Shape", "Four Boxes", "Hourglass",
    "Diamond", "Frame", "Waves", "Trapezoid", "Octagon"
  ];
  return names[index % names.length];
}

Set<String> _getMask(int index, int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double dx = x - mid;
      double dy = y - mid;
      double r = sqrt(dx*dx + dy*dy);
      
      bool add = false;
      switch (index) {
        case 0: add = true; break; // Full Square
        case 1: add = r <= gs * 0.45; break; // Circle
        case 2: add = y > gs * 0.2 && y < gs * 0.9 && dx.abs() < (y - gs*0.1); break; // Triangle
        case 3: add = dx.abs() < gs*0.4 && dy.abs() < gs*0.45 && (dx.abs() + dy.abs() < gs*0.6); break; // Hexagon
        case 4: // Star
          double angle = atan2(dy, dx);
          double rLimit = gs * 0.25 + gs * 0.2 * cos(5 * angle).abs();
          add = r < rLimit;
          break;
        case 5: add = dx.abs() < gs*0.15 || dy.abs() < gs*0.15; break; // Plus
        case 6: add = r > gs*0.2 && r < gs*0.45; break; // Ring
        case 7: add = (dx - dy).abs() < gs*0.15 || (dx + dy).abs() < gs*0.15; break; // X-Shape
        case 8: // Four Boxes
          add = (dx.abs() > gs*0.1 && dx.abs() < gs*0.4) && (dy.abs() > gs*0.1 && dy.abs() < gs*0.4);
          break;
        case 9: add = (dx.abs() < dy.abs() + 2) && dy.abs() < gs*0.4; break; // Hourglass
        case 10: add = dx.abs() + dy.abs() < gs*0.45; break; // Diamond
        case 11: add = dx.abs() > gs*0.3 || dy.abs() > gs*0.3; break; // Frame
        case 12: add = (dy - sin(x * 0.5) * gs*0.2).abs() < gs*0.2; break; // Waves
        case 13: add = y > gs*0.3 && y < gs*0.8 && dx.abs() < y*0.6; break; // Trapezoid
        case 14: add = dx.abs() < gs*0.4 && dy.abs() < gs*0.4 && dx.abs() + dy.abs() < gs*0.55; break; // Octagon
      }
      
      if (add) mask.add('$x,$y');
    }
  }
  return mask;
}

// Guaranteed solvable Maze Generator - Art Shape Edition
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final file = File('assets/levels.json');
  if (!file.existsSync()) {
    print('❌ assets/levels.json not found!');
    return;
  }
  
  final data = json.decode(file.readAsStringSync()) as List;
  final newLevels = data.where((lvl) => lvl['level'] <= 10).toList();

  for (int lvlNum = 11; lvlNum <= 50; lvlNum++) {
    bool isHardStage = (lvlNum % 5 == 0);
    int gridSize = 20 + (lvlNum - 11); // Scaling up
    if (isHardStage) gridSize += 10;

    final rand = Random(lvlNum * 555 + 11);
    
    // Choose a shape mask
    Set<String> mask = {};
    String shapeName = "";
    int shapeType = rand.nextInt(6); 

    if (shapeType == 0) {
      shapeName = "Heart";
      mask = _createHeartMask(gridSize);
    } else if (shapeType == 1) {
      shapeName = "Diamond";
      mask = _createDiamondMask(gridSize);
    } else if (shapeType == 2) {
      shapeName = "Dog-ish";
      mask = _createDogMask(gridSize);
    } else if (shapeType == 3) {
      shapeName = "Butterfly";
      mask = _createButterflyMask(gridSize);
    } else if (shapeType == 4) {
      shapeName = "Plus";
      mask = _createPlusMask(gridSize);
    } else {
      shapeName = "Ring";
      mask = _createRingMask(gridSize);
    }

    List<Map<String, dynamic>> arrows = [];
    Set<String> allCells = {};
    Map<int, List<String>> arrowRays = {};
    int idGen = 1;

    bool isAllowed(int x, int y) {
      if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) return false;
      if (!mask.contains('$x,$y')) return false; // Must be inside the shape
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

    int maxAttempts = isHardStage ? 1000000 : 500000;
    double targetFill = 0.95;

    for (int i = 0; i < maxAttempts; i++) {
      if (allCells.length >= mask.length * targetFill) break;

      // Pick a random point from the mask that is not used
      var maskList = mask.toList();
      String point = maskList[rand.nextInt(maskList.length)];
      var parts = point.split(',');
      int sx = int.parse(parts[0]);
      int sy = int.parse(parts[1]);
      
      if (!isAllowed(sx, sy)) continue;

      bool isBig = rand.nextDouble() < 0.4;
      int minL = isBig ? 8 : 3;
      int maxL = isBig ? 20 : 7;
      
      List<List<int>> path = [[sx, sy]];
      Set<String> tempCells = {'$sx,$sy'};
      int cx = sx, cy = sy;
      var dirs = [[1,0], [-1,0], [0,1], [0,-1]];
      int cdIdx = rand.nextInt(4);
      int currentTargetLen = minL + rand.nextInt(maxL - minL + 1);
      
      for (int step = 0; step < currentTargetLen; step++) {
        if (rand.nextDouble() < 0.6) {
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

    print('Stage $lvlNum: [$shapeName] ${arrows.length} arrows, Fill: ${(allCells.length/mask.length*100).toStringAsFixed(1)}%');

    newLevels.add({
      'level': lvlNum,
      'gridSize': gridSize,
      'isHardStage': isHardStage,
      'arrows': arrows,
      'shapeName': shapeName
    });
  }

  File('assets/levels.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(newLevels));
  print('\n✅ Generated Shape-Art Levels!');
}

Set<String> _createHeartMask(int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double nx = (x - mid) / (gs / 2.5);
      double ny = (y - mid) / (gs / 2.5);
      // Heart formula: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
      double val = pow(nx*nx + ny*ny - 1, 3) - nx*nx * pow(ny, 3);
      if (val <= 0) mask.add('$x,$y');
    }
  }
  return mask;
}

Set<String> _createDiamondMask(int gs) {
  Set<String> mask = {};
  int mid = gs ~/ 2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      if ((x - mid).abs() + (y - mid).abs() <= gs ~/ 2.2) mask.add('$x,$y');
    }
  }
  return mask;
}

Set<String> _createDogMask(int gs) {
  Set<String> mask = {};
  // Very simplified silhoutte
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      bool head = (x > gs * 0.6 && x < gs * 0.9 && y > gs * 0.1 && y < gs * 0.4);
      bool body = (x > gs * 0.2 && x < gs * 0.7 && y > gs * 0.3 && y < gs * 0.8);
      bool tail = (x > gs * 0.1 && x < gs * 0.2 && y > gs * 0.2 && y < gs * 0.4);
      bool leg1 = (x > gs * 0.2 && x < gs * 0.3 && y > gs * 0.8 && y < gs * 0.95);
      bool leg2 = (x > gs * 0.6 && x < gs * 0.7 && y > gs * 0.8 && y < gs * 0.95);
      if (head || body || tail || leg1 || leg2) mask.add('$x,$y');
    }
  }
  return mask;
}

Set<String> _createButterflyMask(int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double dx = (x - mid).abs();
      double dy = (y - mid).abs();
      // Simple wings
      if (dx < gs * 0.4 && dy < gs * 0.4) {
        if (dx > dy * 0.3 || dx < gs * 0.05) mask.add('$x,$y');
      }
    }
  }
  return mask;
}

Set<String> _createPlusMask(int gs) {
  Set<String> mask = {};
  int mid = gs ~/ 2;
  int thick = gs ~/ 4;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      if ((x - mid).abs() < thick || (y - mid).abs() < thick) mask.add('$x,$y');
    }
  }
  return mask;
}

Set<String> _createRingMask(int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  double rOuter = gs * 0.45;
  double rInner = gs * 0.2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double d = sqrt(pow(x - mid, 2) + pow(y - mid, 2));
      if (d < rOuter && d > rInner) mask.add('$x,$y');
    }
  }
  return mask;
}

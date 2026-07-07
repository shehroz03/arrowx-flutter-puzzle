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
    int gridSize;
    if (stage >= 21) {
      gridSize = 42 + (stage - 21) * 2; // 42 to 60 for massive 3x/double arrow density
    } else {
      gridSize = 22 + (stage - 16) ~/ 2;
      if (gridSize > 30) gridSize = 30;
    }

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

    int maxAttempts = stage >= 21 ? 400000 : 200000;
    double targetFill = stage >= 21 ? 0.95 : 0.90;

    for (int i = 0; i < maxAttempts; i++) {
      if (allCells.length >= mask.length * targetFill) break;

      var maskList = mask.toList();
      if (maskList.isEmpty) break;
      String point = maskList[rand.nextInt(maskList.length)];
      var parts = point.split(',');
      int sx = int.parse(parts[0]);
      int sy = int.parse(parts[1]);
      
      if (!isAllowed(sx, sy)) continue;

      int minL, maxL;
      if (stage >= 21) {
        // "bary bary arrow add kro medium arrow do"
        bool isBig = rand.nextDouble() < 0.5;
        minL = isBig ? 8 : 4; // Medium: 4-7, Big: 8-15
        maxL = isBig ? 15 : 7;
      } else {
        bool isBig = rand.nextDouble() < 0.3;
        minL = isBig ? 6 : 2;
        maxL = isBig ? 15 : 6;
      }
      
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
      
      if (path.length < (stage >= 21 ? 4 : 2)) continue; // Ensure minimum length 4 for stages 21-30
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

String _getShapeName(int stage) {
  switch (stage) {
    case 16: return "Full Square";
    case 17: return "Circle";
    case 18: return "Triangle";
    case 19: return "Hexagon";
    case 20: return "Star";
    case 21: return "Architectural Fortress";
    case 22: return "Symmetrical Mandala";
    case 23: return "Sacred Geometry Star";
    case 24: return "Imperial Colosseum";
    case 25: return "Labyrinthine Pyramid";
    case 26: return "Cathedral Rosette";
    case 27: return "Quantum Citadel";
    case 28: return "Celestial Compass";
    case 29: return "Helix Pantheon";
    case 30: return "Master Architect Megastructure";
    default: return "Geometric Form";
  }
}

Set<String> _getMask(int stage, int gs) {
  Set<String> mask = {};
  double mid = gs / 2;
  
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      double dx = x - mid;
      double dy = y - mid;
      double r = sqrt(dx*dx + dy*dy);
      
      bool add = false;
      switch (stage) {
        case 16: add = true; break; // Full Square
        case 17: add = r <= gs * 0.45; break; // Circle
        case 18: add = y > gs * 0.2 && y < gs * 0.9 && dx.abs() < (y - gs*0.1); break; // Triangle
        case 19: add = dx.abs() < gs*0.4 && dy.abs() < gs*0.45 && (dx.abs() + dy.abs() < gs*0.6); break; // Hexagon
        case 20: // Star
          double angle = atan2(dy, dx);
          double rLimit = gs * 0.25 + gs * 0.2 * cos(5 * angle).abs();
          add = r < rLimit;
          break;
        case 21: // Architectural Fortress: Outer perimeter wall, inner towers, central courtyard
          bool outerWall = (dx.abs() > gs*0.38 && dx.abs() < gs*0.45) || (dy.abs() > gs*0.38 && dy.abs() < gs*0.45);
          bool towers = (dx.abs() > gs*0.2 && dx.abs() < gs*0.3) && (dy.abs() > gs*0.2 && dy.abs() < gs*0.3);
          bool courtyard = r < gs*0.15;
          bool bridges = dx.abs() < 2 || dy.abs() < 2;
          add = outerWall || towers || courtyard || bridges;
          break;
        case 22: // Symmetrical Mandala: Concentric ornamental rings and radiating spokes
          bool ring1 = r > gs*0.35 && r < gs*0.42;
          bool ring2 = r > gs*0.20 && r < gs*0.27;
          bool ring3 = r < gs*0.12;
          bool spokes = (dx.abs() < 2) || (dy.abs() < 2) || ((dx - dy).abs() < 2) || ((dx + dy).abs() < 2);
          add = ring1 || ring2 || ring3 || spokes;
          break;
        case 23: // Sacred Geometry Star: 8-pointed architectural star grid
          double angle23 = atan2(dy, dx);
          double rStar = gs * 0.25 + gs * 0.18 * cos(8 * angle23).abs();
          bool core23 = r < rStar;
          bool outerFrame = dx.abs() + dy.abs() > gs*0.35 && dx.abs() + dy.abs() < gs*0.45;
          add = core23 || outerFrame;
          break;
        case 24: // Imperial Colosseum: Concentric elliptical tiers with 4 radial entrance corridors
          double ellipseR = sqrt(dx*dx*1.2 + dy*dy*0.8);
          bool tier1 = ellipseR > gs*0.35 && ellipseR < gs*0.45;
          bool tier2 = ellipseR > gs*0.22 && ellipseR < gs*0.30;
          bool tier3 = ellipseR < gs*0.15;
          bool corridors = dx.abs() < 3 || dy.abs() < 3;
          add = tier1 || tier2 || tier3 || corridors;
          break;
        case 25: // Labyrinthine Pyramid: Stepped pyramid terraces forming a dense grand maze
          double maxDist = max(dx.abs(), dy.abs());
          bool terrace1 = maxDist > gs*0.38 && maxDist < gs*0.45;
          bool terrace2 = maxDist > gs*0.28 && maxDist < gs*0.34;
          bool terrace3 = maxDist > gs*0.18 && maxDist < gs*0.24;
          bool terrace4 = maxDist < gs*0.12;
          bool stairs = dx.abs() < 2 || dy.abs() < 2;
          add = terrace1 || terrace2 || terrace3 || terrace4 || stairs;
          break;
        case 26: // Cathedral Rosette: Circular stained-glass window pattern with interlocking petals
          double angle26 = atan2(dy, dx);
          double petals = sin(6 * angle26).abs() * gs * 0.38;
          bool rosette = r < petals && r > gs * 0.1;
          bool center = r < gs * 0.15;
          bool rim = r > gs*0.38 && r < gs*0.44;
          add = rosette || center || rim;
          break;
        case 27: // Quantum Citadel: Four interconnected corner bastions linked by diagonal bridges
          bool bastions = (dx.abs() > gs*0.22 && dx.abs() < gs*0.42) && (dy.abs() > gs*0.22 && dy.abs() < gs*0.42);
          bool diagBridges = (dx - dy).abs() < 3 || (dx + dy).abs() < 3;
          bool centralKeep = r < gs * 0.18;
          add = bastions || diagBridges || centralKeep;
          break;
        case 28: // Celestial Compass: Outer navigation ring with prominent North/South/East/West axes
          bool compassRing = r > gs*0.36 && r < gs*0.44;
          bool mainAxes = (dx.abs() < 4 && dy.abs() < gs*0.45) || (dy.abs() < 4 && dx.abs() < gs*0.45);
          bool subAxes = ((dx - dy).abs() < 2 && r < gs*0.35) || ((dx + dy).abs() < 2 && r < gs*0.35);
          bool hub = r < gs*0.15;
          add = compassRing || mainAxes || subAxes || hub;
          break;
        case 29: // Helix Pantheon: Intertwined spiral corridors radiating from a grand central rotunda
          double angle29 = atan2(dy, dx);
          double spiral1 = (angle29 * gs * 0.05 + r) % (gs * 0.2);
          bool helix = spiral1 < gs * 0.08 && r < gs * 0.42;
          bool rotunda = r < gs * 0.2;
          bool crossWalks = dx.abs() < 2 || dy.abs() < 2;
          add = helix || rotunda || crossWalks;
          break;
        case 30: // Master Architect Megastructure: Massive, ultra-dense symmetrical fortress
          double mDist = max(dx.abs(), dy.abs());
          bool megaOuter = mDist > gs*0.40 && mDist < gs*0.48;
          bool megaInner = mDist > gs*0.25 && mDist < gs*0.35;
          bool megaCore = r < gs*0.20;
          bool grandDiagonals = (dx - dy).abs() < 3 || (dx + dy).abs() < 3;
          bool grandCardinals = dx.abs() < 3 || dy.abs() < 3;
          add = megaOuter || megaInner || megaCore || grandDiagonals || grandCardinals;
          break;
        default:
          add = r <= gs * 0.45;
      }
      
      if (add) mask.add('$x,$y');
    }
  }
  return mask;
}

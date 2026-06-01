import 'dart:convert';
import 'dart:io';
import 'dart:math';

int nextId = 1;

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  levels.removeWhere((l) => l['level'] >= 16 && l['level'] <= 25);

  final rand = Random();

  for (int stage = 16; stage <= 25; stage++) {
    // 120 to 160 arrows
    int targetArrows = 120 + rand.nextInt(41);
    
    // Determine grid size based on target arrows
    int gs = sqrt(targetArrows * 2.5).ceil();
    if (gs < 8) gs = 8;
    if (gs % 2 != 0) gs++; 
    if (gs > 32) gs = 32;

    double center = gs / 2.0;
    
    List<Map<String, dynamic>> arrows = [];
    Set<String> occupied = {};

    bool canPlace(int x, int y, int dx, int dy) {
      if (x < 0 || x >= gs || y < 0 || y >= gs) return false;
      if (x+dx < 0 || x+dx >= gs || y+dy < 0 || y+dy >= gs) return false;
      if (occupied.contains('$x,$y')) return false;
      if (occupied.contains('${x+dx},${y+dy}')) return false;
      return true;
    }

    List<int> getDir(int x, int y) {
      double dx = x - center + 0.5;
      double dy = y - center + 0.5;
      if (dx.abs() > dy.abs()) {
        return dx > 0 ? [1, 0] : [-1, 0];
      } else {
        return dy > 0 ? [0, 1] : [0, -1];
      }
    }

    int shapeType = stage % 6;
    String shapeName = "";
    
    List<Map<String, dynamic>> candidates = [];
    
    for (int y = 0; y < gs; y++) {
      for (int x = 0; x < gs; x++) {
        if ((x + y) % 2 != 0) continue; // Checkerboard to ensure they interlock well
        
        List<int> dir = getDir(x, y);
        if (!canPlace(x, y, dir[0], dir[1])) continue;

        double dx = x - center + 0.5;
        double dy = y - center + 0.5;
        double score = 0;

        if (shapeType == 0) {
          shapeName = "Circle";
          score = (sqrt(dx*dx + dy*dy) - (gs/3)).abs();
        } else if (shapeType == 1) {
          shapeName = "Diamond";
          score = (dx.abs() + dy.abs() - (gs/2)).abs();
        } else if (shapeType == 2) {
          shapeName = "Cross";
          score = min(dx.abs(), dy.abs());
        } else if (shapeType == 3) {
          shapeName = "X Shape";
          score = (dx.abs() - dy.abs()).abs();
        } else if (shapeType == 4) {
          shapeName = "Spiral";
          double angle = atan2(dy, dx);
          double radius = sqrt(dx*dx + dy*dy);
          score = (radius - (angle * gs / (2*pi)) % (gs/3)).abs();
        } else if (shapeType == 5) {
          shapeName = "Face Art";
          double eyeL = sqrt(pow(dx + gs/5, 2) + pow(dy + gs/6, 2));
          double eyeR = sqrt(pow(dx - gs/5, 2) + pow(dy + gs/6, 2));
          double mouth = sqrt(pow(dx, 2) + pow(dy - gs/4, 2));
          double jaw = (sqrt(dx*dx + dy*dy) - (gs/2.2)).abs();
          
          if (dy > 0 && mouth < gs/5 && dx.abs() < gs/4) score = mouth;
          else if (dy < 0 && eyeL < gs/8) score = eyeL;
          else if (dy < 0 && eyeR < gs/8) score = eyeR;
          else score = jaw;
        }

        candidates.add({
          'x': x, 'y': y, 'dir': dir, 'score': score
        });
      }
    }

    candidates.sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));

    int placed = 0;
    for (var c in candidates) {
      if (placed >= targetArrows) break;
      int x = c['x'];
      int y = c['y'];
      List<int> dir = c['dir'];
      
      if (canPlace(x, y, dir[0], dir[1])) {
        occupied.add('$x,$y');
        occupied.add('${x+dir[0]},${y+dir[1]}');
        
        int colorIdx = (sqrt(pow(x-center,2) + pow(y-center,2)).toInt() % 5);
        
        arrows.add({
          'id': nextId++,
          'path': [[x, y], [x+dir[0], y+dir[1]]],
          'dir': dir,
          'colorIndex': colorIdx,
          'sx': x,
          'sy': y,
          'len': 2
        });
        placed++;
      }
    }

    levels.add({
      'level': stage,
      'gridSize': gs,
      'shapeName': shapeName,
      'isHardStage': true,
      'arrows': arrows
    });
  }

  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected 10 Dense Levels (16-25) successfully!');
}

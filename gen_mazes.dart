import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  List<Map<String, dynamic>> levels = [];
  int nextId = 1;
  final rand = Random();

  for (int stage = 1; stage <= 30; stage++) {
    int targetArrows = 60 + stage * 3;
    
    int gs = sqrt(targetArrows * 2.5).ceil();
    if (gs < 10) gs = 10;
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

    List<Map<String, dynamic>> candidates = [];
    for (int y = 0; y < gs; y++) {
      for (int x = 0; x < gs; x++) {
        if ((x + y) % 2 != 0) continue;
        
        List<int> dir = getDir(x, y);
        if (!canPlace(x, y, dir[0], dir[1])) continue;

        double dx = x - center + 0.5;
        double dy = y - center + 0.5;
        double angle = atan2(dy, dx);
        double radius = sqrt(dx*dx + dy*dy);
        double score = (radius - (angle * gs / (2*pi)) % (gs/3)).abs(); // Spiral shape
        candidates.add({'x': x, 'y': y, 'dir': dir, 'score': score});
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
        arrows.add({
          'id': nextId++,
          'path': [[x, y], [x+dir[0], y+dir[1]]],
          'dir': dir,
          'colorIndex': rand.nextInt(5),
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
      'shapeName': 'Maze $stage',
      'isHardStage': stage % 5 == 0,
      'arrows': arrows
    });
  }

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/mazes.json').writeAsStringSync(encoder.convert(levels));
  print('Generated 30 Maze Levels!');
}

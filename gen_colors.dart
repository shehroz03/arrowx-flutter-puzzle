// ignore_for_file: avoid_print, unused_local_variable, curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  List<Map<String, dynamic>> levels = [];
  int nextId = 1;
  final rand = Random();

  for (int stage = 1; stage <= 25; stage++) {
    int targetArrows = 40 + stage * 2;
    
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

    List<Map<String, dynamic>> candidates = [];
    for (int y = 0; y < gs; y++) {
      for (int x = 0; x < gs; x++) {
        if ((x + y) % 2 != 0) continue;
        
        List<int> dir = rand.nextBool() ? (rand.nextBool() ? [1, 0] : [-1, 0]) : (rand.nextBool() ? [0, 1] : [0, -1]);
        if (!canPlace(x, y, dir[0], dir[1])) continue;

        candidates.add({'x': x, 'y': y, 'dir': dir, 'score': rand.nextDouble()});
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
      'shapeName': 'Color Match $stage',
      'isHardStage': stage % 5 == 0,
      'arrows': arrows
    });
  }

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/color_match.json').writeAsStringSync(encoder.convert(levels));
  print('Generated 25 Color Match Levels!');
}

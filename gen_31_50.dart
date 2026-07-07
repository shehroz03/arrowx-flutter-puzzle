// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  final rand = Random();

  for (int stage = 31; stage <= 50; stage++) {
    int targetArrows = 150 + (stage - 31) * 5;
    
    // Find the level in the list
    int index = levels.indexWhere((l) => l['level'] == stage);
    if (index != -1) {
      var levelData = levels[index];
      List<dynamic> arrows = List<dynamic>.from(levelData['arrows']);
      int gs = levelData['gridSize'];

      if (arrows.length > targetArrows) {
        print('Stage $stage: Currently ${arrows.length} arrows. Removing ${arrows.length - targetArrows} extra arrows to reach $targetArrows.');
        arrows = arrows.sublist(0, targetArrows);
      } else if (arrows.length < targetArrows) {
        print('Stage $stage: Currently ${arrows.length} arrows. Adding ${targetArrows - arrows.length} arrows to reach $targetArrows.');
        
        // Collect existing cells
        Set<String> occupied = {};
        int maxId = 0;
        for (var a in arrows) {
          int id = a['id'];
          if (id > maxId) maxId = id;
          if (a.containsKey('path')) {
            for (var pt in a['path']) {
              occupied.add('${pt[0]},${pt[1]}');
            }
          }
        }

        int added = 0;
        int needed = targetArrows - arrows.length;
        for (int y = 0; y < gs && added < needed; y++) {
          for (int x = 0; x < gs && added < needed; x++) {
            if (x + 1 < gs && !occupied.contains('$x,$y') && !occupied.contains('${x+1},$y')) {
              maxId++;
              arrows.add({
                'id': maxId,
                'path': [[x, y], [x+1, y]],
                'arrowhead': 'last',
                'colorIndex': rand.nextInt(5),
              });
              occupied.add('$x,$y');
              occupied.add('${x+1},$y');
              added++;
            }
          }
        }
      } else {
        print('Stage $stage: Already has exactly $targetArrows arrows.');
      }

      levelData['arrows'] = arrows;
      levels[index] = levelData;
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Successfully adjusted arrow counts for Stages 31-50!');
}

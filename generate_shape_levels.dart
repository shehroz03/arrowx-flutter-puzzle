import 'dart:convert';
import 'dart:io';

int nextId = 1;

void main() {
  final levels = <Map<String, dynamic>>[];
  int lvlNum = 1;

  // Helper to create an arrow with a path
  Map<String, dynamic> pathArrow(List<List<int>> path, int colorIndex) {
    return {
      'id': nextId++,
      'path': path,
      'arrowhead': 'last',
      'colorIndex': colorIndex,
      'solved': false, // For verification
    };
  }

  // Helper to create a straight arrow
  Map<String, dynamic> straightArrow(int sx, int sy, String dir, int len, int colorIndex) {
    int dx = 0, dy = 0;
    switch (dir) {
      case 'right': dx = 1; break;
      case 'left': dx = -1; break;
      case 'down': dy = 1; break;
      case 'up': dy = -1; break;
    }
    List<List<int>> path = List.generate(len, (i) => [sx + dx * i, sy + dy * i]);
    return pathArrow(path, colorIndex);
  }

  Map<String, dynamic> createLevel(int gridSize, String shapeName, List<Map<String, dynamic>> arrows) {
    return {
      'level': lvlNum++,
      'gridSize': gridSize,
      'shapeName': shapeName,
      'isHardStage': lvlNum % 5 == 1, // Since lvlNum was already incremented, lvlNum-1 % 5 == 0 is hard, so lvlNum % 5 == 1
      'arrows': arrows,
    };
  }

  // 1. Plus/Cross (Grid 8)
  nextId = 1;
  levels.add(createLevel(8, 'Plus', [
    straightArrow(2, 4, 'left', 2, 1),
    straightArrow(6, 4, 'right', 2, 1),
    straightArrow(4, 2, 'up', 2, 1),
    straightArrow(4, 6, 'down', 2, 1),
  ]));

  // 2. Arrow (Grid 8)
  nextId = 1;
  levels.add(createLevel(8, 'Arrow', [
    straightArrow(6, 4, 'right', 3, 0), // tip
    straightArrow(4, 3, 'up', 2, 0), // top wing
    straightArrow(4, 5, 'down', 2, 0), // bottom wing
    straightArrow(1, 4, 'left', 3, 0), // tail
  ]));

  // 3. Diamond (Grid 10)
  nextId = 1;
  levels.add(createLevel(10, 'Diamond', [
    straightArrow(2, 5, 'left', 2, 1),
    straightArrow(8, 5, 'right', 2, 1),
    straightArrow(5, 2, 'up', 2, 0),
    straightArrow(5, 8, 'down', 2, 0),
  ]));

  // 4. Heart (Grid 10)
  nextId = 1;
  levels.add(createLevel(10, 'Heart', [
    pathArrow([[3, 3], [2, 3], [2, 4], [3, 5], [5, 7]], 3), // left side
    pathArrow([[7, 3], [8, 3], [8, 4], [7, 5], [5, 7]], 3), // right side
    straightArrow(3, 2, 'up', 2, 3), // left top
    straightArrow(7, 2, 'up', 2, 3), // right top
    straightArrow(4, 8, 'down', 2, 3), // bottom left
    straightArrow(6, 8, 'down', 2, 3), // bottom right
  ]));

  // 5. Star (Grid 10)
  nextId = 1;
  levels.add(createLevel(10, 'Star', [
    straightArrow(5, 1, 'up', 2, 0), // top
    straightArrow(2, 4, 'left', 2, 1), // left
    straightArrow(8, 4, 'right', 2, 1), // right
    straightArrow(3, 8, 'down', 2, 0), // bottom left
    straightArrow(7, 8, 'down', 2, 0), // bottom right
  ]));

  // Generate generic levels for the rest up to 50 for now, just to have a working set
  // In a real scenario, we would design 45 more unique shapes.
  // For the sake of this script, we'll repeat and scale these shapes to fill 50 levels.
  
  for (int i = 6; i <= 50; i++) {
    nextId = 1;
    int size = 10 + (i ~/ 5) * 2;
    if (size > 24) size = 24;
    
    int c = size ~/ 2;
    
    if (i % 5 == 0) {
      // Square outline
      levels.add(createLevel(size, 'Square', [
        straightArrow(c-2, c-2, 'up', 2, i%5),
        straightArrow(c+2, c-2, 'right', 2, i%5),
        straightArrow(c+2, c+2, 'down', 2, i%5),
        straightArrow(c-2, c+2, 'left', 2, i%5),
      ]));
    } else if (i % 5 == 1) {
      // Triangle
      levels.add(createLevel(size, 'Triangle', [
        straightArrow(c, c-3, 'up', 2, i%5),
        straightArrow(c-3, c+2, 'left', 2, i%5),
        straightArrow(c+3, c+2, 'right', 2, i%5),
      ]));
    } else if (i % 5 == 2) {
      // Cross
      levels.add(createLevel(size, 'Cross', [
        straightArrow(c-3, c, 'left', 3, i%5),
        straightArrow(c+3, c, 'right', 3, i%5),
        straightArrow(c, c-3, 'up', 3, i%5),
        straightArrow(c, c+3, 'down', 3, i%5),
      ]));
    } else if (i % 5 == 3) {
      // X Shape
      levels.add(createLevel(size, 'X Shape', [
        straightArrow(c-3, c-3, 'up', 2, i%5),
        straightArrow(c+3, c-3, 'right', 2, i%5),
        straightArrow(c-3, c+3, 'left', 2, i%5),
        straightArrow(c+3, c+3, 'down', 2, i%5),
      ]));
    } else {
      // Double Cross
      levels.add(createLevel(size, 'Double Cross', [
        straightArrow(c-4, c, 'left', 2, i%5),
        straightArrow(c+4, c, 'right', 2, i%5),
        straightArrow(c, c-4, 'up', 2, i%5),
        straightArrow(c, c+4, 'down', 2, i%5),
        straightArrow(c-2, c, 'left', 2, (i+1)%5),
        straightArrow(c+2, c, 'right', 2, (i+1)%5),
        straightArrow(c, c-2, 'up', 2, (i+1)%5),
        straightArrow(c, c+2, 'down', 2, (i+1)%5),
      ]));
    }
  }

  // Write to file
  // Clean up 'solved' keys before writing
  final exportLevels = levels.map((lvl) {
    final arrows = (lvl['arrows'] as List).map((a) {
      final arr = Map<String, dynamic>.from(a);
      arr.remove('solved');
      return arr;
    }).toList();
    return {
      ...lvl,
      'arrows': arrows,
    };
  }).toList();

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/levels.json').writeAsStringSync(encoder.convert(exportLevels));
  print('Generated \${exportLevels.length} levels!');
}

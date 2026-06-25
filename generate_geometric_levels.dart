// ignore_for_file: avoid_print, unused_local_variable, curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:io';

int nextId = 1;

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  // Remove existing 11-15 (animals and skull)
  levels.removeWhere((l) => l['level'] >= 11 && l['level'] <= 15);

  levels.add(_createLevelFromAscii(11, 20, "Vertical Zig-Zag", zigzagAscii));
  levels.add(_createLevelFromAscii(12, 20, "Spiral", spiralAscii));
  levels.add(_createLevelFromAscii(13, 20, "Diamond Grid", diamondAscii));
  levels.add(_createLevelFromAscii(14, 20, "Horizontal Zig-Zag", horizZigzagAscii));
  levels.add(_createLevelFromAscii(15, 20, "Square Spiral", sqSpiralAscii));

  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected 5 Geometric Levels (11-15) successfully!');
}

Map<String, dynamic> _createLevelFromAscii(int levelNum, int gridSize, String shapeName, List<String> asciiLines) {
  nextId = 1;
  List<Map<String, dynamic>> arrows = [];
  Set<String> processedChars = {};

  for (int y = 0; y < asciiLines.length; y++) {
    for (int x = 0; x < asciiLines[y].length; x++) {
      String c = asciiLines[y][x];
      if (c != ' ' && !processedChars.contains(c)) {
        processedChars.add(c);
        
        List<List<int>> path = [];
        int cx = x, cy = y;
        path.add([cx, cy]);
        
        bool moved;
        do {
          moved = false;
          for (var dir in [[1,0], [-1,0], [0,1], [0,-1], [1,1], [-1,-1], [1,-1], [-1,1]]) {
            int nx = cx + dir[0];
            int ny = cy + dir[1];
            if (ny >= 0 && ny < asciiLines.length && nx >= 0 && nx < asciiLines[ny].length) {
              if (asciiLines[ny][nx] == c) {
                bool inPath = path.any((p) => p[0] == nx && p[1] == ny);
                if (!inPath) {
                  cx = nx;
                  cy = ny;
                  path.add([cx, cy]);
                  moved = true;
                  break;
                }
              }
            }
          }
        } while(moved);

        List<int> headDir = [1, 0];
        if (path.length > 1) {
           headDir = [
             path.last[0] - path[path.length-2][0],
             path.last[1] - path[path.length-2][1]
           ];
           // Ensure headDir is strictly orthogonal (since rendering might only support orthogonal arrows)
           if (headDir[0] != 0 && headDir[1] != 0) {
              headDir = [headDir[0], 0]; // Force orthogonal direction for rendering
           }
        }
        
        if (path.length == 1) {
           path.add([path[0][0] + 1, path[0][1]]);
        }

        arrows.add({
          'id': nextId++,
          'path': path,
          'dir': headDir,
          'colorIndex': nextId % 5,
          'sx': path.first[0],
          'sy': path.first[1],
          'len': path.length
        });
      }
    }
  }

  return {
    'level': levelNum,
    'gridSize': gridSize,
    'shapeName': shapeName,
    'isHardStage': false, 
    'arrows': arrows,
  };
}

List<String> zigzagAscii = [
  "A   B   C   D   E   ",
  " A B C D E F G H I  ",
  "  A   C   E   G   I ",
  " A B C D E F G H I  ",
  "A   B   C   D   E   ",
  " A B C D E F G H I  ",
  "  A   C   E   G   I ",
  " A B C D E F G H I  ",
  "A   B   C   D   E   ",
  " A B C D E F G H I  ",
  "  A   C   E   G   I ",
  " A B C D E F G H I  ",
  "A   B   C   D   E   ",
  " A B C D E F G H I  ",
  "  A   C   E   G   I ",
  " A B C D E F G H I  ",
  "A   B   C   D   E   ",
  " A B C D E F G H I  ",
  "  A   C   E   G   I ",
  " A B C D E F G H I  ",
];

List<String> horizZigzagAscii = [
  "A A A A A A A A A A ",
  " A B A B A B A B A  ",
  "  B   B   B   B   B ",
  " C B C B C B C B C  ",
  "C C C C C C C C C C ",
  " C D C D C D C D C  ",
  "  D   D   D   D   D ",
  " E D E D E D E D E  ",
  "E E E E E E E E E E ",
  " E F E F E F E F E  ",
  "  F   F   F   F   F ",
  " G F G F G F G F G  ",
  "G G G G G G G G G G ",
  " G H G H G H G H G  ",
  "  H   H   H   H   H ",
  " I H I H I H I H I  ",
  "I I I I I I I I I I ",
  " I J I J I J I J I  ",
  "  J   J   J   J   J ",
  "   J   J   J   J    ",
];

List<String> spiralAscii = [
  "       AAAAAA       ",
  "    AAA      AAA    ",
  "   A            A   ",
  "  A   BBBBBBBB   A  ",
  " A   B        B   A ",
  " A  B  CCCCCC  B  A ",
  " A  B C      C B  A ",
  "A   B C DDDD C B   A",
  "A   B C D  D C B   A",
  "A   B C D ED C B   A",
  "A   B C D  D C B   A",
  "A   B C DDDD C B   A",
  " A  B C      C B  A ",
  " A  B  CCCCCC  B  A ",
  " A   B        B   A ",
  "  A   BBBBBBBB   A  ",
  "   A            A   ",
  "    AAA      AAA    ",
  "       AAAAAA       ",
  "                    "
];

List<String> sqSpiralAscii = [
  "AAAAAAAAAAAAAAAAAAA ",
  "A                 A ",
  "A BBBBBBBBBBBBBBB A ",
  "A B             B A ",
  "A B CCCCCCCCCCC B A ",
  "A B C         C B A ",
  "A B C DDDDDDD C B A ",
  "A B C D     D C B A ",
  "A B C D EEE D C B A ",
  "A B C D E F D C B A ",
  "A B C D EEE D C B A ",
  "A B C D     D C B A ",
  "A B C DDDDDDD C B A ",
  "A B C         C B A ",
  "A B CCCCCCCCCCC B A ",
  "A B             B A ",
  "A BBBBBBBBBBBBBBB A ",
  "A                 A ",
  "AAAAAAAAAAAAAAAAAAA ",
  "                    "
];

List<String> diamondAscii = [
  "         A          ",
  "        A A         ",
  "       A B A        ",
  "      A B B A       ",
  "     A B C B A      ",
  "    A B C C B A     ",
  "   A B C D C B A    ",
  "  A B C D D C B A   ",
  " A B C D E D C B A  ",
  "A B C D E E D C B A ",
  " A B C D E D C B A  ",
  "  A B C D D C B A   ",
  "   A B C D C B A    ",
  "    A B C C B A     ",
  "     A B C B A      ",
  "      A B B A       ",
  "       A B A        ",
  "        A A         ",
  "         A          ",
  "                    "
];

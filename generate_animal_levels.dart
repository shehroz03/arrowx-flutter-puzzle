import 'dart:convert';
import 'dart:io';

int nextId = 1;

void main() {
  // We'll read existing levels, and append our new 4 levels at the end (or replace 11, 12, 13, 14)
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  levels.removeWhere((l) => l['level'] >= 11 && l['level'] <= 14); // Replace 11-14 if they exist

  levels.add(_createLevelFromAscii(11, 20, "Crab", crabAscii));
  levels.add(_createLevelFromAscii(12, 20, "Cat", catAscii));
  levels.add(_createLevelFromAscii(13, 20, "Jellyfish", jellyAscii));
  levels.add(_createLevelFromAscii(14, 20, "Dog", dogAscii));

  // Sort by level just in case
  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected animal levels 11-14 successfully!');
}

Map<String, dynamic> _createLevelFromAscii(int levelNum, int gridSize, String shapeName, List<String> asciiLines) {
  nextId = 1;
  List<Map<String, dynamic>> arrows = [];
  Set<String> processedChars = {};

  // Find all unique characters (each char represents a path)
  for (int y = 0; y < asciiLines.length; y++) {
    for (int x = 0; x < asciiLines[y].length; x++) {
      String c = asciiLines[y][x];
      if (c != ' ' && !processedChars.contains(c)) {
        processedChars.add(c);
        
        // Trace this character's path
        List<List<int>> path = [];
        int cx = x, cy = y;
        path.add([cx, cy]);
        
        bool moved;
        do {
          moved = false;
          // Look for an adjacent same character that isn't already in the path
          for (var dir in [[1,0], [-1,0], [0,1], [0,-1]]) {
            int nx = cx + dir[0];
            int ny = cy + dir[1];
            if (ny >= 0 && ny < asciiLines.length && nx >= 0 && nx < asciiLines[ny].length) {
              if (asciiLines[ny][nx] == c) {
                // Check if already in path
                bool inPath = path.any((p) => p[0] == nx && p[1] == ny);
                if (!inPath) {
                  cx = nx;
                  cy = ny;
                  path.add([cx, cy]);
                  moved = true;
                  break; // Move to this adjacent cell and continue
                }
              }
            }
          }
        } while(moved);

        // Calculate arrowhead direction (outward from the last point)
        List<int> headDir = [1, 0]; // default
        if (path.length > 1) {
           headDir = [
             path.last[0] - path[path.length-2][0],
             path.last[1] - path[path.length-2][1]
           ];
        } else {
           // single cell, just point right
           headDir = [1, 0];
        }
        
        // Ensure path length is at least 2 for arrow mechanics, if it's 1, add an artificial step
        if (path.length == 1) {
           path.add([path[0][0] + 1, path[0][1]]);
        }

        arrows.add({
          'id': nextId++,
          'path': path,
          'dir': headDir,
          'colorIndex': nextId % 5, // colorful
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
    'isHardStage': levelNum % 5 == 1,
    'arrows': arrows,
  };
}

// 20x20 Grids where each letter forms a continuous path. 
// A single letter repeated adjacent to itself creates one arrow path.

List<String> crabAscii = [
  "                    ",
  " AA              BB ",
  " A                B ",
  " ACC          DDB B ",
  "   C          D   B ",
  "   C  EE  FF  D     ",
  "  GCE E    F FDH    ",
  "  G C E    F F H    ",
  "  G C E    F F H    ",
  "  G C II  JJ F H    ",
  "  G C I    J F H    ",
  "  G  KI    J L H    ",
  "  G  K M  N  L H    ",
  "  G  K M  N  L H    ",
  "   O K M  N  L P    ",
  "   O K M  N  L P    ",
  "   O K M  N  L P    ",
  "   O K      QL P    ",
  "   OO        QQ     ",
  "                    "
];

List<String> catAscii = [
  "                    ",
  " AA              BB ",
  "  A              B  ",
  "  A   CCCCCCC    B  ",
  "  A   C     C    B  ",
  "  A   C  D  C    B  ",
  "  A   C D D C    B  ",
  "  A   C  D  C    B  ",
  "  A E C     C F  B  ",
  "  A E C     C F  B  ",
  "  A E C     C F  B  ",
  "  A E C  G  C F  B  ",
  "  A E C G G C F  B  ",
  "  A E C  G  C F  B  ",
  "  A E C     C F  B  ",
  "  A E CCCCCCC F  B  ",
  "  A E         F  B  ",
  "  AAEEEEEEEEFFFB B  ",
  "               BBB  ",
  "                    "
];

List<String> jellyAscii = [
  "                    ",
  "       AAAAAA       ",
  "      A      A      ",
  "     A        A     ",
  "    A   BBBB   A    ",
  "   A   B    B   A   ",
  "  A    B    B    A  ",
  "  ACCC B    B DDDA  ",
  "     C B    B D     ",
  "     C B    B D     ",
  "     C B    B D     ",
  "     C B    B D     ",
  "     C B    B D     ",
  "     C B    B D     ",
  "     C E    F D     ",
  "     C E    F D     ",
  "     C E    F D     ",
  "       E    F       ",
  "       E    F       ",
  "                    "
];

List<String> dogAscii = [
  "                    ",
  "    AAAAAA          ",
  "   A      A         ",
  "  A  B  B  A        ",
  "  A        A        ",
  "   A  CC  A         ",
  "    A    A          ",
  "     A  A           ",
  "    DD  DD          ",
  "   D      D         ",
  "   D  EE  D         ",
  "   D E  E D         ",
  "   D E  E D         ",
  "   D E  E D         ",
  "   D E  E D         ",
  "   D  EE  D         ",
  "  DD      DD        ",
  "  D        D        ",
  "  DDDDDDDDDD        ",
  "                    "
];

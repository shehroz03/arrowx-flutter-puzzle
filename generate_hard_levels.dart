import 'dart:convert';
import 'dart:io';

int nextId = 1;

void main() {
  File file = File('assets/levels.json');
  List<dynamic> existingRaw = jsonDecode(file.readAsStringSync());
  List<Map<String, dynamic>> levels = List<Map<String, dynamic>>.from(existingRaw);

  levels.removeWhere((l) => l['level'] >= 15 && l['level'] <= 24);

  levels.add(_createLevelFromAscii(15, 20, "Skull", skullAscii));
  levels.add(_createLevelFromAscii(16, 20, "Spider", spiderAscii));
  levels.add(_createLevelFromAscii(17, 20, "Crown", crownAscii));
  levels.add(_createLevelFromAscii(18, 20, "Sword", swordAscii));
  levels.add(_createLevelFromAscii(19, 20, "Shield", shieldAscii));
  levels.add(_createLevelFromAscii(20, 20, "Bat", batAscii));
  levels.add(_createLevelFromAscii(21, 20, "Octopus", octopusAscii));
  levels.add(_createLevelFromAscii(22, 20, "Scorpion", scorpionAscii));
  levels.add(_createLevelFromAscii(23, 20, "Owl", owlAscii));
  levels.add(_createLevelFromAscii(24, 20, "Dragon", dragonAscii));

  levels.sort((a, b) => a['level'].compareTo(b['level']));

  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(levels));
  print('Injected 10 Hard Levels (15-24) successfully!');
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
          for (var dir in [[1,0], [-1,0], [0,1], [0,-1]]) {
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
    'isHardStage': true, // Makes it visibly harder
    'arrows': arrows,
  };
}

List<String> skullAscii = [
  "                    ",
  "      AAAAAAAA      ",
  "     A        A     ",
  "    A  B    C  A    ",
  "   A   B    C   A   ",
  "   A   B    C   A   ",
  "   A   B    C   A   ",
  "   A            A   ",
  "    A   D  D   A    ",
  "     A  D  D  A     ",
  "      A      A      ",
  "      AE EE EA      ",
  "      AE EE EA      ",
  "      AE EE EA      ",
  "       AAAAAA       ",
  "                    ",
  "                    ",
  "                    ",
  "                    ",
  "                    "
];

List<String> spiderAscii = [
  " A                B ",
  " A   CC      DD   B ",
  "  A C  E    F  D B  ",
  "  A C E G  H F D B  ",
  "   A CE G  H FD B   ",
  "   A C  G  H  D B   ",
  "    A   G  H   B    ",
  "    I   G  H   J    ",
  "   I    G  H    J   ",
  "   I    G  H    J   ",
  "  I     G  H     J  ",
  "  I KKKKK  LLLLL J  ",
  " I K            L J ",
  " I K  MMMMMMMM  L J ",
  " I K  M      M  L J ",
  " I K  MMMMMMMM  L J ",
  " I K            L J ",
  "  I KKKKK  LLLLL J  ",
  "                    ",
  "                    "
];

List<String> crownAscii = [
  "                    ",
  " A       B       C  ",
  " A       B       C  ",
  " AA     BBB     CC  ",
  "  A     B B     C   ",
  "  A    B   B    C   ",
  "  A    B   B    C   ",
  "  AA  B     B  CC   ",
  "   A  B     B  C    ",
  "   A  B     B  C    ",
  "   A B       B C    ",
  "   A B       B C    ",
  "   A B       B C    ",
  "   AA         CC    ",
  "   DDDDDDDDDDDDD    ",
  "   D           D    ",
  "   EEEEEEEEEEEEE    ",
  "                    ",
  "                    ",
  "                    "
];

List<String> swordAscii = [
  "          A         ",
  "          A         ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "         A A        ",
  "     BBBBBBBBBBB    ",
  "     B         B    ",
  "     BBBBBBBBBBB    ",
  "          C         ",
  "          C         ",
  "          C         ",
  "         DDD        ",
  "                    "
];

List<String> shieldAscii = [
  "                    ",
  " AAAAAAAAAAAAAAAAAA ",
  " A                A ",
  " A B CCCCCCCCCC B A ",
  " A B C        C B A ",
  " A B C        C B A ",
  " A B C        C B A ",
  " A B C        C B A ",
  "  AB C        C BA  ",
  "  AB C        C BA  ",
  "   AB C      C BA   ",
  "   AB C      C BA   ",
  "    AB C    C BA    ",
  "    AB C    C BA    ",
  "     AB C  C BA     ",
  "      AB CC BA      ",
  "       AB  BA       ",
  "        ABBA        ",
  "         AA         ",
  "                    "
];

List<String> batAscii = [
  "A                  B",
  "AA                BB",
  "A A              B B",
  "A  A     CC     B  B",
  "A   A   C  C   B   B",
  " A   A C    C B   B ",
  " A   AC      CB   B ",
  "  A  C  DDDD  C  B  ",
  "  A  C  D  D  C  B  ",
  "   A C  DDDD  C B   ",
  "   A C        C B   ",
  "    ACCCCCCCCCCB    ",
  "     A        B     ",
  "     A        B     ",
  "      A      B      ",
  "      A      B      ",
  "       A    B       ",
  "       A    B       ",
  "        A  B        ",
  "                    "
];

List<String> octopusAscii = [
  "                    ",
  "      AAAAAA        ",
  "     A      A       ",
  "    A B    C A      ",
  "   A  B    C  A     ",
  "   A          A     ",
  "   A   DDDD   A     ",
  "    A  D  D  A      ",
  "    A  DDDD  A      ",
  "     AAAAAAAA       ",
  "   E F G  H I J     ",
  "  E  F G  H I  J    ",
  "  E  F G  H I  J    ",
  "  E  F G  H I  J    ",
  " E   F G  H I   J   ",
  " E  F  G  H  I  J   ",
  " E  F  G  H  I  J   ",
  "E   F  G  H  I   J  ",
  "                    ",
  "                    "
];

List<String> scorpionAscii = [
  "  A            B    ",
  "  A            B    ",
  "  AA          BB    ",
  "   A          B     ",
  "   AA        BB     ",
  "    A        B      ",
  "    AA      BB      ",
  "      A    B        ",
  "      ACCCCB        ",
  "       C  C         ",
  "    DD C  C EE      ",
  "   D   C  C   E     ",
  "       CCCC         ",
  "    FF C  C GG      ",
  "   F   C  C   G     ",
  "       CCCC         ",
  "       C  C         ",
  "       C  C         ",
  "        CC          ",
  "                    "
];

List<String> owlAscii = [
  "                    ",
  "   A          B     ",
  "  A A        B B    ",
  " A   A      B   B   ",
  " A C A      B D B   ",
  " A C A      B D B   ",
  "  A A   EE   B B    ",
  "   A   E  E   B     ",
  "   A   EEEE   B     ",
  "  A            B    ",
  "  A  F      G  B    ",
  "  A  F      G  B    ",
  "  A  F      G  B    ",
  "   A F      G B     ",
  "   A F      G B     ",
  "    AFFFFFFFFB      ",
  "     A      B       ",
  "     A      B       ",
  "      A    B        ",
  "                    "
];

List<String> dragonAscii = [
  "          A         ",
  "         A A        ",
  "        A   A       ",
  "       A     A      ",
  "      A       A     ",
  "     A         A    ",
  "     A B     C A    ",
  "    A  B     C  A   ",
  "    A           A   ",
  "    A    DDD    A   ",
  "    A   D   D   A   ",
  "     A  D   D  A    ",
  "     A  DDDDD  A    ",
  "      A       A     ",
  "      A       A     ",
  "      A EE EE A     ",
  "       A E E A      ",
  "       A E E A      ",
  "        A   A       ",
  "         AAA        "
];

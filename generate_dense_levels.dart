import 'dart:convert';
import 'dart:io';
import 'dart:math';

int nextId = 1;

void main() {
  final levels = <Map<String, dynamic>>[];

  for (int stage = 1; stage <= 50; stage++) {
    int targetArrows = stage <= 10 ? 5 + stage * 5 : 55 + (stage - 10) * 10;
    
    // Determine grid size based on target arrows (need at least targetArrows * 2 cells for checkerboard)
    int gs = sqrt(targetArrows * 2.5).ceil();
    if (gs < 8) gs = 8;
    if (gs % 2 != 0) gs++; // Keep grid size even for symmetry
    if (gs > 32) gs = 32;

    double center = gs / 2.0;

    // We will place arrows on a checkerboard to avoid overlap.
    // Starting cell must have (x+y) % 2 == 0.
    // The arrow will be length 2.
    
    List<Map<String, dynamic>> arrows = [];
    Set<String> occupied = {};

    bool canPlace(int x, int y, int dx, int dy) {
      if (x < 0 || x >= gs || y < 0 || y >= gs) return false;
      if (x+dx < 0 || x+dx >= gs || y+dy < 0 || y+dy >= gs) return false;
      if (occupied.contains('\$x,\$y')) return false;
      if (occupied.contains('\${x+dx},\${y+dy}')) return false;
      return true;
    }

    // Quadrant direction
    List<int> getDir(int x, int y) {
      double dx = x - center + 0.5;
      double dy = y - center + 0.5;
      if (dx.abs() > dy.abs()) {
        return dx > 0 ? [1, 0] : [-1, 0]; // Right / Left
      } else {
        return dy > 0 ? [0, 1] : [0, -1]; // Down / Up
      }
    }

    // We want to form a shape. We assign a "score" to each cell. Lower score = better fit for the shape.
    // Shapes: 0=Circle, 1=Diamond, 2=Cross, 3=X, 4=Spiral, 5=Face Profile
    int shapeType = stage % 6;
    String shapeName = "";
    
    List<Map<String, dynamic>> candidates = [];
    
    for (int y = 0; y < gs; y++) {
      for (int x = 0; x < gs; x++) {
        if ((x + y) % 2 != 0) continue; // Checkerboard
        
        List<int> dir = getDir(x, y);
        if (!canPlace(x, y, dir[0], dir[1])) continue;

        double dx = x - center + 0.5;
        double dy = y - center + 0.5;
        double score = 0;

        if (shapeType == 0) {
          shapeName = "Circle";
          score = (sqrt(dx*dx + dy*dy) - (gs/3)).abs(); // Concentric ring preference
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
          // A rudimentary face outline: eyes, nose, mouth, jaw
          double eyeL = sqrt(pow(dx + gs/5, 2) + pow(dy + gs/6, 2));
          double eyeR = sqrt(pow(dx - gs/5, 2) + pow(dy + gs/6, 2));
          double mouth = sqrt(pow(dx, 2) + pow(dy - gs/4, 2));
          double jaw = (sqrt(dx*dx + dy*dy) - (gs/2.2)).abs();
          
          if (dy > 0 && mouth < gs/5 && dx.abs() < gs/4) score = mouth; // Mouth area
          else if (dy < 0 && eyeL < gs/8) score = eyeL;
          else if (dy < 0 && eyeR < gs/8) score = eyeR;
          else score = jaw; // Outline
        }

        candidates.add({
          'x': x, 'y': y, 'dir': dir, 'score': score
        });
      }
    }

    // Sort by score (best fit for shape first)
    candidates.sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));

    // Place arrows
    int placed = 0;
    for (var c in candidates) {
      if (placed >= targetArrows) break;
      int x = c['x'];
      int y = c['y'];
      List<int> dir = c['dir'];
      
      if (canPlace(x, y, dir[0], dir[1])) {
        occupied.add('\$x,\$y');
        occupied.add('\${x+dir[0]},\${y+dir[1]}');
        
        int colorIdx = (sqrt(pow(x-center,2) + pow(y-center,2)).toInt() % 5);
        
        arrows.add({
          'id': nextId++,
          'path': [[x, y], [x+dir[0], y+dir[1]]],
          'arrowhead': 'last',
          'colorIndex': colorIdx
        });
        placed++;
      }
    }

    levels.add({
      'level': stage,
      'gridSize': gs,
      'shapeName': shapeName,
      'isHardStage': stage % 5 == 0,
      'arrows': arrows
    });
  }

  final encoder = JsonEncoder.withIndent('  ');
  File('assets/levels.json').writeAsStringSync(encoder.convert({'levels': levels})); // Wait, format!
  
  // Game state expects an ARRAY of levels, not an object with 'levels' key. Let me check the previous script.
  File('assets/levels.json').writeAsStringSync(encoder.convert(levels));
  
  print('Generated \${levels.length} dense levels!');
}

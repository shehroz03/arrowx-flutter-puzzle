// ignore_for_file: avoid_print
// Professional redesign for levels 5-20 and 31-100.
// Keeps 1-4 (tutorial) and 21-30 (already redesigned) untouched.
// 26 parametric shape masks, clean straight/L arrows, center-out placement,
// every level verified solvable before being written.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Shape id per level 5-20 (simple geometry first).
const early = [
  'circle', 'square', 'triangle', 'diamond', 'plus', 'ring', 'hexagon',
  'hourglass', 'moon', 'sun', 'house', 'tree', 'cup', 'kite', 'shield', 'bell'
];
// Rotation for 31-100: 40-shape pool (14 premium new + 26 base), consecutive
// levels never share a shape and a shape only repeats 40 levels later.
const lateOrder = [
  'snowflake', 'heart', 'plane', 'star', 'umbrella', 'fish', 'target', 'bulb',
  'anchor', 'tree', 'infinity', 'butterfly', 'mushroom', 'house', 'note',
  'rocket', 'cat', 'moon', 'key', 'flower', 'boat', 'shield', 'leaf', 'cup',
  'zap', 'gem', 'clover', 'sun', 'ring', 'crown', 'hexagon', 'trophy',
  'hourglass', 'bell', 'kite', 'plus', 'circle', 'triangle', 'square', 'diamond'
];
// Levels 101-130: 30 brand-new shapes, each used exactly once and never
// seen in levels 1-100.
const xlOrder = [
  'smiley', 'robot', 'cloud', 'sword', 'duck', 'gift', 'octagon', 'ghost',
  'pizza', 'balloon', 'owl', 'magnet', 'icecream', 'pinwheel', 'whale',
  'candy', 'cactus', 'camera', 'rabbit', 'flame', 'turtle', 'lock',
  'cupcake', 'arrow', 'paw', 'guitar', 'drop', 'skull', 'pentagon', 'bone'
];

// Levels 51-100: all 40 base shapes once each + 10 fresh shapes, so the
// whole 51-200 range never repeats a shape.
const midOrder = [
  'strawberry', 'star', 'boat', 'pumpkin', 'heart', 'snowflake', 'pear',
  'fish', 'umbrella', 'watermelon', 'bulb', 'tree', 'candle', 'butterfly',
  'target', 'rainbow', 'rocket', 'moon', 'tent', 'flower', 'anchor',
  'igloo', 'crown', 'infinity', 'sock', 'gem', 'cat', 'mitten', 'trophy',
  'mushroom', 'circle', 'note', 'kite', 'square', 'key', 'shield',
  'triangle', 'leaf', 'bell', 'diamond', 'zap', 'cup', 'plus', 'clover',
  'hexagon', 'sun', 'ring', 'house', 'hourglass', 'plane'
];

// Levels 131-200: 70 unique spectacular shapes, each used exactly once.
const xl2Order = [
  'elephant', 'yinyang', 'palm', 'gear', 'penguin', 'saturn', 'wineglass',
  'dove', 'spiral', 'castle', 'frog', 'comet', 'puzzle', 'shark', 'peace',
  'teapot', 'snail', 'ufo', 'medal', 'octopus', 'mountain', 'glasses',
  'bat', 'atom', 'tophat', 'crab', 'volcano', 'scissors', 'seahorse',
  'hexagram', 'book', 'bee', 'wave', 'envelope', 'jellyfish', 'tornado',
  'diamondring', 'swan', 'hotair', 'bowtie', 'fox', 'windmill', 'tshirt',
  'mouse', 'lighthouse', 'boot', 'chick', 'cherry', 'lantern', 'serpent',
  'acorn', 'dumbbell', 'dino', 'shell', 'flag', 'ladybird', 'star8',
  'kettlebell', 'spider', 'keyhole', 'question', 'dog', 'rings3',
  'exclaim', 'bear', 'wrench', 'percent', 'crosshair', 'snowman', 'rook'
];
const names = {
  'circle': 'Circle', 'square': 'Square', 'triangle': 'Triangle',
  'diamond': 'Diamond', 'plus': 'Cross', 'ring': 'Ring', 'hexagon': 'Hexagon',
  'hourglass': 'Hourglass', 'moon': 'Moon', 'sun': 'Sun', 'house': 'House',
  'tree': 'Pine Tree', 'cup': 'Cup', 'kite': 'Kite', 'shield': 'Shield',
  'bell': 'Bell', 'heart': 'Heart', 'star': 'Star', 'fish': 'Fish',
  'bulb': 'Light Bulb', 'butterfly': 'Butterfly', 'rocket': 'Rocket',
  'flower': 'Flower', 'gem': 'Gem', 'crown': 'Crown', 'trophy': 'Trophy',
  'snowflake': 'Snowflake', 'plane': 'Aeroplane', 'umbrella': 'Umbrella',
  'target': 'Target', 'anchor': 'Anchor', 'infinity': 'Infinity',
  'mushroom': 'Mushroom', 'note': 'Music Note', 'cat': 'Cat', 'key': 'Key',
  'boat': 'Sailboat', 'leaf': 'Leaf', 'zap': 'Lightning', 'clover': 'Clover',
  'smiley': 'Smiley', 'robot': 'Robot', 'cloud': 'Cloud', 'sword': 'Sword',
  'duck': 'Duck', 'gift': 'Gift', 'octagon': 'Octagon', 'ghost': 'Ghost',
  'pizza': 'Pizza', 'balloon': 'Balloon', 'owl': 'Owl', 'magnet': 'Magnet',
  'icecream': 'Ice Cream', 'pinwheel': 'Pinwheel', 'whale': 'Whale',
  'candy': 'Candy', 'cactus': 'Cactus', 'camera': 'Camera',
  'rabbit': 'Rabbit', 'flame': 'Flame', 'turtle': 'Turtle', 'lock': 'Lock',
  'cupcake': 'Cupcake', 'arrow': 'Arrow', 'paw': 'Paw Print',
  'guitar': 'Guitar', 'drop': 'Raindrop', 'skull': 'Skull',
  'pentagon': 'Pentagon', 'bone': 'Bone',
  'elephant': 'Elephant', 'yinyang': 'Yin Yang', 'palm': 'Palm Tree',
  'gear': 'Gear', 'penguin': 'Penguin', 'saturn': 'Saturn',
  'wineglass': 'Goblet', 'dove': 'Dove', 'spiral': 'Spiral',
  'castle': 'Castle', 'frog': 'Frog', 'comet': 'Comet', 'puzzle': 'Puzzle',
  'shark': 'Shark', 'peace': 'Peace', 'teapot': 'Teapot', 'snail': 'Snail',
  'ufo': 'UFO', 'medal': 'Medal', 'octopus': 'Octopus',
  'mountain': 'Mountain', 'glasses': 'Glasses', 'bat': 'Bat', 'atom': 'Atom',
  'tophat': 'Top Hat', 'crab': 'Crab', 'volcano': 'Volcano',
  'scissors': 'Scissors', 'seahorse': 'Seahorse', 'hexagram': 'Hexagram',
  'book': 'Open Book', 'bee': 'Bee', 'wave': 'Ocean Wave',
  'envelope': 'Envelope', 'jellyfish': 'Jellyfish', 'tornado': 'Tornado',
  'diamondring': 'Diamond Ring', 'swan': 'Swan', 'hotair': 'Hot Air Balloon',
  'bowtie': 'Bow Tie', 'fox': 'Fox', 'windmill': 'Windmill',
  'tshirt': 'T-Shirt', 'mouse': 'Mouse', 'lighthouse': 'Lighthouse',
  'boot': 'Boot', 'chick': 'Chick', 'cherry': 'Cherries',
  'lantern': 'Lantern', 'serpent': 'Serpent', 'acorn': 'Acorn',
  'dumbbell': 'Dumbbell', 'dino': 'Dinosaur', 'shell': 'Seashell',
  'flag': 'Flag', 'ladybird': 'Ladybird', 'star8': 'Starburst',
  'kettlebell': 'Kettlebell', 'spider': 'Spider', 'keyhole': 'Keyhole',
  'question': 'Question Mark', 'dog': 'Dog', 'rings3': 'Trinity Rings',
  'exclaim': 'Exclamation', 'bear': 'Bear', 'wrench': 'Wrench',
  'percent': 'Percent', 'crosshair': 'Crosshair', 'snowman': 'Snowman',
  'rook': 'Chess Rook',
  'strawberry': 'Strawberry', 'pear': 'Pear', 'watermelon': 'Watermelon',
  'pumpkin': 'Pumpkin', 'candle': 'Candle', 'rainbow': 'Rainbow',
  'tent': 'Tent', 'igloo': 'Igloo', 'sock': 'Sock', 'mitten': 'Mitten'
};

// Levels 21-30 keep their existing shapes and grids.
const midShapes = [
  'heart', 'bulb', 'star', 'butterfly', 'rocket',
  'flower', 'fish', 'crown', 'gem', 'trophy'
];
const midGrids = [30, 30, 32, 32, 32, 32, 32, 32, 32, 34];

// Long winding "snake" arrows for confusion; more and longer on later levels.
int snakeCountFor(int stage) {
  if (stage <= 10) return 0;
  if (stage <= 20) return 2;
  if (stage <= 35) return 3;
  if (stage <= 50) return 4;
  if (stage <= 70) return 5;
  if (stage <= 90) return 6;
  if (stage <= 100) return 7;
  if (stage <= 130) return 10; // the XL era
  // Mega era (131-200): snakes climb 20 -> 60
  return 20 + ((stage - 131) * 40 / 69).round();
}

void main() {
  final file = File('assets/levels.json');
  final levels = List<Map<String, dynamic>>.from(jsonDecode(file.readAsStringSync()));
  levels.removeWhere((l) {
    final n = l['level'] as int;
    return n >= 11 && n <= 200;
  });

  final targets = <int>[];
  for (int i = 11; i <= 200; i++) {
    targets.add(i);
  }

  for (final stage in targets) {
    String shape;
    int gs;
    List<int> straightLen, legLen;
    if (stage <= 20) {
      shape = early[stage - 5];
      gs = 22 + ((stage - 5) * 4 ~/ 15); // 22..26
      if (stage <= 12) {
        straightLen = [4, 9];
        legLen = [3, 6];
      } else {
        straightLen = [3, 8];
        legLen = [2, 5];
      }
    } else if (stage <= 30) {
      shape = midShapes[stage - 21];
      gs = midGrids[stage - 21];
      straightLen = [3, 8];
      legLen = [2, 5];
    } else if (stage <= 50) {
      final i = stage - 31;
      shape = lateOrder[i % lateOrder.length];
      gs = 28 + (i * 14 / 69).round(); // unchanged early-mid band
      straightLen = [3, 8];
      legLen = [2, 5];
    } else if (stage <= 100) {
      // Recreated band: unique shapes, dense short arrows, 100+ arrow floor.
      final i = stage - 51;
      shape = midOrder[i];
      gs = 34 + (i * 8 / 49).round(); // 34..42
      straightLen = [2, 6];
      legLen = [2, 4];
    } else if (stage <= 130) {
      // XL era: every level a brand-new shape, ~2x the arrows of level 100.
      // Shorter arrows -> far more of them -> the "massive level" feel.
      final i = stage - 101;
      shape = xlOrder[i];
      gs = 44 + (i * 8 / 29).round(); // 44..52
      straightLen = [2, 6];
      legLen = [2, 4];
    } else {
      // Mega era (131-200): 70 one-off spectacular shapes, snake swarms.
      final i = stage - 131;
      shape = xl2Order[i];
      gs = 54 + (i * 14 / 69).round(); // 54..68
      straightLen = [2, 6];
      legLen = [2, 4];
    }

    Map<String, dynamic>? built;
    final wantSnakes = snakeCountFor(stage);
    final isMega = stage > 130;
    // Levels past 50 must carry at least 100 arrows; thin shapes get a
    // bigger grid until they do.
    final minArrows = stage > 50 ? 100 : 0;
    Map<String, dynamic>? fallback;
    for (int bump = 0; bump <= 48 && built == null; bump += 6) {
      Map<String, dynamic>? cand0;
      // Deep rescue: on thin shapes a bigger grid just fits MORE snakes,
      // which starves the small-arrow count — so cap snakes there.
      final scStart = bump >= 24 ? min(wantSnakes, 8) : wantSnakes;
      outer:
      for (int sc = scStart; sc >= 0; sc -= (isMega ? 5 : 1)) {
        for (int attempt = 0; attempt < 8; attempt++) {
          // In rescue bumps (thin shapes chasing the 100-arrow floor) the
          // fill bar is relaxed a little so the bigger grid can pass.
          final cand = buildLevel(stage, shape, gs + bump, straightLen, legLen,
              snakeCount: sc,
              snakeDiv: isMega ? 30 : 120,
              minFill: isMega ? 0.52 : (bump > 0 ? 0.72 : null),
              seed: stage * 7919 + attempt + (wantSnakes - sc) * 131 + bump * 17);
          if (cand != null) {
            cand0 = cand;
            break outer;
          }
        }
      }
      if (cand0 == null) continue;
      if ((cand0['arrows'] as List).length >= minArrows) {
        built = cand0;
      } else if (fallback == null ||
          (cand0['arrows'] as List).length > (fallback['arrows'] as List).length) {
        fallback = cand0;
      }
    }
    built ??= fallback;
    if (built == null) {
      print('!! Stage $stage [$shape] FAILED all attempts');
      exit(1);
    }
    levels.add(built);
    print('Stage $stage [${names[shape]}] grid $gs: '
        '${(built['arrows'] as List).length} arrows, fill ${built['_fill']}%');
    built.remove('_fill');
  }

  levels.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(levels));

  // Preview HTML for every path-format level.
  final previewDir = Directory('design_previews');
  if (!previewDir.existsSync()) previewDir.createSync();
  final htmlParts = StringBuffer();
  for (final l in levels) {
    final arrows = l['arrows'] as List;
    if (arrows.isEmpty || !(arrows.first as Map).containsKey('path')) continue;
    final svg = renderSvg(l['gridSize'] as int, arrows.cast<Map<String, dynamic>>());
    htmlParts.write('<div class="card"><h2>Level ${l['level']} — '
        '${l['shapeName'] ?? ''} <span>${arrows.length} arrows</span></h2>$svg</div>');
  }
  File('design_previews/all_levels.html').writeAsStringSync('''
<!DOCTYPE html><html><head><meta charset="utf-8"><title>All Levels Redesign</title>
<style>body{background:#F5ECDC;font-family:Georgia,serif;color:#5A4632;margin:24px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(380px,1fr));gap:20px}
.card{background:#FBF5E9;border-radius:16px;padding:14px;box-shadow:0 4px 14px rgba(90,70,50,.15)}
.card h2{margin:0 0 8px;font-size:18px}.card h2 span{font-size:12px;color:#A08B6F;font-weight:normal}
svg{width:100%;height:auto;display:block}</style></head>
<body><h1>Arrow Game — Full Redesign Preview</h1><div class="grid">$htmlParts</div></body></html>''');
  print('Done. Preview: design_previews/all_levels.html');
}

Map<String, dynamic>? buildLevel(int stage, String shape, int gs,
    List<int> straightLen, List<int> legLen,
    {int snakeCount = 0, int snakeDiv = 120, double? minFill,
    required int seed}) {
  final rand = Random(seed);
  final mask = buildMask(shape, gs);
  if (mask.length < 40) return null;
  final maskList = mask.toList();
  final occupied = <String>{};
  final arrows = <Map<String, dynamic>>[];
  int idGen = 1;

  bool free(int x, int y) =>
      x >= 0 && x < gs && y >= 0 && y < gs &&
      mask.contains('$x,$y') && !occupied.contains('$x,$y');

  bool rayClear(int hx, int hy, int dx, int dy) {
    int nx = hx + dx, ny = hy + dy;
    while (nx >= 0 && nx < gs && ny >= 0 && ny < gs) {
      if (occupied.contains('$nx,$ny')) return false;
      nx += dx;
      ny += dy;
    }
    return true;
  }

  bool commit(List<List<int>> path) {
    if (path.length < 2) return false;
    var h = path.last, n = path[path.length - 2];
    if (!rayClear(h[0], h[1], h[0] - n[0], h[1] - n[1])) {
      h = path.first;
      n = path[1];
      if (!rayClear(h[0], h[1], h[0] - n[0], h[1] - n[1])) return false;
      path = path.reversed.toList();
    }
    arrows.add({
      'id': idGen++,
      'path': path,
      'arrowhead': 'last',
      'colorIndex': rand.nextInt(5),
    });
    for (final p in path) {
      occupied.add('${p[0]},${p[1]}');
    }
    return true;
  }

  List<List<int>> outwardDirs(int x, int y) {
    final vx = x + 0.5 - gs / 2, vy = y + 0.5 - gs / 2;
    final dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    dirs.shuffle(rand);
    dirs.sort((a, b) =>
        (b[0] * vx + b[1] * vy).compareTo(a[0] * vx + a[1] * vy));
    return dirs;
  }

  List<List<int>>? walk(int sx, int sy, List<List<int>> legs) {
    if (!free(sx, sy)) return null;
    final path = [[sx, sy]];
    final seen = {'$sx,$sy'};
    int cx = sx, cy = sy;
    for (final leg in legs) {
      for (int s = 0; s < leg[2]; s++) {
        final nx = cx + leg[0], ny = cy + leg[1];
        if (!free(nx, ny) || seen.contains('$nx,$ny')) return path;
        cx = nx;
        cy = ny;
        path.add([cx, cy]);
        seen.add('$cx,$cy');
      }
    }
    return path;
  }

  double rOf(String c) {
    final p = c.split(',');
    final dx = int.parse(p[0]) + 0.5 - gs / 2;
    final dy = int.parse(p[1]) + 0.5 - gs / 2;
    return dx * dx + dy * dy;
  }

  final ordered = maskList.toList()
    ..shuffle(rand)
    ..sort((a, b) => rOf(a).compareTo(rOf(b)));

  // Phase 0: long winding snake arrows (the "confusion" arrows).
  // Placed first on the empty board so they weave freely through the shape;
  // they end up being the last arrows the player can remove.
  List<List<int>>? snakeWalk(int sx, int sy, int targetLen) {
    if (!free(sx, sy)) return null;
    final path = [
      [sx, sy]
    ];
    final seen = {'$sx,$sy'};
    final dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    int d = rand.nextInt(4);
    int cx = sx, cy = sy;
    for (int step = 0; step < targetLen; step++) {
      if (rand.nextDouble() < 0.32) {
        d = (d + (rand.nextBool() ? 1 : 3)) % 4;
      }
      bool moved = false;
      for (final opt in [0, 1, 3]) {
        final nd = (d + opt) % 4;
        final nx = cx + dirs[nd][0], ny = cy + dirs[nd][1];
        if (free(nx, ny) && !seen.contains('$nx,$ny')) {
          d = nd;
          cx = nx;
          cy = ny;
          path.add([cx, cy]);
          seen.add('$cx,$cy');
          moved = true;
          break;
        }
      }
      if (!moved) break;
    }
    return path;
  }

  // Small masks cannot host many long snakes without leaving holes.
  final effSnakes = min(snakeCount, mask.length ~/ snakeDiv);
  final swarm = snakeCount >= 15;
  final minSnakeLen = swarm ? 10 : 12;

  int placeSnakes(int want) {
    int placed = 0;
    final tryBudget = max(6000, want * 900);
    for (int tries = 0; tries < tryBudget && placed < want; tries++) {
      final cell = maskList[rand.nextInt(maskList.length)].split(',');
      final targetLen = swarm
          ? 12 + rand.nextInt(17) // 12-28 cells
          : ((gs * 0.8).round() + rand.nextInt(gs)).clamp(14, 40);
      final path = snakeWalk(int.parse(cell[0]), int.parse(cell[1]), targetLen);
      if (path == null || path.length < minSnakeLen) continue;
      // If the full snake has no clear exit ray, retry progressively
      // shorter cuts of it.
      for (int cut = 0; path.length - cut >= minSnakeLen; cut += 3) {
        if (commit(path.sublist(0, path.length - cut))) {
          placed++;
          break;
        }
      }
    }
    return placed;
  }

  void fillPasses(int passes, double prob) {
    for (int pass = 0; pass < passes; pass++) {
      for (final cell in ordered) {
        if (prob < 1.0 && rand.nextDouble() > prob) continue;
        final pt = cell.split(',');
        final sx = int.parse(pt[0]), sy = int.parse(pt[1]);
        if (!free(sx, sy)) continue;
        for (final d1 in outwardDirs(sx, sy)) {
          List<List<int>> legs;
          if (rand.nextDouble() < 0.60) {
            legs = [
              [d1[0], d1[1],
               straightLen[0] + rand.nextInt(straightLen[1] - straightLen[0] + 1)]
            ];
          } else {
            final turn = rand.nextBool() ? 1 : -1;
            final d2 = [-d1[1] * turn, d1[0] * turn];
            legs = [
              [d1[0], d1[1], legLen[0] + rand.nextInt(legLen[1] - legLen[0] + 1)],
              [d2[0], d2[1], legLen[0] + rand.nextInt(legLen[1] - legLen[0] + 1)],
            ];
          }
          final path = walk(sx, sy, legs);
          if (path != null && path.length >= 3 && commit(path)) break;
        }
      }
    }
  }

  // Snakes go first so they solve last. Dense swarms cap the reachable fill
  // (~55-70%): every extra snake blocks exit rays for later small arrows,
  // which is exactly the intended confusion on mega levels.
  placeSnakes(effSnakes);
  fillPasses(6, 1.0);
  for (final len in [3, 2]) {
    for (final cell in ordered) {
      final pt = cell.split(',');
      final sx = int.parse(pt[0]), sy = int.parse(pt[1]);
      if (!free(sx, sy)) continue;
      for (final d in outwardDirs(sx, sy)) {
        final path = walk(sx, sy, [[d[0], d[1], len - 1]]);
        if (path != null && path.length == len && commit(path)) break;
      }
    }
  }

  final fill = occupied.length / mask.length;
  // Snake weaving leaves small pockets; allow slightly lower fill there.
  if (fill < (minFill ?? (snakeCount > 0 ? 0.80 : 0.85))) return null;
  if (!isSolvable(arrows, gs)) return null;

  return {
    'level': stage,
    'gridSize': gs,
    'shapeName': names[shape],
    'isHardStage': stage % 5 == 0,
    'arrows': arrows,
    '_fill': (fill * 100).toStringAsFixed(1),
  };
}

bool isSolvable(List<Map<String, dynamic>> arrows, int gs) {
  final remaining = <int, List<List<int>>>{};
  final occ = <String>{};
  for (final a in arrows) {
    final path = (a['path'] as List).cast<List<int>>();
    remaining[a['id'] as int] = path;
    for (final p in path) {
      occ.add('${p[0]},${p[1]}');
    }
  }
  bool progress = true;
  while (progress && remaining.isNotEmpty) {
    progress = false;
    for (final id in remaining.keys.toList()) {
      final path = remaining[id]!;
      final h = path.last, n = path[path.length - 2];
      final dx = h[0] - n[0], dy = h[1] - n[1];
      int x = h[0] + dx, y = h[1] + dy;
      bool clear = true;
      while (x >= 0 && x < gs && y >= 0 && y < gs) {
        if (occ.contains('$x,$y') && !path.any((p) => p[0] == x && p[1] == y)) {
          clear = false;
          break;
        }
        x += dx;
        y += dy;
      }
      if (clear) {
        for (final p in path) {
          occ.remove('${p[0]},${p[1]}');
        }
        remaining.remove(id);
        progress = true;
      }
    }
  }
  return remaining.isEmpty;
}

String renderSvg(int gs, List<Map<String, dynamic>> arrows) {
  const cs = 14.0;
  final size = (gs * cs + 2 * cs).round();
  final bodies = StringBuffer();
  final heads = StringBuffer();
  String n(double v) => v.round().toString();
  for (final a in arrows) {
    final path = a['path'] as List;
    final pts = path
        .map((p) => [cs + (p[0] + 0.5) * cs, cs + (p[1] + 0.5) * cs])
        .toList();
    bodies.write('M${n(pts[0][0])} ${n(pts[0][1])}');
    for (int i = 1; i < pts.length; i++) {
      bodies.write('L${n(pts[i][0])} ${n(pts[i][1])}');
    }
    final h = pts.last, p = pts[pts.length - 2];
    final dx = (h[0] - p[0]).sign, dy = (h[1] - p[1]).sign;
    final tx = h[0] + dx * cs * 0.36, ty = h[1] + dy * cs * 0.36;
    final wl = cs * 0.42;
    heads.write('M${n(tx + (-dx + -dy) * wl)} ${n(ty + (-dy + dx) * wl)}'
        'L${n(tx)} ${n(ty)}'
        'L${n(tx + (-dx + dy) * wl)} ${n(ty + (-dy - dx) * wl)}');
  }
  return '<svg viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">'
      '<rect width="$size" height="$size" fill="#F5ECDC"/>'
      '<path d="$bodies" fill="none" stroke="#5A4632" stroke-width="${cs * 0.30}" stroke-linecap="round" stroke-linejoin="round"/>'
      '<path d="$heads" fill="none" stroke="#5A4632" stroke-width="${cs * 0.30}" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>';
}

Set<String> buildMask(String shape, int gs) {
  final mask = <String>{};
  final mid = gs / 2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      final px = (x + 0.5 - mid) / (gs / 2);
      final py = (y + 0.5 - mid) / (gs / 2);
      if (inShape(shape, px, py)) mask.add('$x,$y');
    }
  }
  return mask;
}

bool inShape(String shape, double px, double py) {
  final ax = px.abs(), ay = py.abs();
  final r = sqrt(px * px + py * py);
  switch (shape) {
    case 'circle':
      return r <= 0.92;
    case 'square':
      return ax <= 0.85 && ay <= 0.85;
    case 'triangle':
      return py > -0.85 && py < 0.78 && ax <= 0.82 * (py + 0.85) / 1.63;
    case 'diamond':
      return ax + ay <= 0.98;
    case 'plus':
      return (ax <= 0.30 && ay <= 0.90) || (ay <= 0.30 && ax <= 0.90);
    case 'ring':
      return r >= 0.45 && r <= 0.92;
    case 'hexagon':
      return max(ax, ax * 0.5 + ay * 0.866) <= 0.82;
    case 'hourglass':
      return ay <= 0.85 && ax <= 0.14 + 0.62 * ay / 0.85;
    case 'moon':
      final r2 = sqrt(pow(px - 0.42, 2) + py * py);
      return r <= 0.90 && r2 > 0.62;
    case 'sun':
      if (r <= 0.52) return true;
      if (r > 0.95) return false;
      final ang = atan2(py, px);
      final m = ((ang % (pi / 4)) + pi / 4) % (pi / 4);
      return (m - pi / 8).abs() < 0.13 && r > 0.55;
    case 'house':
      final body = ax <= 0.62 && py > -0.10 && py < 0.82;
      final roof = py > -0.72 && py <= -0.10 && ax <= 0.78 * (py + 0.72) / 0.62;
      final chimney = px > 0.32 && px < 0.54 && py > -0.60 && py < -0.25;
      return body || roof || chimney;
    case 'tree':
      final t1 = py > -0.95 && py < -0.45 && ax <= 0.45 * (py + 0.95) / 0.5;
      final t2 = py > -0.55 && py < 0.05 && ax <= 0.62 * (py + 0.55) / 0.6;
      final t3 = py > -0.15 && py < 0.55 && ax <= 0.80 * (py + 0.15) / 0.7;
      final trunk = ax <= 0.13 && py >= 0.55 && py < 0.92;
      return t1 || t2 || t3 || trunk;
    case 'cup':
      final body = px > -0.62 && px < 0.42 &&
          py > -0.55 && py < 0.50 &&
          (px + 0.10).abs() <= 0.52 - 0.10 * (py + 0.55) / 1.05;
      final rr = sqrt(pow(px - 0.48, 2) + pow(py + 0.05, 2));
      final handle = rr >= 0.14 && rr <= 0.32 && px > 0.40;
      final base = (px + 0.10).abs() <= 0.38 && py >= 0.50 && py < 0.66;
      return body || handle || base;
    case 'kite':
      if (ay > 0.92) return false;
      final w = py < -0.1 ? 0.68 * (py + 0.92) / 0.82 : 0.68 * (0.92 - py) / 1.02;
      return ax <= w;
    case 'shield':
      final top = py > -0.88 && py <= 0.05 && ax <= 0.75;
      final bot = py > 0.05 && py < 0.90 && ax <= 0.75 * (0.90 - py) / 0.85;
      return top || bot;
    case 'bell':
      final dome = py > -0.88 && py < 0.42 &&
          ax <= 0.24 + 0.56 * pow((py + 0.88) / 1.3, 1.6);
      final lip = ay < 0.60 && py > 0.42 && py < 0.60 && ax <= 0.82;
      final clapper = sqrt(px * px + pow(py - 0.74, 2)) <= 0.13;
      return dome || lip || clapper;
    case 'heart':
      final lobe = (ax - 0.32) * (ax - 0.32) + (py + 0.28) * (py + 0.28) <= 0.16;
      final body = py > -0.28 && py < 0.88 && ax <= 0.70 * (0.88 - py) / 1.16;
      return lobe || body;
    case 'bulb':
      final globe = px * px + (py + 0.30) * (py + 0.30) <= 0.27;
      final neck = ax <= 0.20 && py > 0.10 && py < 0.44;
      final band1 = ax <= 0.28 && py > 0.50 && py < 0.62;
      final band2 = ax <= 0.28 && py > 0.68 && py < 0.80;
      return globe || neck || band1 || band2;
    case 'star':
      var phi = atan2(px, -py);
      const alpha = 2 * pi / 5;
      var u = (phi % alpha) / alpha;
      if (u < 0) u += 1;
      final tri = 1 - (1 - 2 * u).abs();
      return r <= 0.95 + (0.40 - 0.95) * tri;
    case 'butterfly':
      final topW = pow((ax - 0.40) / 0.40, 2) + pow((py + 0.28) / 0.36, 2) <= 1;
      final botW = pow((ax - 0.30) / 0.32, 2) + pow((py - 0.30) / 0.30, 2) <= 1;
      final body = ax <= 0.07 && ay <= 0.62;
      return topW || botW || body;
    case 'rocket':
      final nose = py > -0.92 && py < -0.42 && ax <= 0.30 * (py + 0.92) / 0.5;
      final bodyR = ax <= 0.28 && py > -0.42 && py < 0.42;
      final fins = py > 0.05 && py < 0.50 && ax <= 0.28 + 0.30 * (py - 0.05) / 0.45;
      final flame = py > 0.52 && py < 0.90 && ax <= 0.18 * (0.90 - py) / 0.38;
      return nose || bodyR || fins || flame;
    case 'flower':
      if (r <= 0.26) return true;
      for (int k = 0; k < 6; k++) {
        final th = k * pi / 3 + pi / 6;
        final u = px * cos(th) + py * sin(th);
        final v = -px * sin(th) + py * cos(th);
        if (pow((u - 0.55) / 0.36, 2) + pow(v / 0.21, 2) <= 1) return true;
      }
      return false;
    case 'fish':
      final body = pow((px + 0.18) / 0.55, 2) + pow(py / 0.34, 2) <= 1;
      final tail = px > 0.30 && px < 0.80 && ay <= 0.52 * (px - 0.30) / 0.50;
      return body || tail;
    case 'crown':
      final band = py > 0.28 && py < 0.72 && ax <= 0.78;
      for (final cx in [-0.56, 0.0, 0.56]) {
        if (py > -0.78 && py <= 0.28 &&
            (px - cx).abs() <= 0.26 * (py + 0.78) / 1.06) {
          return true;
        }
      }
      return band;
    case 'gem':
      final top = py > -0.60 && py <= -0.18 && ax <= 0.42 + 0.44 * (py + 0.60) / 0.42;
      final bottom = py > -0.18 && py < 0.82 && ax <= 0.86 * (0.82 - py) / 1.0;
      return top || bottom;
    case 'snowflake':
      if (r <= 0.18) return true;
      for (int k = 0; k < 3; k++) {
        final th = k * pi / 3;
        final u = px * cos(th) + py * sin(th);
        final v = -px * sin(th) + py * cos(th);
        if (v.abs() <= 0.10 && u.abs() <= 0.92) return true;
        if (((u.abs() - 0.50).abs() <= 0.07) && v.abs() <= 0.28) return true;
      }
      return false;
    case 'plane':
      final noseTaper = py > -0.92 && py < -0.70
          ? 0.13 * (py + 0.92) / 0.22
          : (py >= -0.70 && py < 0.70 ? 0.13 : -1.0);
      if (noseTaper > 0 && ax <= noseTaper) return true;
      final wing = ax <= 0.88 &&
          py > ax * 0.35 - 0.05 && py < ax * 0.35 + 0.18;
      final tail = ax <= 0.40 &&
          py > 0.55 + ax * 0.30 - 0.04 && py < 0.55 + ax * 0.30 + 0.12;
      return wing || tail;
    case 'umbrella':
      final canopy = pow(px / 0.88, 2) + pow(py / 0.85, 2) <= 1 && py <= -0.05;
      final shaft = ax <= 0.06 && py > -0.05 && py < 0.62;
      final hookR = sqrt(pow(px - 0.16, 2) + pow(py - 0.62, 2));
      final hook = hookR >= 0.09 && hookR <= 0.24 && py >= 0.62;
      return canopy || shaft || hook;
    case 'target':
      return r <= 0.28 ||
          (r >= 0.46 && r <= 0.64) ||
          (r >= 0.80 && r <= 0.95);
    case 'anchor':
      final ringTop = sqrt(px * px + pow(py + 0.68, 2));
      final bow2 = ringTop >= 0.10 && ringTop <= 0.26;
      final shaft2 = ax <= 0.08 && py > -0.45 && py < 0.60;
      final cross = (py + 0.25).abs() <= 0.07 && ax <= 0.38;
      final arcR = sqrt(px * px + pow(py - 0.05, 2));
      final flukes = arcR >= 0.52 && arcR <= 0.72 && py > 0.35;
      return bow2 || shaft2 || cross || flukes;
    case 'infinity':
      final dInf = sqrt(pow(ax - 0.45, 2) + py * py);
      return dInf >= 0.20 && dInf <= 0.46;
    case 'mushroom':
      final cap = pow(px / 0.78, 2) + pow((py + 0.30) / 0.52, 2) <= 1 && py <= -0.02;
      final stem = ax <= 0.16 + 0.10 * (py + 0.02) / 0.8 && py > -0.02 && py < 0.78;
      return cap || stem;
    case 'note':
      final headN = pow((px + 0.28) / 0.30, 2) + pow((py - 0.55) / 0.22, 2) <= 1;
      final stemN = (px - 0.02).abs() <= 0.07 && py > -0.78 && py < 0.55;
      final flag = px > 0.02 && px < 0.55 &&
          (py - (-0.78 + 0.9 * (px - 0.02))).abs() <= 0.13;
      return headN || stemN || flag;
    case 'cat':
      final headC = px * px + pow(py - 0.05, 2) <= 0.36;
      for (final s in [-1.0, 1.0]) {
        if (py > -0.95 && py < -0.30 &&
            (px - s * 0.40).abs() <= 0.24 * (py + 0.95) / 0.65) {
          return true;
        }
      }
      return headC;
    case 'key':
      final bowK = sqrt(px * px + pow(py + 0.60, 2));
      final ringK = bowK >= 0.14 && bowK <= 0.34;
      final shaftK = ax <= 0.08 && py > -0.28 && py < 0.85;
      final tooth1 = px > 0.08 && px < 0.38 && py > 0.48 && py < 0.62;
      final tooth2 = px > 0.08 && px < 0.30 && py > 0.70 && py < 0.84;
      return ringK || shaftK || tooth1 || tooth2;
    case 'boat':
      final hull = py > 0.35 && py < 0.78 && ax <= 0.85 - 0.38 * (py - 0.35) / 0.43;
      final mast = ax <= 0.05 && py > -0.90 && py < 0.35;
      final mainSail = px > 0.05 && px < 0.78 && py > -0.85 && py < 0.25 &&
          px <= 0.75 * (py + 0.85) / 1.10;
      final jib = px < -0.05 && px > -0.58 && py > -0.60 && py < 0.25 &&
          -px <= 0.55 * (py + 0.60) / 0.85;
      return hull || mast || mainSail || jib;
    case 'leaf':
      if (py > -0.92 && py < 0.70) {
        final t = (py + 0.92) / 1.62;
        if (ax <= 0.68 * pow(sin(pi * t), 0.8)) return true;
      }
      return ax <= 0.05 && py >= 0.70 && py < 0.92;
    case 'zap':
      final upper = py > -0.92 && py < 0.12 &&
          (px - (0.30 - 0.55 * (py + 0.92) / 1.04)).abs() <= 0.24;
      final lower = py > -0.12 && py < 0.92 &&
          (px - (0.28 - 0.55 * (py + 0.12) / 1.04)).abs() <= 0.24;
      return upper || lower;
    case 'clover':
      for (int k = 0; k < 4; k++) {
        final th = pi / 4 + k * pi / 2;
        final cx = 0.36 * cos(th), cy = -0.10 + 0.36 * sin(th);
        if (pow(px - cx, 2) + pow(py - cy, 2) <= 0.31 * 0.31) return true;
      }
      return (px - 0.10 * (py - 0.26) / 0.62 * 0.5).abs() <= 0.07 &&
          py > 0.26 && py < 0.88;
    case 'trophy':
      if (py > -0.88 && py < -0.12) {
        final t = (py + 0.88) / 0.76;
        if (ax <= 0.60 * (1 - 0.55 * t * t)) return true;
      }
      final rr = sqrt(pow(ax - 0.62, 2) + pow(py + 0.60, 2));
      final handle = rr >= 0.13 && rr <= 0.30 && py < -0.30;
      final stem = ax <= 0.10 && py >= -0.14 && py < 0.32;
      final base1 = ax <= 0.40 && py >= 0.32 && py < 0.50;
      final base2 = ax <= 0.56 && py >= 0.50 && py < 0.68;
      return handle || stem || base1 || base2;
    // ---------- XL era shapes (levels 101-130) ----------
    case 'octagon':
      return max(ax, ay) <= 0.88 && ax + ay <= 1.24;
    case 'pentagon':
      var phi5 = atan2(px, -py);
      const a5 = 2 * pi / 5;
      var m5 = phi5 % a5;
      if (m5 < 0) m5 += a5;
      return r <= 0.88 * cos(pi / 5) / cos(m5 - pi / 5);
    case 'arrow':
      final headA = py > -0.90 && py <= -0.05 && ax <= 0.80 * (py + 0.90) / 0.85;
      final shaftA = ax <= 0.26 && py > -0.05 && py < 0.90;
      return headA || shaftA;
    case 'cloud':
      if (pow(px + 0.40, 2) + pow(py - 0.05, 2) <= 0.38 * 0.38) return true;
      if (pow(px - 0.05, 2) + pow(py + 0.18, 2) <= 0.50 * 0.50) return true;
      if (pow(px - 0.45, 2) + pow(py - 0.08, 2) <= 0.36 * 0.36) return true;
      return py > 0.05 && py < 0.40 && ax <= 0.70;
    case 'drop':
      final bulbD = px * px + pow(py - 0.30, 2) <= 0.52 * 0.52;
      final coneD = py > -0.90 && py <= 0.30 && ax <= 0.52 * (py + 0.90) / 1.20;
      return bulbD || coneD;
    case 'flame':
      if (py <= -0.88 || py >= 0.88) return false;
      final tf = (py + 0.88) / 1.76;
      final wf = 0.55 * pow(sin(pi * pow(tf, 1.3)), 0.9) *
          (1 + 0.16 * sin(9 * py));
      return ax <= wf;
    case 'bone':
      if (ay <= 0.15 && ax <= 0.55) return true;
      for (final sx in [-0.55, 0.55]) {
        for (final sy in [-0.17, 0.17]) {
          if (pow(px - sx, 2) + pow(py - sy, 2) <= 0.24 * 0.24) return true;
        }
      }
      return false;
    case 'paw':
      if (pow(px / 0.42, 2) + pow((py - 0.32) / 0.32, 2) <= 1) return true;
      for (final toe in [[-0.48, -0.05], [-0.17, -0.30], [0.17, -0.30], [0.48, -0.05]]) {
        if (pow(px - toe[0], 2) + pow(py - toe[1], 2) <= 0.17 * 0.17) return true;
      }
      return false;
    case 'turtle':
      if (pow(px / 0.55, 2) + pow(py / 0.40, 2) <= 1) return true;
      if (pow(px - 0.66, 2) + py * py <= 0.17 * 0.17) return true;
      for (final leg in [[-0.34, -0.42], [0.34, -0.42], [-0.34, 0.42], [0.34, 0.42]]) {
        if (pow(px - leg[0], 2) + pow(py - leg[1], 2) <= 0.13 * 0.13) return true;
      }
      return px > -0.78 && px < -0.55 && py.abs() <= 0.10 * (px + 0.78) / 0.23;
    case 'owl':
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.20, 2) + pow(py + 0.18, 2) <= 0.13 * 0.13) return false;
        if (py > -0.88 && py < -0.45 &&
            (px - s * 0.30).abs() <= 0.15 * (py + 0.88) / 0.43) {
          return true;
        }
      }
      return pow(px / 0.50, 2) + pow((py - 0.08) / 0.62, 2) <= 1;
    case 'whale':
      final bodyW = pow((px + 0.15) / 0.60, 2) + pow((py - 0.10) / 0.36, 2) <= 1;
      final tailW = px > 0.40 && px < 0.85 &&
          (py - 0.02).abs() <= 0.42 * (px - 0.40) / 0.45;
      return bodyW || tailW;
    case 'duck':
      final bodyDk = pow((px - 0.10) / 0.55, 2) + pow((py - 0.28) / 0.30, 2) <= 1;
      final headDk = pow(px + 0.32, 2) + pow(py + 0.28, 2) <= 0.24 * 0.24;
      final beak = px > -0.82 && px < -0.50 && (py + 0.24).abs() <= 0.08;
      return bodyDk || headDk || beak;
    case 'rabbit':
      if (px * px + pow(py - 0.35, 2) <= 0.40 * 0.40) return true;
      return pow((ax - 0.20) / 0.14, 2) + pow((py + 0.35) / 0.55, 2) <= 1;
    case 'ghost':
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.20, 2) + pow(py + 0.15, 2) <= 0.11 * 0.11) return false;
      }
      final domeG = px * px + pow(py + 0.15, 2) <= 0.60 * 0.60 && py <= -0.15;
      final bodyG = ax <= 0.60 && py > -0.15 && py <= 0.62;
      final frill = ax <= 0.60 && py > 0.62 &&
          py <= 0.62 + 0.16 * (0.5 + 0.5 * sin(px * 10.5));
      return domeG || bodyG || frill;
    case 'robot':
      final headR = ax <= 0.40 && py > -0.85 && py < -0.38;
      final antenna = ax <= 0.05 && py > -0.97 && py <= -0.85;
      final bodyRb = ax <= 0.55 && py > -0.28 && py < 0.42;
      final armsR = ax > 0.55 && ax <= 0.80 && py > -0.25 && py < 0.05;
      final legsR = (ax - 0.26).abs() <= 0.12 && py >= 0.42 && py < 0.88;
      return headR || antenna || bodyRb || armsR || legsR;
    case 'pizza':
      final triP = py > -0.82 && py < 0.90 && ax <= 0.60 * (0.90 - py) / 1.72;
      final crust = py > -0.82 && py < -0.56 &&
          ax <= 0.60 * (0.90 - py) / 1.72 + 0.06;
      return triP || crust;
    case 'icecream':
      final coneI = py > 0.02 && py < 0.92 && ax <= 0.44 * (0.92 - py) / 0.90;
      if (coneI) return true;
      for (final sc in [[-0.22, -0.12, 0.28], [0.22, -0.12, 0.28], [0.0, -0.42, 0.30]]) {
        if (pow(px - sc[0], 2) + pow(py - sc[1], 2) <= sc[2] * sc[2]) return true;
      }
      return false;
    case 'cupcake':
      for (final f in [[0.0, -0.30, 0.40], [-0.32, -0.12, 0.26], [0.32, -0.12, 0.26], [0.0, -0.70, 0.13]]) {
        if (pow(px - f[0], 2) + pow(py - f[1], 2) <= f[2] * f[2]) return true;
      }
      return py > 0.02 && py < 0.68 && ax <= 0.50 - 0.14 * (py - 0.02) / 0.66;
    case 'candy':
      if (r <= 0.40) return true;
      return ax > 0.40 && ax <= 0.85 && ay <= 0.32 * (ax - 0.38) / 0.47;
    case 'gift':
      final boxG = ax <= 0.60 && py > -0.18 && py < 0.75;
      final lidG = ax <= 0.70 && py > -0.40 && py <= -0.18;
      final ribbon = ax <= 0.09 && py > -0.55 && py <= -0.40;
      final bow = pow(ax - 0.20, 2) + pow(py + 0.55, 2) <= 0.17 * 0.17;
      return boxG || lidG || ribbon || bow;
    case 'balloon':
      if (pow(px / 0.46, 2) + pow((py + 0.28) / 0.55, 2) <= 1) return true;
      final knot = py > 0.25 && py < 0.42 && ax <= 0.55 * (py - 0.24);
      final string = py >= 0.42 && py < 0.95 &&
          (px - 0.06 * sin(6 * (py - 0.42))).abs() <= 0.035;
      return knot || string;
    case 'guitar':
      if (px * px + pow(py - 0.28, 2) <= 0.14 * 0.14) return false;
      if (px * px + pow(py - 0.45, 2) <= 0.42 * 0.42) return true;
      if (px * px + pow(py - 0.02, 2) <= 0.30 * 0.30) return true;
      final neckG = ax <= 0.07 && py > -0.88 && py <= -0.02;
      final headG = ax <= 0.14 && py > -0.98 && py <= -0.88;
      return neckG || headG;
    case 'camera':
      final lensR = sqrt(px * px + pow(py - 0.12, 2));
      if (lensR >= 0.15 && lensR <= 0.27) return false;
      final bodyC = ax <= 0.75 && py > -0.28 && py < 0.55;
      final hump = px > -0.45 && px < -0.05 && py > -0.45 && py <= -0.28;
      final flash = px > 0.30 && px < 0.55 && py > -0.42 && py <= -0.28;
      return bodyC || hump || flash;
    case 'magnet':
      final arcM = r >= 0.30 && r <= 0.68 && py <= 0.15;
      final legsM = (ax - 0.49).abs() <= 0.19 && py > 0.15 && py < 0.62;
      return arcM || legsM;
    case 'lock':
      if (px * px + py * py <= 0.10 * 0.10) return false;
      if (ax <= 0.05 && py > 0 && py < 0.28) return false;
      final shackle = sqrt(px * px + pow(py + 0.38, 2)) >= 0.20 &&
          sqrt(px * px + pow(py + 0.38, 2)) <= 0.36 &&
          py <= -0.38;
      final bodyL = ax <= 0.52 && py > -0.38 && py < 0.62;
      return shackle || bodyL;
    case 'skull':
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.22, 2) + pow(py + 0.12, 2) <= 0.14 * 0.14) return false;
      }
      if (px * px + pow(py - 0.18, 2) <= 0.08 * 0.08) return false;
      final domeS = px * px + pow(py + 0.12, 2) <= 0.55 * 0.55;
      final jaw = ax <= 0.34 && py >= 0.30 && py < 0.66;
      return domeS || jaw;
    case 'cactus':
      final trunkC = ax <= 0.14 && py > -0.82 && py < 0.92;
      final armL = (px + 0.40).abs() <= 0.11 && py > -0.38 && py < 0.10;
      final connL = (py - 0.05).abs() <= 0.09 && px >= -0.40 && px <= -0.14;
      final armR = (px - 0.40).abs() <= 0.11 && py > -0.55 && py < -0.10;
      final connR = (py + 0.12).abs() <= 0.09 && px >= 0.14 && px <= 0.40;
      return trunkC || armL || connL || armR || connR;
    case 'pinwheel':
      if (r <= 0.14) return true;
      for (int k = 0; k < 4; k++) {
        final th = k * pi / 2;
        final u = px * cos(th) + py * sin(th);
        final v = -px * sin(th) + py * cos(th);
        if (u > 0.06 && u < 0.85 && v > 0.04 && v <= 0.40 * (0.85 - u) / 0.79) {
          return true;
        }
      }
      return false;
    case 'sword':
      final tipS = py > -0.97 && py <= -0.78 && ax <= 0.10 * (py + 0.97) / 0.19;
      final blade = ax <= 0.10 && py > -0.78 && py < 0.34;
      final guard = (py - 0.40).abs() <= 0.06 && ax <= 0.38;
      final hilt = ax <= 0.08 && py > 0.46 && py < 0.78;
      final pommel = px * px + pow(py - 0.85, 2) <= 0.11 * 0.11;
      return tipS || blade || guard || hilt || pommel;
    case 'smiley':
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.30, 2) + pow(py + 0.25, 2) <= 0.13 * 0.13) return false;
      }
      if (r >= 0.42 && r <= 0.58 && py > 0.18) return false;
      return r <= 0.85;
    // ---------- Mega era shapes (levels 131-200) ----------
    case 'elephant': {
      final body = pow((px - 0.10) / 0.55, 2) + pow((py - 0.15) / 0.42, 2) <= 1;
      final head = pow(px + 0.45, 2) + pow(py + 0.15, 2) <= 0.32 * 0.32;
      final trunk = py > -0.15 && py < 0.55 &&
          (px + 0.68 - 0.08 * sin(3 * (py + 0.15))).abs() <= 0.09;
      final legs = ((px + 0.12).abs() <= 0.10 || (px - 0.38).abs() <= 0.10) &&
          py > 0.50 && py < 0.85;
      return body || head || trunk || legs;
    }
    case 'yinyang': {
      if (r > 0.85) return false;
      if (px * px + pow(py - 0.42, 2) <= 0.13 * 0.13) return true;
      if (px * px + pow(py + 0.42, 2) <= 0.13 * 0.13) return false;
      final inTop = px * px + pow(py + 0.42, 2) <= 0.42 * 0.42;
      final inBot = px * px + pow(py - 0.42, 2) <= 0.42 * 0.42;
      return (px > 0 && !inBot) || inTop;
    }
    case 'palm': {
      final trunk = py > -0.20 && py < 0.90 &&
          (px - 0.12 * sin(2 * py)).abs() <= 0.09;
      if (trunk) return true;
      final r2 = sqrt(px * px + pow(py + 0.32, 2));
      return r2 <= 0.58 && py < -0.05 &&
          sin(4.5 * atan2(py + 0.32, px) + 0.6) > 0.15;
    }
    case 'gear': {
      if (r <= 0.18) return false; // axle hole
      if (r <= 0.58) return true;
      final ang = atan2(py, px);
      return r <= 0.80 && sin(8 * ang) > 0.30;
    }
    case 'penguin': {
      final body = pow(px / 0.45, 2) + pow((py - 0.12) / 0.60, 2) <= 1;
      final head = px * px + pow(py + 0.55, 2) <= 0.28 * 0.28;
      final beakP = px > 0.24 && px < 0.44 && (py + 0.55).abs() <= 0.07;
      final feet = (px.abs() - 0.18).abs() <= 0.12 && py > 0.70 && py < 0.85;
      return body || head || beakP || feet;
    }
    case 'saturn': {
      if (r <= 0.45) return true;
      final u = px * cos(-0.35) + py * sin(-0.35);
      final v = -px * sin(-0.35) + py * cos(-0.35);
      final e = pow(u / 0.88, 2) + pow(v / 0.28, 2);
      return e <= 1 && e >= 0.55;
    }
    case 'wineglass': {
      final bowl = pow(px / 0.42, 2) + pow((py + 0.55) / 0.32, 2) <= 1 && py <= -0.35;
      final stemW = ax <= 0.05 && py > -0.35 && py < 0.50;
      final baseW = ax <= 0.35 && py >= 0.50 && py < 0.62;
      return bowl || stemW || baseW;
    }
    case 'dove': {
      final body = pow((px - 0.05) / 0.45, 2) + pow((py - 0.05) / 0.30, 2) <= 1;
      final head = pow(px + 0.40, 2) + pow(py + 0.15, 2) <= 0.15 * 0.15;
      final beakD = px > -0.66 && px < -0.52 && (py + 0.15).abs() <= 0.05;
      final wing = pow((px - 0.10) / 0.30, 2) + pow((py + 0.38) / 0.20, 2) <= 1;
      final tail = px > 0.40 && px < 0.78 &&
          (py - (0.05 + (px - 0.40) * 0.35)).abs() <= 0.10;
      return body || head || beakD || wing || tail;
    }
    case 'spiral': {
      var ang = atan2(py, px) + pi;
      for (int k = 0; k < 4; k++) {
        final rr = 0.06 + 0.13 * (ang / (2 * pi) + k);
        if (rr <= 0.88 && (r - rr).abs() <= 0.065) return true;
      }
      return false;
    }
    case 'castle': {
      final teeth = (((px + 1) * 7).floor() % 2 == 0);
      final base = ax <= 0.80 && py > 0.10 && py < 0.80;
      final towers = (ax - 0.60).abs() <= 0.16 && py > -0.50 && py <= 0.10;
      final towerTop = (ax - 0.60).abs() <= 0.16 && py > -0.65 && py <= -0.50 && teeth;
      final wallTop = ax <= 0.40 && py > -0.05 && py <= 0.10 && teeth;
      if (ax <= 0.15 && py > 0.45 && py < 0.80) return false; // gate
      if (px * px + pow(py - 0.45, 2) <= 0.15 * 0.15) return false;
      return base || towers || towerTop || wallTop;
    }
    case 'frog': {
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.32, 2) + pow(py + 0.30, 2) <= 0.08 * 0.08) return false;
        if (pow(px - s * 0.32, 2) + pow(py + 0.28, 2) <= 0.20 * 0.20) return true;
      }
      return pow(px / 0.62, 2) + pow((py - 0.15) / 0.45, 2) <= 1;
    }
    case 'comet': {
      if (pow(px + 0.42, 2) + pow(py - 0.35, 2) <= 0.30 * 0.30) return true;
      final u = px + 0.42, v = py - 0.35;
      final t = 0.74 * u - 0.67 * v;
      final per = 0.67 * u + 0.74 * v;
      if (t > 0.08 && t < 1.30 && per.abs() <= 0.30 * (1.30 - t) / 1.22) return true;
      // trailing sparkles
      if (pow(px - 0.42, 2) + pow(py + 0.55, 2) <= 0.10 * 0.10) return true;
      return pow(px - 0.12, 2) + pow(py + 0.18, 2) <= 0.08 * 0.08;
    }
    case 'puzzle': {
      if (pow(px + 0.60, 2) + py * py <= 0.17 * 0.17) return false;
      if (px * px + pow(py - 0.60, 2) <= 0.17 * 0.17) return false;
      if (ax <= 0.60 && ay <= 0.60) return true;
      if (px * px + pow(py + 0.66, 2) <= 0.17 * 0.17) return true;
      return pow(px - 0.66, 2) + py * py <= 0.17 * 0.17;
    }
    case 'shark': {
      if (pow(px + 0.55, 2) + pow(py - 0.18, 2) <= 0.12 * 0.12) return false;
      final body = pow(px / 0.60, 2) + pow((py - 0.05) / 0.28, 2) <= 1;
      final fin = py > -0.50 && py <= -0.20 &&
          (px + 0.05).abs() <= 0.18 * (py + 0.50) / 0.30;
      final tail = px > 0.55 && px < 0.80 && py.abs() <= 0.40 * (px - 0.55) / 0.25;
      return body || fin || tail;
    }
    case 'peace': {
      if (r > 0.85) return false;
      if (r >= 0.66) return true;
      if (ax <= 0.09) return true;
      if (py >= 0) {
        for (final s in [-1.0, 1.0]) {
          final per = px * 0.707 - s * py * 0.707;
          final t = px * s * 0.707 + py * 0.707;
          if (per.abs() <= 0.09 && t > 0) return true;
        }
      }
      return false;
    }
    case 'teapot': {
      final body = pow(px / 0.50, 2) + pow((py - 0.15) / 0.40, 2) <= 1;
      final spout = px > -0.82 && px < -0.45 &&
          (py - (-0.25 + 0.3 * (px + 0.82) / 0.37)).abs() <= 0.09;
      final hr = sqrt(pow(px - 0.60, 2) + py * py);
      final handleT = hr >= 0.12 && hr <= 0.26 && px > 0.50;
      final knob = px * px + pow(py + 0.35, 2) <= 0.10 * 0.10;
      final lid = (py + 0.26).abs() <= 0.05 && ax <= 0.35;
      return body || spout || handleT || knob || lid;
    }
    case 'snail': {
      if (pow(px - 0.15, 2) + pow(py + 0.05, 2) <= 0.42 * 0.42) {
        final rs = sqrt(pow(px - 0.15, 2) + pow(py + 0.05, 2));
        if (rs >= 0.15 && rs <= 0.24 && py < -0.05) return false; // spiral groove
        return true;
      }
      final foot = py > 0.40 && py < 0.60 && px > -0.70 && px < 0.55;
      final neck = (px + 0.55).abs() <= 0.10 && py > 0.00 && py < 0.50;
      final horn = (px + 0.66).abs() <= 0.05 && py > -0.30 && py <= 0.00;
      return foot || neck || horn;
    }
    case 'ufo': {
      final dome = px * px + pow(py + 0.25, 2) <= 0.30 * 0.30 && py <= -0.18;
      final saucer = pow(px / 0.75, 2) + pow((py + 0.05) / 0.20, 2) <= 1;
      final beam = py > 0.10 && py < 0.60 && ax <= 0.15 + 0.30 * (py - 0.10) / 0.50;
      return dome || saucer || beam;
    }
    case 'medal': {
      for (final s in [-1.0, 1.0]) {
        if (py > -0.90 && py < -0.22 &&
            (px - s * 0.35 * ((-0.22 - py) / 0.68)).abs() <= 0.11) {
          return true;
        }
      }
      if (px * px + pow(py - 0.30, 2) <= 0.12 * 0.12) return false;
      return px * px + pow(py - 0.30, 2) <= 0.40 * 0.40;
    }
    case 'octopus': {
      final headO = px * px + pow(py + 0.30, 2) <= 0.40 * 0.40 && py <= -0.10;
      if (headO) return true;
      for (final k in [-0.45, -0.15, 0.15, 0.45]) {
        if (py > -0.12 && py < 0.70 &&
            (px - k - 0.07 * sin(6 * py)).abs() <= 0.07) {
          return true;
        }
      }
      return false;
    }
    case 'mountain': {
      final peak1 = py > -0.70 && py < 0.60 && (px + 0.30).abs() <= 0.55 * (py + 0.70) / 1.30;
      final peak2 = py > -0.45 && py < 0.60 && (px - 0.35).abs() <= 0.45 * (py + 0.45) / 1.05;
      final baseM = py >= 0.60 && py < 0.75 && ax <= 0.85;
      return peak1 || peak2 || baseM;
    }
    case 'glasses': {
      for (final s in [-1.0, 1.0]) {
        final lr = sqrt(pow(px - s * 0.40, 2) + py * py);
        if (lr >= 0.18 && lr <= 0.32) return true;
      }
      final bridge = py.abs() <= 0.05 && ax <= 0.12;
      final arms = (py + 0.05).abs() <= 0.05 && ax > 0.70 && ax < 0.95;
      return bridge || arms;
    }
    case 'bat': {
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.35, 2) + pow(py - 0.18, 2) <= 0.12 * 0.12) return false;
        if (pow(px - s * 0.65, 2) + py * py <= 0.10 * 0.10) return false;
      }
      final wing = ax > 0.10 && ax < 0.90 && py > -0.40 &&
          py <= 0.15 - 0.50 * (ax - 0.10);
      final bodyB = px * px + py * py <= 0.16 * 0.16;
      final ears = (ax - 0.12).abs() <= 0.05 && py > -0.55 && py <= -0.30;
      return wing || bodyB || ears;
    }
    case 'atom': {
      if (r <= 0.13) return true;
      for (int k = 0; k < 3; k++) {
        final th = k * pi / 3;
        final u = px * cos(th) + py * sin(th);
        final v = -px * sin(th) + py * cos(th);
        final e = pow(u / 0.85, 2) + pow(v / 0.30, 2);
        if (e <= 1 && e >= 0.55) return true;
      }
      return false;
    }
    case 'tophat': {
      final brim = pow(px / 0.70, 2) + pow((py - 0.35) / 0.14, 2) <= 1;
      if ((py - 0.18).abs() <= 0.05 && ax <= 0.38) return false; // band
      final crownH = ax <= 0.38 && py > -0.65 && py < 0.35;
      return brim || crownH;
    }
    case 'crab': {
      final bodyCr = pow(px / 0.45, 2) + pow((py - 0.10) / 0.32, 2) <= 1;
      if (bodyCr) return true;
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.60, 2) + pow(py + 0.25, 2) <= 0.18 * 0.18) return true;
        if (py > -0.20 && py < 0.05 && (px * s) > 0.40 && (px * s) < 0.62) return true;
        for (final m in [0.30, 0.60, 0.90]) {
          if (ax > 0.45 && ax < 0.80 &&
              ((py - 0.30) - m * (ax - 0.45)).abs() <= 0.05) {
            return true;
          }
        }
      }
      return false;
    }
    case 'volcano': {
      final cone = py > -0.35 && py < 0.70 && ax <= 0.25 + 0.50 * (py + 0.35) / 1.05;
      if (cone) return true;
      if (px * px + pow(py + 0.50, 2) <= 0.15 * 0.15) return true;
      if (pow(px + 0.20, 2) + pow(py + 0.62, 2) <= 0.11 * 0.11) return true;
      return pow(px - 0.18, 2) + pow(py + 0.66, 2) <= 0.10 * 0.10;
    }
    case 'scissors': {
      if (px * px + py * py <= 0.08 * 0.08) return true;
      for (final s in [-1.0, 1.0]) {
        final a = s * 0.45;
        final u = px * cos(a) + py * sin(a);
        final v = -px * sin(a) + py * cos(a);
        if (pow((u + 0.28) / 0.50, 2) + pow(v / 0.09, 2) <= 1 && py < 0.1) return true;
        final hr = sqrt(pow(px - s * 0.25, 2) + pow(py - 0.50, 2));
        if (hr >= 0.10 && hr <= 0.24) return true;
      }
      return false;
    }
    case 'seahorse': {
      final head = pow(px + 0.15, 2) + pow(py + 0.50, 2) <= 0.20 * 0.20;
      final snout = px > -0.52 && px < -0.28 && (py + 0.50).abs() <= 0.07;
      final bodySh = py > -0.40 && py < 0.50 &&
          (px - 0.05 - 0.10 * sin(3 * (py + 0.20))).abs() <= 0.13;
      final tr = sqrt(pow(px - 0.15, 2) + pow(py - 0.60, 2));
      final tailSh = tr >= 0.10 && tr <= 0.22 && py > 0.45;
      return head || snout || bodySh || tailSh;
    }
    case 'hexagram': {
      final t1 = py <= 0.55 && py >= -0.75 + 2.0 * ax;
      final t2 = -py <= 0.55 && -py >= -0.75 + 2.0 * ax;
      return t1 || t2;
    }
    case 'book': {
      final page = ax > 0.03 && ax < 0.78 &&
          py > -0.45 + 0.15 * ax && py < 0.35 - 0.10 * ax;
      final spine = ax <= 0.03 && py > -0.30 && py < 0.40;
      return page || spine;
    }
    case 'bee': {
      if ((py + 0.05).abs() <= 0.045 && ax <= 0.34) return false;
      if ((py - 0.25).abs() <= 0.045 && ax <= 0.32) return false;
      final bodyBe = pow(px / 0.34, 2) + pow((py - 0.10) / 0.48, 2) <= 1;
      final wings = pow((ax - 0.38) / 0.24, 2) + pow((py + 0.30) / 0.16, 2) <= 1;
      final ant = (ax - 0.10).abs() <= 0.04 && py > -0.72 && py < -0.55;
      return bodyBe || wings || ant;
    }
    case 'wave': {
      final cr = sqrt(pow(px - 0.15, 2) + pow(py + 0.05, 2));
      final curl = cr >= 0.32 && cr <= 0.60 && (px - 0.15 > 0 || py + 0.05 < 0);
      final swell = py > 0.30 + 0.10 * sin(4 * px) && py < 0.62 && ax <= 0.85;
      final foam = pow(px - 0.32, 2) + pow(py + 0.22, 2) <= 0.12 * 0.12;
      return curl || swell || foam;
    }
    case 'envelope': {
      if (py < 0.05 && ((py + 0.50) - 0.66 * ax).abs() <= 0.035) return false;
      return ax <= 0.75 && ay <= 0.50;
    }
    case 'jellyfish': {
      final dome = px * px + pow(py + 0.25, 2) <= 0.45 * 0.45 && py <= -0.18;
      final band = py > -0.20 && py < -0.10 && ax <= 0.45;
      if (dome || band) return true;
      for (final k in [-0.30, -0.10, 0.10, 0.30]) {
        if (py > -0.08 && py < 0.65 &&
            (px - k - 0.06 * sin(7 * py)).abs() <= 0.05) {
          return true;
        }
      }
      return false;
    }
    case 'tornado': {
      final widths = [0.75, 0.60, 0.46, 0.33, 0.21, 0.11];
      for (int k = 0; k < 6; k++) {
        final y0 = -0.80 + k * 0.26;
        if (py >= y0 && py < y0 + 0.20 &&
            ax <= widths[k] + 0.05 * sin(8 * py + k)) {
          return true;
        }
      }
      return false;
    }
    case 'diamondring': {
      final br = sqrt(px * px + pow(py - 0.25, 2));
      final band = br >= 0.30 && br <= 0.45;
      final gemR = (ax + (py + 0.60).abs()) <= 0.26;
      return band || gemR;
    }
    case 'swan': {
      final bodySw = pow((px - 0.15) / 0.45, 2) + pow((py - 0.30) / 0.30, 2) <= 1;
      final neck = py > -0.55 && py < 0.35 &&
          (px + 0.35 - 0.15 * sin(2.6 * py)).abs() <= 0.09;
      final headSw = pow(px + 0.50, 2) + pow(py + 0.60, 2) <= 0.13 * 0.13;
      final beakSw = px > -0.72 && px < -0.55 && (py + 0.60).abs() <= 0.05;
      return bodySw || neck || headSw || beakSw;
    }
    case 'hotair': {
      if (px * px + pow(py + 0.30, 2) <= 0.50 * 0.50) return true;
      final basket = ax <= 0.20 && py > 0.45 && py < 0.70;
      if (basket) return true;
      for (final s in [-1.0, 1.0]) {
        if (py > 0.16 && py < 0.47 &&
            (px - s * (0.30 - 0.12 * (py - 0.16) / 0.31)).abs() <= 0.035) {
          return true;
        }
      }
      return false;
    }
    case 'bowtie': {
      final tri = ax > 0.08 && ax < 0.62 && ay <= 0.38 * (ax - 0.08) / 0.54;
      final knot = ax <= 0.10 && ay <= 0.16;
      return tri || knot;
    }
    case 'fox': {
      final headF = ax * 0.9 + (py - 0.05).abs() <= 0.62;
      for (final s in [-1.0, 1.0]) {
        if (py > -0.85 && py < -0.30 &&
            (px - s * 0.35).abs() <= 0.22 * (py + 0.85) / 0.55) {
          return true;
        }
      }
      return headF;
    }
    case 'windmill': {
      final tower = py > -0.10 && py < 0.85 && ax <= 0.12 + 0.15 * (py + 0.10) / 0.95;
      if (tower) return true;
      final cy = py + 0.32;
      if (px * px + cy * cy <= 0.09 * 0.09) return true;
      for (int k = 0; k < 4; k++) {
        final th = pi / 4 + k * pi / 2;
        final u = px * cos(th) + cy * sin(th);
        final v = -px * sin(th) + cy * cos(th);
        if (u > 0.08 && u < 0.60 && v.abs() <= 0.09) return true;
      }
      return false;
    }
    case 'tshirt': {
      if (px * px + pow(py + 0.45, 2) <= 0.12 * 0.12) return false;
      final torso = ax <= 0.42 && py > -0.20 && py < 0.70;
      final top = ay < 0.45 && py > -0.45 && py < -0.05 && ax <= 0.80 &&
          py >= -0.45 + 0.50 * max(0, ax - 0.42);
      return torso || top;
    }
    case 'mouse': {
      if (px * px + pow(py - 0.15, 2) <= 0.40 * 0.40) return true;
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.40, 2) + pow(py + 0.40, 2) <= 0.28 * 0.28) return true;
      }
      return false;
    }
    case 'lighthouse': {
      final inTower = py > -0.60 && py < 0.90 && ax <= 0.16 + 0.12 * (py + 0.60) / 1.50;
      if (inTower && ((py - 0.00).abs() <= 0.05 || (py - 0.40).abs() <= 0.05)) {
        return false; // stripes
      }
      if (inTower) return true;
      final house = ax <= 0.20 && py > -0.78 && py <= -0.60;
      final rays = py > -0.75 && py < -0.62 && ax > 0.28 && ax < 0.58;
      return house || rays;
    }
    case 'boot': {
      final shaft = px > -0.45 && px < 0.05 && py > -0.80 && py < 0.35;
      final foot = px > -0.45 && px < 0.55 && py >= 0.35 && py < 0.75;
      final toe = pow(px - 0.55, 2) + pow(py - 0.55, 2) <= 0.20 * 0.20;
      return shaft || foot || toe;
    }
    case 'chick': {
      final bodyCh = px * px + pow(py - 0.20, 2) <= 0.42 * 0.42;
      final headCh = px * px + pow(py + 0.35, 2) <= 0.30 * 0.30;
      final beakCh = px > 0.28 && px < 0.45 &&
          (py + 0.35).abs() <= 0.06 * (0.45 - px) / 0.17;
      return bodyCh || headCh || beakCh;
    }
    case 'cherry': {
      if (pow(px + 0.25, 2) + pow(py - 0.35, 2) <= 0.28 * 0.28) return true;
      if (pow(px - 0.30, 2) + pow(py - 0.45, 2) <= 0.26 * 0.26) return true;
      final stem1 = py > -0.55 && py < 0.10 &&
          (px - (-0.25 + 0.30 * (0.07 - py) / 0.62)).abs() <= 0.045;
      final stem2 = py > -0.55 && py < 0.22 &&
          (px - (0.30 - 0.25 * (0.20 - py) / 0.75)).abs() <= 0.045;
      final leafC = pow((px - 0.18) / 0.20, 2) + pow((py + 0.62) / 0.09, 2) <= 1;
      return stem1 || stem2 || leafC;
    }
    case 'lantern': {
      final frame = ax <= 0.35 && ay <= 0.50;
      final inner = ax <= 0.22 && ay <= 0.36 && py.abs() > 0.05;
      if (frame && !inner) return true;
      final cap = py > -0.70 && py <= -0.50 && ax <= 0.15 + 0.20 * (py + 0.70) / 0.20;
      final ringL = sqrt(px * px + pow(py + 0.80, 2));
      final hoop = ringL >= 0.06 && ringL <= 0.14;
      final baseL = ay > 0.50 && py < 0.65 && ax <= 0.30;
      return cap || hoop || baseL;
    }
    case 'serpent': {
      final bodySp = ay <= 0.80 && (px - 0.38 * sin(2.4 * py)).abs() <= 0.13;
      final headSp = pow(px + 0.357, 2) + pow(py + 0.80, 2) <= 0.16 * 0.16;
      return bodySp || headSp;
    }
    case 'acorn': {
      final cap = px * px + pow(py + 0.10, 2) <= 0.50 * 0.50 && py <= -0.10;
      final stemA = ax <= 0.05 && py > -0.70 && py <= -0.55;
      final nut = pow(px / 0.40, 2) + pow((py - 0.25) / 0.42, 2) <= 1 && py > -0.10;
      return cap || stemA || nut;
    }
    case 'dumbbell': {
      final bar = ay <= 0.09 && ax <= 0.55;
      final plate1 = (ax - 0.62).abs() <= 0.10 && ay <= 0.42;
      final plate2 = (ax - 0.82).abs() <= 0.08 && ay <= 0.30;
      return bar || plate1 || plate2;
    }
    case 'dino': {
      final bodyD = pow((px - 0.15) / 0.45, 2) + pow((py - 0.35) / 0.28, 2) <= 1;
      final neck = py > -0.75 && py < 0.35 &&
          (px + 0.38 - 0.10 * (py + 0.20)).abs() <= 0.10;
      final headD = pow(px + 0.45, 2) + pow(py + 0.75, 2) <= 0.13 * 0.13;
      final tailD = px > 0.55 && px < 0.90 &&
          (py - (0.35 - (px - 0.55) * 0.50)).abs() <= 0.08;
      final legsD = ((px - 0.02).abs() <= 0.08 || (px - 0.35).abs() <= 0.08) &&
          py > 0.55 && py < 0.85;
      return bodyD || neck || headD || tailD || legsD;
    }
    case 'shell': {
      final d = sqrt(px * px + pow(py - 0.70, 2));
      final angS = atan2(px, -(py - 0.70));
      if (d > 1.30 || angS.abs() > 0.85 || py < -0.62) return false;
      if (d > 0.35 && sin(angS * 9) > 0.72) return false; // grooves
      return true;
    }
    case 'flag': {
      final pole = px > -0.65 && px < -0.55 && ay <= 0.85;
      final cloth = px > -0.55 && py > -0.80 + 0.06 * sin(6 * px) &&
          py < -0.15 + 0.06 * sin(6 * px) &&
          px <= 0.65 - 0.08 * sin(5 * py + 2);
      return pole || cloth;
    }
    case 'ladybird': {
      final inBody = px * px + pow(py - 0.05, 2) <= 0.55 * 0.55;
      if (inBody) {
        if (ax <= 0.035 && py > -0.45) return false; // wing split
        for (final sp in [[-0.25, -0.05], [0.25, -0.05], [-0.20, 0.35], [0.20, 0.35]]) {
          if (pow(px - sp[0], 2) + pow(py - sp[1], 2) <= 0.10 * 0.10) return false;
        }
        return true;
      }
      return px * px + pow(py + 0.55, 2) <= 0.20 * 0.20;
    }
    case 'star8': {
      final ang = atan2(py, px);
      return r <= 0.45 + 0.45 * pow(cos(4 * ang).abs(), 1.5);
    }
    case 'kettlebell': {
      final ball = px * px + pow(py - 0.25, 2) <= 0.48 * 0.48;
      final hr = sqrt(px * px + pow(py + 0.30, 2));
      final handleK = hr >= 0.20 && hr <= 0.38 && py <= -0.25;
      return ball || handleK;
    }
    case 'spider': {
      final bodyS = px * px + pow(py - 0.05, 2) <= 0.30 * 0.30;
      final headS = px * px + pow(py + 0.40, 2) <= 0.18 * 0.18;
      if (bodyS || headS) return true;
      for (final m in [-0.9, -0.3, 0.3, 0.9]) {
        if (ax > 0.28 && ax < 0.85 && (py - m * (ax - 0.28)).abs() <= 0.05) {
          return true;
        }
      }
      return false;
    }
    case 'keyhole': {
      if (px * px + pow(py + 0.20, 2) <= 0.26 * 0.26) return false;
      if (py > -0.05 && py < 0.60 && ax <= 0.08 + 0.28 * (py + 0.05) / 0.65) {
        return false;
      }
      return r <= 0.85;
    }
    case 'question': {
      final qr = sqrt(px * px + pow(py + 0.30, 2));
      final hook = qr >= 0.22 && qr <= 0.42 && (px >= -0.05 || py <= -0.30);
      final stemQ = ax <= 0.10 && py > 0.05 && py < 0.38;
      final dot = px * px + pow(py - 0.62, 2) <= 0.12 * 0.12;
      return hook || stemQ || dot;
    }
    case 'dog': {
      final bodyDg = pow((px - 0.05) / 0.50, 2) + pow((py - 0.20) / 0.30, 2) <= 1;
      final headDg = pow(px + 0.50, 2) + pow(py + 0.20, 2) <= 0.25 * 0.25;
      final ear = (px + 0.62).abs() <= 0.08 && py > -0.50 && py < -0.20;
      final legsDg = ((px + 0.35).abs() <= 0.07 || (px + 0.12).abs() <= 0.07 ||
              (px - 0.18).abs() <= 0.07 || (px - 0.42).abs() <= 0.07) &&
          py > 0.45 && py < 0.80;
      final tailDg = px > 0.50 && px < 0.75 &&
          (py - (0.10 - (px - 0.50) * 1.2)).abs() <= 0.07;
      return bodyDg || headDg || ear || legsDg || tailDg;
    }
    case 'rings3': {
      for (int k = 0; k < 3; k++) {
        final th = -pi / 2 + k * 2 * pi / 3;
        final cx = 0.30 * cos(th), cy = 0.30 * sin(th);
        final rr = sqrt(pow(px - cx, 2) + pow(py - cy, 2));
        if (rr >= 0.18 && rr <= 0.34) return true;
      }
      return false;
    }
    case 'exclaim': {
      final bar = py > -0.85 && py < 0.30 && ax <= 0.16 - 0.06 * (py + 0.85) / 1.15;
      final dotE = px * px + pow(py - 0.60, 2) <= 0.14 * 0.14;
      return bar || dotE;
    }
    case 'bear': {
      if (px * px + pow(py - 0.05, 2) <= 0.60 * 0.60) return true;
      for (final s in [-1.0, 1.0]) {
        if (pow(px - s * 0.45, 2) + pow(py + 0.45, 2) <= 0.20 * 0.20) return true;
      }
      return false;
    }
    case 'wrench': {
      final u = (px + py) * 0.707;
      final v = (px - py) * 0.707;
      if (v.abs() <= 0.12 && u < -0.30) return false; // jaw slot
      final handleW = v.abs() <= 0.11 && u > -0.20 && u < 0.85;
      final headW = pow(px + 0.40, 2) + pow(py + 0.40, 2) <= 0.30 * 0.30;
      return handleW || headW;
    }
    case 'percent': {
      for (final s in [-1.0, 1.0]) {
        final cr = sqrt(pow(px - s * 0.40, 2) + pow(py - s * 0.40, 2));
        if (cr >= 0.10 && cr <= 0.26) return true;
      }
      return (0.8 * px + 0.6 * py).abs() <= 0.09 && r <= 0.85;
    }
    case 'crosshair': {
      if (r >= 0.50 && r <= 0.68) return true;
      if (r <= 0.14) return true;
      final ticks = (ax <= 0.08 && ay > 0.30 && ay < 0.92) ||
          (ay <= 0.08 && ax > 0.30 && ax < 0.92);
      return ticks;
    }
    case 'snowman': {
      if (px * px + pow(py - 0.50, 2) <= 0.36 * 0.36) return true;
      if (px * px + pow(py + 0.02, 2) <= 0.28 * 0.28) return true;
      if (px * px + pow(py + 0.45, 2) <= 0.20 * 0.20) return true;
      final hat = ax <= 0.22 && py > -0.78 && py < -0.58;
      final brim = ax <= 0.32 && (py + 0.58).abs() <= 0.04;
      if (hat || brim) return true;
      for (final s in [-1.0, 1.0]) {
        if (ax > 0.26 && ax < 0.68 &&
            (py - (-0.02 - s * 0 - 0.25 * (ax - 0.26) / 0.42)).abs() <= 0.045) {
          return true;
        }
      }
      return false;
    }
    case 'rook': {
      final bodyRk = ax <= 0.30 && py > -0.30 && py < 0.55;
      final crownTeeth = (((px + 1) * 5).floor() % 2 == 0);
      final crownRk = ax <= 0.42 && py > -0.62 && py <= -0.30 && crownTeeth;
      final collar = (py + 0.28).abs() <= 0.05 && ax <= 0.40;
      final baseRk = py >= 0.55 && py < 0.75 && ax <= 0.46;
      return bodyRk || crownRk || collar || baseRk;
    }
    // ---------- Fresh shapes for the recreated 51-100 band ----------
    case 'strawberry': {
      final top = pow(px / 0.60, 2) + pow((py + 0.05) / 0.34, 2) <= 1 && py <= 0.0;
      final bodyStr = py > -0.10 && py < 0.85 && ax <= 0.58 * (0.85 - py) / 0.95;
      for (final k in [-0.26, 0.0, 0.26]) {
        if (py > -0.62 && py < -0.20 &&
            (px - k).abs() <= 0.12 * (py + 0.62) / 0.42) {
          return true;
        }
      }
      final stemStr = ax <= 0.045 && py > -0.80 && py <= -0.55;
      return top || bodyStr || stemStr;
    }
    case 'pear': {
      if (px * px + pow(py - 0.30, 2) <= 0.45 * 0.45) return true;
      if (pow(px / 0.28, 2) + pow((py + 0.25) / 0.42, 2) <= 1) return true;
      return ax <= 0.05 && py > -0.85 && py <= -0.58;
    }
    case 'watermelon': {
      for (final sd in [[-0.30, 0.40], [0.0, 0.52], [0.30, 0.40]]) {
        if (pow(px - sd[0], 2) + pow(py - sd[1], 2) <= 0.07 * 0.07) return false;
      }
      return r <= 0.82 && py >= 0.05;
    }
    case 'pumpkin': {
      for (final k in [-0.30, 0.0, 0.30]) {
        if (pow((px - k) / 0.32, 2) + pow((py - 0.10) / 0.55, 2) <= 1) return true;
      }
      return ax <= 0.07 && py > -0.85 && py <= -0.58;
    }
    case 'candle': {
      final bodyCn = ax <= 0.22 && py > -0.25 && py < 0.80;
      final flameCn = pow(px / 0.14, 2) + pow((py + 0.52) / 0.28, 2) <= 1;
      final holder = ax <= 0.40 && py >= 0.80 && py < 0.92;
      return bodyCn || flameCn || holder;
    }
    case 'rainbow': {
      if (py > 0.35) return false;
      final rr = sqrt(px * px + pow(py - 0.35, 2));
      return (rr >= 0.35 && rr <= 0.50) ||
          (rr >= 0.58 && rr <= 0.73) ||
          (rr >= 0.80 && rr <= 0.95);
    }
    case 'tent': {
      if (ax <= 0.12 && py > 0.15 && py < 0.60) return false; // door
      final canvasT = py > -0.60 && py < 0.60 && ax <= 0.80 * (py + 0.60) / 1.20;
      final ground = py >= 0.60 && py < 0.72 && ax <= 0.90;
      return canvasT || ground;
    }
    case 'igloo': {
      final rr = sqrt(px * px + pow(py - 0.35, 2));
      if (rr <= 0.28 && py > 0.05) return false; // entrance
      final dome = rr <= 0.75 && py <= 0.35;
      final baseI = ax <= 0.75 && py > 0.35 && py < 0.50 &&
          !(ax <= 0.28); // entrance continues through the base
      return dome || baseI;
    }
    case 'sock': {
      final shaft = px > -0.35 && px < 0.15 && py > -0.80 && py < 0.20;
      final foot = px > -0.35 && px < 0.55 && py >= 0.20 && py < 0.60;
      final toe = pow(px - 0.55, 2) + pow(py - 0.40, 2) <= 0.20 * 0.20;
      final cuff = px > -0.42 && px < 0.22 && py > -0.92 && py <= -0.80;
      return shaft || foot || toe || cuff;
    }
    case 'mitten': {
      final hand = pow(px / 0.42, 2) + pow(py / 0.55, 2) <= 1 && py < 0.50;
      final thumb = pow(px + 0.48, 2) + pow(py + 0.10, 2) <= 0.19 * 0.19;
      final cuffM = ax <= 0.42 && py >= 0.50 && py < 0.75;
      return hand || thumb || cuffM;
    }
    default:
      return false;
  }
}

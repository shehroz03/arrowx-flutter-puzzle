// ignore_for_file: avoid_print
// Clean, competitor-beating designs for stages 21-30.
// Design rules: recognizable silhouettes, straight / single-bend arrows only,
// dense orderly packing, guaranteed solvable (reverse placement order).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const shapes = [
  'Heart', 'Light Bulb', 'Star', 'Butterfly', 'Rocket',
  'Flower', 'Fish', 'Crown', 'Diamond', 'Trophy'
];
const grids = [30, 30, 32, 32, 32, 32, 32, 32, 32, 34];

void main() {
  final file = File('assets/levels.json');
  final levels = List<Map<String, dynamic>>.from(jsonDecode(file.readAsStringSync()));
  levels.removeWhere((l) => l['level'] >= 21 && l['level'] <= 30);

  final previewDir = Directory('design_previews');
  if (!previewDir.existsSync()) previewDir.createSync();
  final htmlParts = StringBuffer();

  for (int stage = 21; stage <= 30; stage++) {
    final gs = grids[stage - 21];
    final shape = shapes[stage - 21];
    final rand = Random(stage * 7919); // deterministic per stage
    final mask = buildMask(stage, gs);
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

    // Try to commit a path (tail->head). Reverses it if head ray is blocked
    // but tail ray is clear. Returns true when placed.
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

    // Directions ordered by outward alignment from grid center, so exit
    // rays tend to pass through still-empty outer cells (higher density).
    List<List<int>> outwardDirs(int x, int y) {
      final vx = x + 0.5 - gs / 2, vy = y + 0.5 - gs / 2;
      final dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
      dirs.shuffle(rand);
      dirs.sort((a, b) =>
          (b[0] * vx + b[1] * vy).compareTo(a[0] * vx + a[1] * vy));
      return dirs;
    }

    List<List<int>>? walk(int sx, int sy, List<List<int>> legs) {
      // legs = list of [dx, dy, steps]
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

    // Cells sorted center-out: inner arrows are placed first pointing
    // outward through empty space, outer arrows layer on afterwards.
    // Reverse placement order is always a valid solve order.
    double rOf(String c) {
      final p = c.split(',');
      final dx = int.parse(p[0]) + 0.5 - gs / 2;
      final dy = int.parse(p[1]) + 0.5 - gs / 2;
      return dx * dx + dy * dy;
    }
    final ordered = maskList.toList()
      ..shuffle(rand)
      ..sort((a, b) => rOf(a).compareTo(rOf(b)));

    // Phase 1: dense fill with straight (60%) and L-shaped (40%) arrows.
    for (int pass = 0; pass < 6; pass++) {
      for (final cell in ordered) {
        final pt = cell.split(',');
        final sx = int.parse(pt[0]), sy = int.parse(pt[1]);
        if (!free(sx, sy)) continue;
        for (final d1 in outwardDirs(sx, sy)) {
          List<List<int>> legs;
          if (rand.nextDouble() < 0.60) {
            legs = [[d1[0], d1[1], 3 + rand.nextInt(6)]]; // straight 4-9 cells
          } else {
            // L-shape: one crisp 90-degree bend
            final turn = rand.nextBool() ? 1 : -1;
            final d2 = [-d1[1] * turn, d1[0] * turn];
            legs = [
              [d1[0], d1[1], 2 + rand.nextInt(4)],
              [d2[0], d2[1], 2 + rand.nextInt(4)],
            ];
          }
          final path = walk(sx, sy, legs);
          if (path != null && path.length >= 3 && commit(path)) break;
        }
      }
    }

    // Phase 2: tidy gap fill with short straights (len 3 then 2).
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

    final fill = (occupied.length * 100 / mask.length).toStringAsFixed(1);
    print('Stage $stage [$shape] grid $gs: ${arrows.length} arrows, $fill% fill');

    levels.add({
      'level': stage,
      'gridSize': gs,
      'shapeName': shape,
      'isHardStage': stage % 5 == 0,
      'arrows': arrows,
    });

    final svg = renderSvg(gs, arrows);
    File('design_previews/level_$stage.svg').writeAsStringSync(svg);
    htmlParts.write(
        '<div class="card"><h2>Level $stage — $shape <span>${arrows.length} arrows</span></h2>$svg</div>');
  }

  levels.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(levels));

  File('design_previews/all_levels.html').writeAsStringSync('''
<!DOCTYPE html><html><head><meta charset="utf-8"><title>Levels 21-30 Redesign</title>
<style>body{background:#F5ECDC;font-family:Georgia,serif;color:#5A4632;margin:24px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:24px}
.card{background:#FBF5E9;border-radius:16px;padding:16px;box-shadow:0 4px 14px rgba(90,70,50,.15)}
.card h2{margin:0 0 10px;font-size:20px}.card h2 span{font-size:13px;color:#A08B6F;font-weight:normal}
svg{width:100%;height:auto;display:block}</style></head>
<body><h1>Arrow Game — Stages 21-30 Clean Redesign</h1><div class="grid">$htmlParts</div></body></html>''');
  print('Done. Preview: design_previews/all_levels.html');
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

Set<String> buildMask(int stage, int gs) {
  final mask = <String>{};
  final mid = gs / 2;
  for (int y = 0; y < gs; y++) {
    for (int x = 0; x < gs; x++) {
      final px = (x + 0.5 - mid) / (gs / 2); // -1..1
      final py = (y + 0.5 - mid) / (gs / 2);
      if (inShape(stage, px, py)) mask.add('$x,$y');
    }
  }
  return mask;
}

bool inShape(int stage, double px, double py) {
  final ax = px.abs();
  switch (stage) {
    case 21: // Heart: two lobes + tapering point
      final lobe = (ax - 0.32) * (ax - 0.32) + (py + 0.28) * (py + 0.28) <= 0.40 * 0.40;
      final body = py > -0.28 && py < 0.88 && ax <= 0.70 * (0.88 - py) / 1.16;
      return lobe || body;
    case 22: // Light Bulb: globe + neck + two detached base bands
      final globe = px * px + (py + 0.30) * (py + 0.30) <= 0.52 * 0.52;
      final neck = ax <= 0.20 && py > 0.10 && py < 0.44;
      final band1 = ax <= 0.28 && py > 0.50 && py < 0.62;
      final band2 = ax <= 0.28 && py > 0.68 && py < 0.80;
      return globe || neck || band1 || band2;
    case 23: // 5-point Star (pointing up)
      final r = sqrt(px * px + py * py);
      var phi = atan2(px, -py); // 0 = up
      const alpha = 2 * pi / 5;
      var u = (phi % alpha) / alpha;
      if (u < 0) u += 1;
      final tri = 1 - (1 - 2 * u).abs(); // 0 at points, 1 mid-edge
      return r <= 0.95 + (0.40 - 0.95) * tri;
    case 24: // Butterfly: 4 wing lobes + body
      final topW = pow((ax - 0.40) / 0.40, 2) + pow((py + 0.28) / 0.36, 2) <= 1;
      final botW = pow((ax - 0.30) / 0.32, 2) + pow((py - 0.30) / 0.30, 2) <= 1;
      final body = ax <= 0.07 && py.abs() <= 0.62;
      return topW || botW || body;
    case 25: // Rocket: nose + body + fins + flame
      final nose = py > -0.92 && py < -0.42 && ax <= 0.30 * (py + 0.92) / 0.5;
      final bodyR = ax <= 0.28 && py > -0.42 && py < 0.42;
      final fins = py > 0.05 && py < 0.50 && ax <= 0.28 + 0.30 * (py - 0.05) / 0.45;
      final flame = py > 0.52 && py < 0.90 && ax <= 0.18 * (0.90 - py) / 0.38;
      return nose || bodyR || fins || flame;
    case 26: // Flower: 6 petals + core
      final r = sqrt(px * px + py * py);
      if (r <= 0.26) return true;
      for (int k = 0; k < 6; k++) {
        final th = k * pi / 3 + pi / 6;
        final u = px * cos(th) + py * sin(th);
        final v = -px * sin(th) + py * cos(th);
        if (pow((u - 0.55) / 0.36, 2) + pow(v / 0.21, 2) <= 1) return true;
      }
      return false;
    case 27: // Fish (facing left): body ellipse + tail fin
      final body = pow((px + 0.18) / 0.55, 2) + pow(py / 0.34, 2) <= 1;
      final tail = px > 0.30 && px < 0.80 && py.abs() <= 0.52 * (px - 0.30) / 0.50;
      return body || tail;
    case 28: // Crown: band + three spikes
      final band = py > 0.28 && py < 0.72 && ax <= 0.78;
      for (final cx in [-0.56, 0.0, 0.56]) {
        if (py > -0.78 && py <= 0.28 &&
            (px - cx).abs() <= 0.26 * (py + 0.78) / 1.06) {
          return true;
        }
      }
      return band;
    case 29: // Diamond gem: crown trapezoid + pavilion
      final top = py > -0.60 && py <= -0.18 && ax <= 0.42 + 0.44 * (py + 0.60) / 0.42;
      final bottom = py > -0.18 && py < 0.82 && ax <= 0.86 * (0.82 - py) / 1.0;
      return top || bottom;
    case 30: // Trophy: cup + handles + stem + two-tier base
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
    default:
      return false;
  }
}

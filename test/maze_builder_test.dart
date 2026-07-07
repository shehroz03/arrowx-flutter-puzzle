import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_game/maze_builder.dart';

void main() {
  // In the test environment text renders with the solid-block Ahem font,
  // which still exercises the full rasterize -> fill -> solvability pipeline.
  test('buildNameMaze produces a solvable maze from a name', () async {
    final result = await buildNameMaze('ALI');
    expect(result, isNotNull);
    expect(result!.arrows.length, greaterThan(10));
    expect(result.mask.length, greaterThan(50));

    // No two arrows may overlap.
    final seen = <String>{};
    for (final a in result.arrows) {
      for (final p in a.path) {
        final key = '${p[0]},${p[1]}';
        expect(seen.contains(key), isFalse, reason: 'overlap at $key');
        seen.add(key);
      }
    }
  });

  test('buildNameMaze rejects empty input', () async {
    expect(await buildNameMaze('   '), isNull);
  });
}

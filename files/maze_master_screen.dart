// ─────────────────────────────────────────────────────────────
// MAZE MASTER — 30 levels arrow maze
// Navigator.push(context, MaterialPageRoute(builder: (_) => const MazeMasterScreen()));
// ─────────────────────────────────────────────────────────────
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kP  = Color(0xFF7C3AED);
const _kP2 = Color(0xFFA78BFA);
const _kBg = Color(0xFFF5F3FF);

// Maze cell walls: bit flags N=1 S=2 E=4 W=8
class _MazeGen {
  static List<List<int>> generate(int rows, int cols, int seed) {
    final rng = Random(seed);
    final walls = List.generate(rows, (_) => List.filled(cols, 15)); // all walls
    final visited = List.generate(rows, (_) => List.filled(cols, false));

    void carve(int r, int c) {
      visited[r][c] = true;
      final dirs = [0, 1, 2, 3]..shuffle(rng);
      for (final d in dirs) {
        final nr = r + [-1, 1, 0, 0][d];
        final nc = c + [0, 0, 1, -1][d];
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && !visited[nr][nc]) {
          // Remove wall between (r,c) and (nr,nc)
          // d=0:N, 1:S, 2:E, 3:W
          walls[r][c]  &= ~[1, 2, 4, 8][d];
          walls[nr][nc] &= ~[2, 1, 8, 4][d];
          carve(nr, nc);
        }
      }
    }
    carve(0, 0);
    return walls;
  }
}

class MazeMasterScreen extends StatefulWidget {
  const MazeMasterScreen({super.key});
  @override State<MazeMasterScreen> createState() => _MazeMasterState();
}

class _MazeMasterState extends State<MazeMasterScreen> {
  int _currentLevel = 0;
  List<int> _unlockedLevels = [0];
  final Map<int, int> _levelStars = {};
  String _screen = 'menu';

  late List<List<int>> _maze;
  late int _rows, _cols;
  int _pr = 0, _pc = 0; // player pos
  int _moves = 0;
  bool _won = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final unlocked = p.getInt('mm_unlocked') ?? 0;
    final starsStr = p.getString('mm_stars') ?? '{}';
    // unused starsMap removed
    try {
      final decoded = starsStr.split(',').where((s) => s.contains(':'));
      for (final kv in decoded) {
        final parts = kv.split(':');
        if (parts.length == 2) _levelStars[int.tryParse(parts[0]) ?? 0] = int.tryParse(parts[1]) ?? 0;
      }
    } catch (_) {}
    setState(() => _unlockedLevels = List.generate(min(30, unlocked + 1), (i) => i));
  }

  Future<void> _saveProgress(int level, int stars) async {
    final p = await SharedPreferences.getInstance();
    final maxUnlocked = max(_unlockedLevels.length, level + 2);
    await p.setInt('mm_unlocked', maxUnlocked - 1);
    if ((_levelStars[level] ?? 0) < stars) {
      _levelStars[level] = stars;
      await p.setString('mm_stars', _levelStars.entries.map((e) => '${e.key}:${e.value}').join(','));
    }
    setState(() => _unlockedLevels = List.generate(min(30, maxUnlocked), (i) => i));
  }

  void _startLevel(int level) {
    final size = level < 5 ? 5 : level < 10 ? 6 : level < 18 ? 7 : level < 25 ? 8 : 9;
    setState(() {
      _currentLevel = level;
      _rows = size; _cols = size;
      _maze = _MazeGen.generate(size, size, level * 137 + 42);
      _pr = 0; _pc = 0; _moves = 0; _won = false; _screen = 'game';
    });
  }

  void _move(int dr, int dc) {
    if (_won) return;
    final nr = _pr + dr, nc = _pc + dc;
    if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) return;
    // Check wall
    final wallBit = dr == -1 ? 1 : dr == 1 ? 2 : dc == 1 ? 4 : 8;
    if (_maze[_pr][_pc] & wallBit != 0) return; // wall present
    setState(() {
      _pr = nr; _pc = nc; _moves++;
      if (_pr == _rows - 1 && _pc == _cols - 1) {
        _won = true;
        final size = _rows;
        final perfect = size * size - 1;
        final stars = _moves <= perfect ? 3 : _moves <= perfect * 1.5 ? 2 : 1;
        _saveProgress(_currentLevel, stars);
      }
    });
  }

  int _starsForMoves() {
    final perfect = _rows * _rows - 1;
    return _moves <= perfect ? 3 : _moves <= perfect * 1.5 ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg, body: SafeArea(child: switch (_screen) {
      'game' => _buildGame(),
      _      => _buildMenu(),
    }));
  }

  Widget _buildMenu() {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back, color: Color(0xFF1a1a2e)))),
        const SizedBox(width: 12),
        const Text('Maze Master', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e))),
      ])),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: 30,
        itemBuilder: (_, i) {
          final unlocked = _unlockedLevels.contains(i);
          final stars = _levelStars[i] ?? 0;
          return GestureDetector(
            onTap: unlocked ? () => _startLevel(i) : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: unlocked ? const LinearGradient(colors: [_kP, _kP2], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: unlocked ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: unlocked ? [BoxShadow(color: _kP.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(unlocked ? '${i + 1}' : '🔒', style: TextStyle(fontWeight: FontWeight.w800, fontSize: unlocked ? 16 : 14,
                    color: unlocked ? Colors.white : Colors.grey)),
                if (unlocked && stars > 0) Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (s) => Icon(s < stars ? Icons.star : Icons.star_border, size: 8,
                      color: s < stars ? Colors.yellow[300] : Colors.white54))),
              ]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildGame() {
    final cellSize = (MediaQuery.of(context).size.width - 48) / _cols;
    return Column(children: [
      // Header
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(onTap: () => setState(() => _screen = 'menu'),
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back, color: Color(0xFF1a1a2e)))),
        Column(children: [
          Text('Level ${_currentLevel + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1a1a2e))),
          Text('Moves: $_moves', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        GestureDetector(onTap: () => _startLevel(_currentLevel),
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.refresh, color: Color(0xFF1a1a2e)))),
      ])),

      // Maze
      Expanded(child: Center(child: _won ? _wonCard() : Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 20)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(_rows, (r) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_cols, (c) {
            final isPlayer = r == _pr && c == _pc;
            final isExit   = r == _rows - 1 && c == _cols - 1;
            final walls    = _maze[r][c];
            return Container(
              width: cellSize, height: cellSize,
              decoration: BoxDecoration(
                color: isPlayer ? _kP.withValues(alpha: .15) : isExit ? Colors.green.withValues(alpha: .15) : Colors.white,
                border: Border(
                  top:    walls & 1 != 0 ? BorderSide(color: _kP.withValues(alpha: .6), width: 1.5) : BorderSide.none,
                  bottom: walls & 2 != 0 ? BorderSide(color: _kP.withValues(alpha: .6), width: 1.5) : BorderSide.none,
                  right:  walls & 4 != 0 ? BorderSide(color: _kP.withValues(alpha: .6), width: 1.5) : BorderSide.none,
                  left:   walls & 8 != 0 ? BorderSide(color: _kP.withValues(alpha: .6), width: 1.5) : BorderSide.none,
                ),
              ),
              child: Center(child: isPlayer ? Container(width: cellSize * .55, height: cellSize * .55,
                decoration: BoxDecoration(color: _kP, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _kP.withValues(alpha: .4), blurRadius: 6)]))
                : isExit ? const Text('🏁', style: TextStyle(fontSize: 12)) : null),
            );
          }),
        ))),
      ))),

      // Controls
      if (!_won) Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(children: [
        _ctrlBtn(Icons.keyboard_arrow_up, () => _move(-1, 0)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ctrlBtn(Icons.keyboard_arrow_left,  () => _move(0, -1)),
          const SizedBox(width: 60),
          _ctrlBtn(Icons.keyboard_arrow_right, () => _move(0, 1)),
        ]),
        _ctrlBtn(Icons.keyboard_arrow_down, () => _move(1, 0)),
      ])),
    ]);
  }

  Widget _ctrlBtn(IconData ic, VoidCallback fn) => GestureDetector(onTap: fn, child: Container(
    margin: const EdgeInsets.all(4), width: 56, height: 56,
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2]), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: _kP.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4))]),
    child: Icon(ic, color: Colors.white, size: 28)));

  Widget _wonCard() {
    final stars = _starsForMoves();
    return Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 20)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 8),
        const Text('Level Complete!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1a1a2e))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(
          i < stars ? Icons.star : Icons.star_border, color: i < stars ? Colors.amber : Colors.grey[300], size: 36))),
        const SizedBox(height: 8),
        Text('$_moves moves', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _startLevel(_currentLevel), child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: _kP.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Retry', style: TextStyle(color: _kP, fontWeight: FontWeight.w700)))))),
          const SizedBox(width: 10),
          if (_currentLevel < 29) Expanded(child: GestureDetector(
            onTap: () => _startLevel(_currentLevel + 1),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2]), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Next →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))))),
        ]),
      ]));
  }
}

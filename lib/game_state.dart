import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_data.dart';
import 'package:flutter/foundation.dart';
import 'sound_manager.dart';
import 'editor_provider.dart';

class ArrowModel {
  final int id;
  final List<List<int>> path; // Ordered [x,y] grid coordinates from tail→head
  final bool arrowAtEnd;      // true = arrowhead at path.last
  final bool isSolved;
  final bool hasError;

  ArrowModel({
    required this.id,
    required this.path,
    this.arrowAtEnd = true,
    this.isSolved = false,
    this.hasError = false,
  });

  int get length => path.length;

  /// Arrowhead point (the triangle tip)
  List<int> get arrowheadPoint => arrowAtEnd ? path.last : path.first;

  /// Tail point (the perpendicular bar end)
  List<int> get tailPoint => arrowAtEnd ? path.first : path.last;

  /// Fly direction — unit vector from arrowhead's predecessor to arrowhead
  List<int> get flyDirection {
    if (path.length < 2) return [0, -1];
    List<int> head, prev;
    if (arrowAtEnd) {
      head = path.last;
      prev = path[path.length - 2];
    } else {
      head = path.first;
      prev = path[1];
    }
    return [(head[0] - prev[0]).sign, (head[1] - prev[1]).sign];
  }

  /// All grid cells this arrow occupies as "x,y" strings for fast lookup
  Set<String> get occupiedCells => path.map((p) => '${p[0]},${p[1]}').toSet();

  /// Bounding box [minX, minY, maxX, maxY]
  List<int> get bounds {
    int mnX = path.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
    int mnY = path.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
    int mxX = path.map((p) => p[0]).reduce((a, b) => a > b ? a : b);
    int mxY = path.map((p) => p[1]).reduce((a, b) => a > b ? a : b);
    return [mnX, mnY, mxX, mxY];
  }

  ArrowModel copyWith({List<List<int>>? path, bool? isSolved, bool? hasError}) {
    return ArrowModel(
      id: id,
      path: path ?? this.path,
      arrowAtEnd: arrowAtEnd,
      isSolved: isSolved ?? this.isSolved,
      hasError: hasError ?? this.hasError,
    );
  }
}

class GameState {
  final int level;
  final int chances;
  final int points;
  final List<ArrowModel> arrows;
  final bool gameOver;
  final int gridSize;
  final bool isLevelComplete;
  final int totalTimeSeconds;
  final int timeRemainingSeconds;
  final int earnedStars;
  final bool outOfTime;

  GameState({
    this.level = 1,
    this.chances = 3,
    this.points = 0,
    this.arrows = const [],
    this.gameOver = false,
    this.gridSize = 12,
    this.isLevelComplete = false,
    this.totalTimeSeconds = 60,
    this.timeRemainingSeconds = 60,
    this.earnedStars = 0,
    this.outOfTime = false,
  });

  GameState copyWith({
    int? level, int? chances, int? points,
    List<ArrowModel>? arrows, bool? gameOver, int? gridSize,
    bool? isLevelComplete,
    int? totalTimeSeconds,
    int? timeRemainingSeconds,
    int? earnedStars,
    bool? outOfTime,
  }) {
    return GameState(
      level: level ?? this.level,
      chances: chances ?? this.chances,
      points: points ?? this.points,
      arrows: arrows ?? this.arrows,
      gameOver: gameOver ?? this.gameOver,
      gridSize: gridSize ?? this.gridSize,
      isLevelComplete: isLevelComplete ?? this.isLevelComplete,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      earnedStars: earnedStars ?? this.earnedStars,
      outOfTime: outOfTime ?? this.outOfTime,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  bool _isProcessingTap = false; // Guard against rapid-tap race conditions
  Timer? _levelTimer;

  GameNotifier() : super(GameState()) {
    _initGame();
  }

  Future<void> _initGame() async {
    await EditorNotifier.loadCustomLevels();
    int lvl = await GameDataManager.loadPlayingLevel();
    await loadLevel(lvl);
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    super.dispose();
  }

  /// Generate straight path from shorthand (sx, sy, dir, len)
  static List<List<int>> _genPath(int sx, int sy, String dir, int len) {
    int dx = 0, dy = 0;
    switch (dir) {
      case 'right': dx = 1; break;
      case 'left': dx = -1; break;
      case 'down': dy = 1; break;
      case 'up': dy = -1; break;
    }
    return List.generate(len, (i) => [sx + dx * i, sy + dy * i]);
  }

  Future<void> loadLevel(int targetLevel) async {
    try {
      dynamic levelData;
      if (targetLevel >= 100) {
        levelData = EditorNotifier.savedLevels.cast<dynamic>().firstWhere(
          (lvl) => lvl['level'] == targetLevel,
          orElse: () => EditorNotifier.savedLevels.isNotEmpty ? EditorNotifier.savedLevels.first : null,
        );
      }

      if (levelData == null) {
        final String response = await rootBundle.loadString('assets/levels.json');
        final List<dynamic> data = json.decode(response);
        levelData = data.firstWhere(
          (lvl) => lvl['level'] == targetLevel,
          orElse: () => data.first,
        );
      }

      final List<ArrowModel> parsed = (levelData['arrows'] as List).map((a) {
        List<List<int>> arrowPath;

        if (a.containsKey('path')) {
          // Direct path-segment format: [[x1,y1],[x2,y2],...]
          arrowPath = (a['path'] as List).map((pt) {
            final p = pt as List;
            return [(p[0] as num).toInt(), (p[1] as num).toInt()];
          }).toList();
        } else {
          // Shorthand format: sx, sy, dir, len
          arrowPath = _genPath(
            (a['sx'] as num).toInt(), (a['sy'] as num).toInt(),
            a['dir'] as String, (a['len'] as num).toInt(),
          );
        }

        return ArrowModel(
          id: (a['id'] as num).toInt(),
          path: arrowPath,
          arrowAtEnd: (a['arrowhead'] ?? 'last') == 'last',
        );
      }).toList();

      int gs = (levelData['gridSize'] as num?)?.toInt() ?? 12;
      int tLvl = (levelData['level'] as num).toInt();
      
      // PERSISTENCE: Save playing stage so user returns here if app closes
      GameDataManager.savePlayingLevel(tLvl);

      state = state.copyWith(
        level: tLvl,
        arrows: parsed, chances: 3, gameOver: false, gridSize: gs,
        isLevelComplete: false,
      );
      _isProcessingTap = false;
      _startTimer(tLvl);

      // Validate solvability after loading
      _validateSolvability();
    } catch (e) {
      debugPrint("JSON Load Error: $e");
    }
  }

  void onArrowTapped(ArrowModel tappedArrow) {
    if (state.gameOver || tappedArrow.isSolved || _isProcessingTap) return;
    _isProcessingTap = true;

    HapticFeedback.lightImpact();
    SoundManager().playTap();

    if (_checkCollision(tappedArrow)) {
      // BLOCKED — red flash + lose chance
      HapticFeedback.heavyImpact();
      SoundManager().playError();
      int newChances = state.chances - 1;
      final tid = tappedArrow.id;
      state = state.copyWith(
        chances: newChances, gameOver: newChances <= 0,
        arrows: state.arrows.map((a) => a.id == tid ? a.copyWith(hasError: true) : a).toList(),
      );
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        state = state.copyWith(
          arrows: state.arrows.map((a) => a.id == tid ? a.copyWith(hasError: false) : a).toList(),
        );
        _isProcessingTap = false;
      });
    } else {
      // CLEAR — fly out
      SoundManager().playClear();
      state = state.copyWith(
        points: state.points + 10,
        arrows: state.arrows.map((a) =>
          a.id == tappedArrow.id ? a.copyWith(isSolved: true) : a
        ).toList(),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final remaining = state.arrows.where((a) => !a.isSolved).toList();
        if (remaining.isEmpty) {
          SoundManager().playLevelComplete();
          int stars = 1;
          if (state.totalTimeSeconds > 0) {
            double ratio = state.timeRemainingSeconds / state.totalTimeSeconds;
            if (ratio >= 0.8) {
              stars = 3;
            } else if (ratio >= 0.6) {
              stars = 2;
            }
          }
          state = state.copyWith(isLevelComplete: true, earnedStars: stars);
          int next = state.level + 1;
          GameDataManager.saveProgress(next, state.points);
          // Auto advance after 2.5 seconds of animation
          Future.delayed(const Duration(milliseconds: 2500), () => loadLevel(next));
        } else {
          state = state.copyWith(arrows: remaining);
        }
        _isProcessingTap = false;
      });
    }
  }

  /// Segment-to-segment collision: ray-cast from arrowhead in fly direction,
  /// checking every cell against all other unsolved arrows' occupied cells.
  bool _checkCollision(ArrowModel tapped) {
    Set<String> blocked = {};
    for (var other in state.arrows) {
      if (other.id == tapped.id || other.isSolved) continue;
      blocked.addAll(other.occupiedCells);
    }

    final dir = tapped.flyDirection;
    final head = tapped.arrowheadPoint;
    int x = head[0] + dir[0];
    int y = head[1] + dir[1];
    int gs = state.gridSize;

    while (x >= 0 && x < gs && y >= 0 && y < gs) {
      if (blocked.contains('$x,$y')) return true;
      x += dir[0];
      y += dir[1];
    }
    return false;
  }

  /// Load a custom level from the editor (for Test Play)
  void loadCustomLevel(List<ArrowModel> arrows, int gridSize) {
    state = state.copyWith(
      level: 99,
      arrows: arrows.map((a) => ArrowModel(
        id: a.id,
        path: List<List<int>>.from(a.path.map((p) => List<int>.from(p))),
        arrowAtEnd: a.arrowAtEnd,
      )).toList(),
      chances: 3,
      gameOver: false,
      gridSize: gridSize,
      isLevelComplete: false,
    );
    _isProcessingTap = false;
    _validateSolvability();
  }

  void tryAgain() => loadLevel(state.level);

  void _startTimer(int level) {
    _levelTimer?.cancel();
    // Example logical timer: 60s for level 1, +30s per level, max 300s
    int totalSecs = (level <= 5) ? 60 + (level - 1) * 30 : 180 + (level - 5) * 20;
    if (totalSecs > 300) totalSecs = 300;
    // For custom test levels (level 99)
    if (level == 99) totalSecs = 300;

    state = state.copyWith(
      totalTimeSeconds: totalSecs,
      timeRemainingSeconds: totalSecs,
      outOfTime: false,
    );

    _levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || state.gameOver || state.isLevelComplete) {
        timer.cancel();
        return;
      }
      final rem = state.timeRemainingSeconds - 1;
      if (rem <= 0) {
        timer.cancel();
        state = state.copyWith(timeRemainingSeconds: 0, gameOver: true, outOfTime: true);
      } else {
        state = state.copyWith(timeRemainingSeconds: rem);
      }
    });
  }

  /// Validates that at least one arrow has a clear flight path.
  /// Logs WHICH arrows are free for easy debugging.
  void _validateSolvability() {
    final unsolved = state.arrows.where((a) => !a.isSolved).toList();
    List<int> freeIds = [];

    for (var arrow in unsolved) {
      if (!_checkCollisionFor(arrow, unsolved)) {
        freeIds.add(arrow.id);
      }
    }

    if (freeIds.isEmpty && unsolved.isNotEmpty) {
      debugPrint('⚠️ SOLVABILITY WARNING: Level ${state.level} has NO free arrows! (${unsolved.length} total)');
    } else {
      debugPrint('✅ Level ${state.level}: ${freeIds.length} free arrows $freeIds out of ${unsolved.length}');
    }
  }

  /// Collision check against a specific list of arrows (for solvability validation)
  bool _checkCollisionFor(ArrowModel target, List<ArrowModel> arrowList) {
    Set<String> blocked = {};
    for (var other in arrowList) {
      if (other.id == target.id) continue;
      blocked.addAll(other.occupiedCells);
    }

    final dir = target.flyDirection;
    final head = target.arrowheadPoint;
    int x = head[0] + dir[0];
    int y = head[1] + dir[1];
    int gs = state.gridSize;

    while (x >= 0 && x < gs && y >= 0 && y < gs) {
      if (blocked.contains('$x,$y')) return true;
      x += dir[0];
      y += dir[1];
    }
    return false;
  }
}

final gameStateProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

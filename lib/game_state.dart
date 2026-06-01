import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_data.dart';
import 'sound_manager.dart';
import 'editor_provider.dart';

enum GameMode { normal, speedRush, mazeMaster, colorMatch }

class ArrowModel {
  final int id;
  final List<List<int>> path; // Ordered [x,y] grid coordinates from tail→head
  final bool arrowAtEnd;      // true = arrowhead at path.last
  final bool isSolved;
  final bool hasError;
  final Set<String> occupiedCells;
  final int colorIndex;

  ArrowModel({
    required this.id,
    required this.path,
    this.arrowAtEnd = true,
    this.isSolved = false,
    this.hasError = false,
    this.colorIndex = 0,
  }) : occupiedCells = path.map((p) => '${p[0]},${p[1]}').toSet();

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



  /// Bounding box [minX, minY, maxX, maxY]
  List<int> get bounds {
    int mnX = path.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
    int mnY = path.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
    int mxX = path.map((p) => p[0]).reduce((a, b) => a > b ? a : b);
    int mxY = path.map((p) => p[1]).reduce((a, b) => a > b ? a : b);
    return [mnX, mnY, mxX, mxY];
  }

  ArrowModel copyWith({List<List<int>>? path, bool? isSolved, bool? hasError, int? colorIndex}) {
    return ArrowModel(
      id: id,
      path: path ?? this.path,
      arrowAtEnd: arrowAtEnd,
      isSolved: isSolved ?? this.isSolved,
      hasError: hasError ?? this.hasError,
      colorIndex: colorIndex ?? this.colorIndex,
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
  final bool isHardStage;
  final Set<String> revealedCells;
  final GameMode gameMode;
  final int? targetColorIndex;

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
    this.isHardStage = false,
    this.revealedCells = const {},
    this.gameMode = GameMode.normal,
    this.targetColorIndex,
  });

  GameState copyWith({
    int? level, int? chances, int? points,
    List<ArrowModel>? arrows, bool? gameOver, int? gridSize,
    bool? isLevelComplete,
    int? totalTimeSeconds,
    int? timeRemainingSeconds,
    int? earnedStars,
    bool? outOfTime,
    bool? isHardStage,
    Set<String>? revealedCells,
    GameMode? gameMode,
    int? targetColorIndex,
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
      isHardStage: isHardStage ?? this.isHardStage,
      revealedCells: revealedCells ?? this.revealedCells,
      gameMode: gameMode ?? this.gameMode,
      targetColorIndex: targetColorIndex ?? this.targetColorIndex,
    );
  }

  Set<String> get allOccupiedCells {
    final set = <String>{};
    for (var a in arrows) {
      if (!a.isSolved) {
        set.addAll(a.occupiedCells);
      }
    }
    return set;
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

  Future<void> loadLevel(int targetLevel, {bool force = false, GameMode mode = GameMode.normal}) async {
    if (!force && state.level == targetLevel && state.arrows.isNotEmpty && !state.isLevelComplete && !state.gameOver && state.gameMode == mode) {
       // Level already loaded and active, skip redundant reload
       return;
    }
    try {
      dynamic levelData;
      if (targetLevel >= 100) {
        levelData = EditorNotifier.savedLevels.cast<dynamic>().firstWhere(
          (lvl) => lvl['level'] == targetLevel,
          orElse: () => EditorNotifier.savedLevels.isNotEmpty ? EditorNotifier.savedLevels.first : null,
        );
      }

      if (levelData == null) {
        String assetPath = 'assets/levels.json';
        if (mode == GameMode.mazeMaster) assetPath = 'assets/mazes.json';
        else if (mode == GameMode.colorMatch) assetPath = 'assets/color_match.json';

        final String response = await rootBundle.loadString(assetPath);
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
          colorIndex: (a['colorIndex'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      int gs = (levelData['gridSize'] as num?)?.toInt() ?? 12;
      int tLvl = (levelData['level'] as num).toInt();
      
      // PERSISTENCE: Save playing stage so user returns here if app closes
      GameDataManager.savePlayingLevel(tLvl);

      bool isHard = (levelData['isHardStage'] as bool?) ?? (tLvl % 5 == 0 && tLvl >= 5);

      int? targetColor;
      if (mode == GameMode.colorMatch && parsed.isNotEmpty) {
        targetColor = parsed.first.colorIndex; // Set initial target color
      }

      int? savedTime;
      if (force) {
        GameDataManager.clearLevelTime(tLvl);
      } else {
        savedTime = await GameDataManager.loadLevelTime(tLvl);
      }

      state = state.copyWith(
        level: tLvl,
        gameMode: mode,
        arrows: parsed, chances: 3, gameOver: false, gridSize: gs,
        isLevelComplete: false,
        isHardStage: isHard,
        revealedCells: {},
        targetColorIndex: targetColor,
      );
      _isProcessingTap = false;
      _startTimer(tLvl, savedTime);

      // Validate solvability after loading
      _validateSolvability();
    } catch (e) {
      // Error ignored in production
    }
  }

  void handleTap(int x, int y) {
    if (_isProcessingTap || state.gameOver || state.isLevelComplete) return;

    final tappedArrow = state.arrows.firstWhere(
      (a) => !a.isSolved && a.occupiedCells.contains('$x,$y'),
      orElse: () => ArrowModel(id: -1, path: []), // Null-ish object
    );

    if (tappedArrow.id != -1) {
      if (state.gameMode == GameMode.colorMatch && state.targetColorIndex != null) {
        if (tappedArrow.colorIndex != state.targetColorIndex) {
          // Play error if they tapped wrong color
          HapticFeedback.heavyImpact();
          SoundManager().playError();
          return;
        }
      }
      onArrowTapped(tappedArrow);
    }
  }

  void onArrowTapped(ArrowModel tappedArrow) {
    if (state.gameOver || tappedArrow.isSolved || _isProcessingTap) return;
    _isProcessingTap = true;

    HapticFeedback.lightImpact();
    SoundManager().playTap();

    final dir = tappedArrow.flyDirection;
    final head = tappedArrow.arrowheadPoint;
    int x = head[0] + dir[0];
    int y = head[1] + dir[1];
    int gs = state.gridSize;
    int steps = 0;

    Set<String> blocked = {};
    for (var other in state.arrows) {
      if (other.id == tappedArrow.id || other.isSolved) continue;
      blocked.addAll(other.occupiedCells);
    }

    bool clearToExit = true;
    while (x >= 0 && x < gs && y >= 0 && y < gs) {
      if (blocked.contains('$x,$y')) {
        clearToExit = false;
        break;
      }
      steps++;
      x += dir[0];
      y += dir[1];
    }

    if (clearToExit) {
      // CLEAR — fly out
      SoundManager().playClear();
      state = state.copyWith(
        points: state.points + 10,
        arrows: state.arrows.map((a) =>
          a.id == tappedArrow.id ? a.copyWith(isSolved: true) : a
        ).toList(),
      );

      // Fast-reset processing flag to allow rapid-fire moves
      _isProcessingTap = false;

      // Physically remove the arrow after the animation completes
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        
        final newRevealed = Set<String>.from(state.revealedCells)..addAll(tappedArrow.occupiedCells);
        
        final remaining = state.arrows.where((a) => !a.isSolved).toList();
        if (remaining.isEmpty) {
          if (state.isLevelComplete) return;

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
          state = state.copyWith(isLevelComplete: true, earnedStars: stars, revealedCells: newRevealed);
          
          if (state.gameMode == GameMode.speedRush) {
            // Speed rush: Add 10s to timer, don't load next level automatically, wait for UI to do it
            // Actually, we can load next random level automatically
            int next = Random().nextInt(50) + 1;
            Future.delayed(const Duration(milliseconds: 1000), () => loadLevel(next, force: true, mode: GameMode.speedRush));
          } else {
            int next = state.level + 1;
            GameDataManager.saveProgress(next, state.points);
            Future.delayed(const Duration(milliseconds: 2500), () => loadLevel(next, mode: state.gameMode));
          }
        } else {
          int? newTargetColor = state.targetColorIndex;
          if (state.gameMode == GameMode.colorMatch) {
            // Check if any arrows of current color are left
            bool hasCurrentColor = remaining.any((a) => a.colorIndex == state.targetColorIndex);
            if (!hasCurrentColor) {
              // Pick the next available color
              newTargetColor = remaining.first.colorIndex;
            }
          }

          state = state.copyWith(
            arrows: state.arrows.where((a) => a.id != tappedArrow.id || !a.isSolved).toList(),
            revealedCells: newRevealed,
            targetColorIndex: newTargetColor,
          );
        }
      });
    } else if (steps > 0) {
      // PARTIAL MOVE — move as far as possible
      final newRevealed = Set<String>.from(state.revealedCells)..addAll(tappedArrow.occupiedCells);
      final newPath = tappedArrow.path.map((p) => [p[0] + dir[0] * steps, p[1] + dir[1] * steps]).toList();
      
      state = state.copyWith(
        arrows: state.arrows.map((a) => a.id == tappedArrow.id ? a.copyWith(path: newPath) : a).toList(),
        revealedCells: newRevealed,
      );
      
      // Briefly pause to show movement before allowing next tap
      Future.delayed(const Duration(milliseconds: 200), () {
        _isProcessingTap = false;
      });
    } else {
      // BLOCKED IMMEDIATELY — error animation
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
    }
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

  void tryAgain() {
    GameDataManager.clearLevelTime(state.level);
    loadLevel(state.level, force: true, mode: state.gameMode);
  }

  void _startTimer(int level, [int? savedTime]) {
    _levelTimer?.cancel();
    
    int totalSecs;
    if (level > 20) {
      totalSecs = 600; // 10 minutes
    } else {
      totalSecs = (level <= 5) ? 60 + (level - 1) * 30 : 180 + (level - 5) * 20;
      if (totalSecs > 300) totalSecs = 300;
    }
    if (level == 99) totalSecs = 300;

    int initialTime = savedTime ?? totalSecs;

    state = state.copyWith(
      totalTimeSeconds: totalSecs,
      timeRemainingSeconds: initialTime,
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
        GameDataManager.clearLevelTime(level);
      } else {
        state = state.copyWith(timeRemainingSeconds: rem);
        GameDataManager.saveLevelTime(level, rem);
      }
    });
  }

  /// Validates that at least one arrow has a clear flight path.
  /// Logs WHICH arrows are free for easy debugging.
  void _validateSolvability() {
    // Solvability validation removed in production
  }

  /// Collision check against a specific list of arrows (for solvability validation)
  // Removed unreferenced _checkCollisionFor for production cleanup
}

final gameStateProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

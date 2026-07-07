import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';

class EditorState {
  final int gridSize;
  final List<ArrowModel> arrows;
  final int? selectedArrowId;
  final String currentDirection;
  final bool isSolvable;
  final int nextId;

  EditorState({
    this.gridSize = 16,
    this.arrows = const [],
    this.selectedArrowId,
    this.currentDirection = 'right',
    this.isSolvable = true,
    this.nextId = 1,
  });

  EditorState copyWith({
    int? gridSize,
    List<ArrowModel>? arrows,
    int? selectedArrowId,
    bool clearSelection = false,
    String? currentDirection,
    bool? isSolvable,
    int? nextId,
  }) {
    return EditorState(
      gridSize: gridSize ?? this.gridSize,
      arrows: arrows ?? this.arrows,
      selectedArrowId: clearSelection ? null : (selectedArrowId ?? this.selectedArrowId),
      currentDirection: currentDirection ?? this.currentDirection,
      isSolvable: isSolvable ?? this.isSolvable,
      nextId: nextId ?? this.nextId,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  /// In-memory storage for custom levels (playable immediately)
  static final List<Map<String, dynamic>> _savedLevels = [];
  static List<Map<String, dynamic>> get savedLevels => _savedLevels;

  static Future<void> loadCustomLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('custom_levels');
    if (data != null) {
      final List decoded = json.decode(data);
      _savedLevels.clear();
      for (var d in decoded) {
        _savedLevels.add(d as Map<String, dynamic>);
      }
    }
  }

  static Future<void> _persistCustomLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_levels', json.encode(_savedLevels));
  }

  EditorNotifier() : super(EditorState());

  void setGridSize(int size) {
    final filtered = state.arrows.where((a) {
      return a.path.every((p) => p[0] < size && p[1] < size && p[0] >= 0 && p[1] >= 0);
    }).toList();
    state = state.copyWith(gridSize: size, arrows: filtered, clearSelection: true);
    _validateSolvability();
  }

  /// Tap on a dot — place new arrow or cycle existing
  void onDotTapped(int x, int y) {
    // Check if any arrow occupies this cell
    for (var arrow in state.arrows) {
      if (arrow.occupiedCells.contains('$x,$y')) {
        state = state.copyWith(selectedArrowId: arrow.id);
        cycleDirection(arrow.id);
        return;
      }
    }
    // No arrow here — place new one
    _addArrow(x, y);
  }

  void _addArrow(int x, int y) {
    final int defaultLen = 3;
    final path = _genPath(x, y, state.currentDirection, defaultLen, state.gridSize);
    if (path.isEmpty) return;

    // Reject if overlaps with any existing arrow
    final newCells = path.map((p) => '${p[0]},${p[1]}').toSet();
    for (var arrow in state.arrows) {
      if (arrow.occupiedCells.intersection(newCells).isNotEmpty) return;
    }

    final newArrow = ArrowModel(id: state.nextId, path: path, arrowAtEnd: true);
    state = state.copyWith(
      arrows: [...state.arrows, newArrow],
      nextId: state.nextId + 1,
      selectedArrowId: newArrow.id,
    );
    _validateSolvability();
  }

  void removeArrow(int id) {
    state = state.copyWith(
      arrows: state.arrows.where((a) => a.id != id).toList(),
      clearSelection: true,
    );
    _validateSolvability();
  }

  void cycleDirection(int id) {
    final arrow = state.arrows.firstWhere((a) => a.id == id, orElse: () => state.arrows.first);
    const dirs = ['right', 'down', 'left', 'up'];
    final dir = arrow.flyDirection;
    String cur;
    if (dir[0] == 1) {
      cur = 'right';
    } else if (dir[0] == -1) {
      cur = 'left';
    } else if (dir[1] == 1) {
      cur = 'down';
    } else {
      cur = 'up';
    }

    // Try each next direction until one fits without overlap
    for (int attempt = 1; attempt <= 4; attempt++) {
      String nextDir = dirs[(dirs.indexOf(cur) + attempt) % 4];
      final newPath = _genPath(arrow.path.first[0], arrow.path.first[1], nextDir, arrow.length, state.gridSize);
      if (newPath.isEmpty) continue;

      final newCells = newPath.map((p) => '${p[0]},${p[1]}').toSet();
      bool overlaps = false;
      for (var other in state.arrows) {
        if (other.id == id) {
          continue;
        }
        if (other.occupiedCells.intersection(newCells).isNotEmpty) { overlaps = true; break; }
      }
      if (overlaps) continue;

      state = state.copyWith(
        arrows: state.arrows.map((a) => a.id == id ? a.copyWith(path: newPath) : a).toList(),
        selectedArrowId: id,
      );
      _validateSolvability();
      return;
    }
  }

  void changeLength(int id, int newLen) {
    if (newLen < 2 || newLen > 15) return;
    final arrow = state.arrows.firstWhere((a) => a.id == id);
    final dir = arrow.flyDirection;
    String dirStr;
    if (dir[0] == 1) {
      dirStr = 'right';
    } else if (dir[0] == -1) {
      dirStr = 'left';
    } else if (dir[1] == 1) {
      dirStr = 'down';
    } else {
      dirStr = 'up';
    }

    final newPath = _genPath(arrow.path.first[0], arrow.path.first[1], dirStr, newLen, state.gridSize);
    if (newPath.isEmpty) return;

    final newCells = newPath.map((p) => '${p[0]},${p[1]}').toSet();
    for (var other in state.arrows) {
      if (other.id == id) continue;
      if (other.occupiedCells.intersection(newCells).isNotEmpty) return;
    }

    state = state.copyWith(
      arrows: state.arrows.map((a) => a.id == id ? a.copyWith(path: newPath) : a).toList(),
    );
    _validateSolvability();
  }

  void setCurrentDirection(String dir) {
    state = state.copyWith(currentDirection: dir);
  }

  void clearAll() {
    state = state.copyWith(arrows: [], nextId: 1, clearSelection: true, isSolvable: true);
  }

  /// Export current design as JSON — copies to clipboard & prints to console
  String exportJSON({int? levelNum}) {
    final int lvl = levelNum ?? (1000 + _savedLevels.length);
    final arrowsJson = state.arrows.map((a) {
      final start = a.path.first;
      final dir = a.flyDirection;
      String dirStr;
      if (dir[0] == 1) {
        dirStr = 'right';
      } else if (dir[0] == -1) {
        dirStr = 'left';
      } else if (dir[1] == 1) {
        dirStr = 'down';
      } else {
        dirStr = 'up';
      }
      return {'id': a.id, 'sx': start[0], 'sy': start[1], 'dir': dirStr, 'len': a.length};
    }).toList();

    final levelMap = {'level': lvl, 'gridSize': state.gridSize, 'arrows': arrowsJson};
    final jsonStr = const JsonEncoder.withIndent('  ').convert(levelMap);
    Clipboard.setData(ClipboardData(text: jsonStr));
    debugPrint('📋 EXPORTED LEVEL $lvl:\n$jsonStr');
    return jsonStr;
  }

  /// Save current design as a new playable level
  void saveAsNewLevel() {
    if (state.arrows.isEmpty) return;
    final int lvl = 1000 + _savedLevels.length;
    final arrowsJson = state.arrows.map((a) {
      final start = a.path.first;
      final dir = a.flyDirection;
      String dirStr;
      if (dir[0] == 1) {
        dirStr = 'right';
      } else if (dir[0] == -1) {
        dirStr = 'left';
      } else if (dir[1] == 1) {
        dirStr = 'down';
      } else {
        dirStr = 'up';
      }
      return {'id': a.id, 'sx': start[0], 'sy': start[1], 'dir': dirStr, 'len': a.length};
    }).toList();

    _savedLevels.add({'level': lvl, 'gridSize': state.gridSize, 'arrows': arrowsJson});
    _persistCustomLevels();
    debugPrint('💾 Saved as Level $lvl (${_savedLevels.length} custom levels total)');
  }

  // ── Solvability ──

  void _validateSolvability() {
    if (state.arrows.isEmpty) {
      state = state.copyWith(isSolvable: true);
      return;
    }
    bool anyFree = false;
    for (var arrow in state.arrows) {
      if (!_isBlocked(arrow)) {
        anyFree = true;
        break;
      }
    }
    state = state.copyWith(isSolvable: anyFree);
  }

  bool _isBlocked(ArrowModel target) {
    Set<String> blocked = {};
    for (var other in state.arrows) {
      if (other.id == target.id) {
        continue;
      }
      blocked.addAll(other.occupiedCells);
    }
    final dir = target.flyDirection;
    final head = target.arrowheadPoint;
    int x = head[0] + dir[0], y = head[1] + dir[1];
    int gs = state.gridSize;
    while (x >= 0 && x < gs && y >= 0 && y < gs) {
      if (blocked.contains('$x,$y')) return true;
      x += dir[0]; y += dir[1];
    }
    return false;
  }

  static List<List<int>> _genPath(int sx, int sy, String dir, int len, int gs) {
    int dx = 0, dy = 0;
    switch (dir) {
      case 'right': dx = 1; break;
      case 'left': dx = -1; break;
      case 'down': dy = 1; break;
      case 'up': dy = -1; break;
    }
    List<List<int>> path = [];
    for (int i = 0; i < len; i++) {
      int nx = sx + dx * i, ny = sy + dy * i;
      if (nx < 0 || nx >= gs || ny < 0 || ny >= gs) return [];
      path.add([nx, ny]);
    }
    return path;
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

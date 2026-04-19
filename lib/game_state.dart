import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameState {
  final int level;
  final int chances;
  final List<Offset> currentPath; // Grid coordinates (X=Col, Y=Row) store karega

  bool get isHardLevel => level % 5 == 0;

  GameState({
    this.level = 1, 
    this.chances = 3, 
    this.currentPath = const []
  });

  GameState copyWith({int? level, int? chances, List<Offset>? currentPath}) {
    return GameState(
      level: level ?? this.level,
      chances: chances ?? this.chances,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState());

  // Naya point add karne ka function (Diagonal blocked)
  void addPathPoint(int col, int row) {
    final newPoint = Offset(col.toDouble(), row.toDouble());
    
    // Agar path khali hai toh direct add kar do
    if (state.currentPath.isEmpty) {
      state = state.copyWith(currentPath: [...state.currentPath, newPoint]);
      return;
    }

    final lastPoint = state.currentPath.last;

    // Agar same cell par dubara touch update hua hai, toh ignore karo
    if (lastPoint == newPoint) return;

    // Sirf valid straight moves allow karne ki logic:
    // Ya toh Row change ho ya Column, dono aik sath nahi. Aur distance exactly 1 ho.
    final dx = (newPoint.dx - lastPoint.dx).abs();
    final dy = (newPoint.dy - lastPoint.dy).abs();

    if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
      // Valid move (Up, Down, Left, Right)
      state = state.copyWith(currentPath: [...state.currentPath, newPoint]);
    }
  }

  // Path ko clear karne ke liye (jab user touch chhor de ya ghalat draw kare)
  void clearPath() {
    state = state.copyWith(currentPath: []);
  }

  void decrementChance() {
    if (state.chances > 0) {
      state = state.copyWith(chances: state.chances - 1);
    }
  }

  void nextLevel() {
    state = state.copyWith(level: state.level + 1, chances: 3, currentPath: []);
  }
}

final gameStateProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

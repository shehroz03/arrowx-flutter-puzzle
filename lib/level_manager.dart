import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PuzzleLevel {
  final int id;
  final int rows;
  final int columns;
  final List<List<String>> grid;

  PuzzleLevel({
    required this.id,
    required this.rows,
    required this.columns,
    required this.grid,
  });

  factory PuzzleLevel.fromJson(Map<String, dynamic> json) {
    // 2D Array ko JSON se Flutter List mein convert karna
    var gridJson = json['grid'] as List;
    List<List<String>> parsedGrid = gridJson.map((row) {
      return (row as List).map((cell) => cell.toString()).toList();
    }).toList();

    return PuzzleLevel(
      id: json['id'],
      rows: json['rows'],
      columns: json['columns'],
      grid: parsedGrid,
    );
  }
}

class LevelManager {
  static List<PuzzleLevel> _levels = [];

  // Yeh function game start hone par aik dafa call hoga
  static Future<void> loadLevels() async {
    try {
      // JSON file read karein
      String jsonString = await rootBundle.loadString('assets/levels.json');
      Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      
      var levelsArray = jsonResponse['levels'] as List;
      _levels = levelsArray.map((levelJson) => PuzzleLevel.fromJson(levelJson)).toList();
      
      debugPrint("Success: ${_levels.length} levels loaded from JSON!");
    } catch (e) {
      debugPrint("Error loading levels: $e");
    }
  }

  // Kisi specific level ka data get karne ke liye
  static PuzzleLevel? getLevel(int levelId) {
    try {
      return _levels.firstWhere((lvl) => lvl.id == levelId);
    } catch (e) {
      return null; // Level nahi mila
    }
  }
}

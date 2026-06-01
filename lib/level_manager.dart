import 'dart:convert';
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
    // Convert 2D Array from JSON to Flutter List
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

  // This function is called once when the game starts
  static Future<void> loadLevels() async {
    try {
      // Read JSON file
      String jsonString = await rootBundle.loadString('assets/levels.json');
      Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      
      var levelsArray = jsonResponse['levels'] as List;
      _levels = levelsArray.map((levelJson) => PuzzleLevel.fromJson(levelJson)).toList();
      
      // Levels loaded
    } catch (e) {
      // Error ignored in production
    }
  }

  // To get data for a specific level
  static PuzzleLevel? getLevel(int levelId) {
    try {
      return _levels.firstWhere((lvl) => lvl.id == levelId);
    } catch (e) {
      return null; // Level not found
    }
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved Fun maze entry — persisted locally so the user can replay,
/// see completion status, and share their mazes.
class FunMazeEntry {
  final String name;
  final String createdAt;
  final bool isCompleted;
  final int? stars;

  FunMazeEntry({
    required this.name,
    required this.createdAt,
    this.isCompleted = false,
    this.stars,
  });

  FunMazeEntry copyWith({bool? isCompleted, int? stars}) => FunMazeEntry(
        name: name,
        createdAt: createdAt,
        isCompleted: isCompleted ?? this.isCompleted,
        stars: stars ?? this.stars,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt,
        'isCompleted': isCompleted,
        'stars': stars,
      };

  factory FunMazeEntry.fromJson(Map<String, dynamic> json) => FunMazeEntry(
        name: json['name'] as String,
        createdAt: json['createdAt'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        stars: json['stars'] as int?,
      );
}

/// Manages local persistence of Fun (My Maze) entries.
class FunMazeManager {
  static const String _key = 'fun_maze_entries';

  /// Load all saved maze entries.
  static Future<List<FunMazeEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => FunMazeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Save a new maze entry (called when user creates a maze).
  static Future<void> add(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    // Don't add duplicate names
    final existing = raw
        .map((s) => FunMazeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    if (existing.any((e) => e.name.toUpperCase() == name.toUpperCase())) return;

    final entry = FunMazeEntry(
      name: name.trim().toUpperCase(),
      createdAt: DateTime.now().toIso8601String(),
    );
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_key, raw);
  }

  /// Mark a maze as completed with stars.
  static Future<void> markCompleted(String name, {int stars = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((s) => FunMazeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    bool found = false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].name.toUpperCase() == name.toUpperCase()) {
        entries[i] = entries[i].copyWith(isCompleted: true, stars: stars);
        found = true;
        break;
      }
    }

    if (!found) {
      // If somehow not saved yet, add and mark complete
      entries.add(FunMazeEntry(
        name: name.trim().toUpperCase(),
        createdAt: DateTime.now().toIso8601String(),
        isCompleted: true,
        stars: stars,
      ));
    }

    await prefs.setStringList(
      _key,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Delete a saved maze entry.
  static Future<void> delete(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((s) => FunMazeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    entries.removeWhere((e) => e.name.toUpperCase() == name.toUpperCase());
    await prefs.setStringList(
      _key,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

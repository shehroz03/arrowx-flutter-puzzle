import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameDataManager {
  // Keys (Taake spelling mistake na ho)
  static const String _levelKey = 'unlocked_level';
  static const String _pointsKey = 'total_points';
  static const String _screenKey = 'last_screen';
  static const String _playingLevelKey = 'playing_level';

  static Future<void> saveLastScreen(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_screenKey, screen);
  }

  static Future<String> loadLastScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_screenKey) ?? 'home';
  }

  static Future<void> savePlayingLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playingLevelKey, level);
  }

  static Future<int> loadPlayingLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playingLevelKey) ?? (prefs.getInt(_levelKey) ?? 1);
  }

  // 1. Data SAVE karne ka function
  static Future<void> saveProgress(int currentLevel, int points) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Naya data save karein
    await prefs.setInt(_levelKey, currentLevel);
    await prefs.setInt(_pointsKey, points);
    
    debugPrint("Progress Saved! Level: $currentLevel, Points: $points");
  }

  // 2. Data LOAD karne ka function
  static Future<Map<String, int>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Agar user pehli baar game khel raha hai, toh Level 1 aur 0 Points assign honge (?? ka matlab hai 'default value')
    int savedLevel = prefs.getInt(_levelKey) ?? 1;
    int savedPoints = prefs.getInt(_pointsKey) ?? 0;
    
    return {
      'level': savedLevel,
      'points': savedPoints,
    };
  }

  // 3. Game Reset karne ka function (Settings mein 'Reset Game' button ke liye)
  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

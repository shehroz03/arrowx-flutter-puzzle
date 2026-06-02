import 'package:shared_preferences/shared_preferences.dart';

class GameDataManager {
  // Keys (to avoid spelling mistakes)
  static const String _levelKey = 'unlocked_level';
  static const String _pointsKey = 'total_points';
  static const String _screenKey = 'last_screen';
  static const String _playingLevelKey = 'playing_level';
  static const String _levelTimeKey = 'level_time_';

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

  static Future<void> saveLevelTime(int level, int timeRemaining) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_levelTimeKey$level', timeRemaining);
  }

  static Future<int?> loadLevelTime(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_levelTimeKey$level');
  }

  static Future<void> clearLevelTime(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_levelTimeKey$level');
  }

  // 1. Function to save game data
  static Future<void> saveProgress(int nextLevel, int points) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save new data, but don't downgrade level if replaying
    int savedLevel = prefs.getInt(_levelKey) ?? 1;
    if (nextLevel > savedLevel) {
      await prefs.setInt(_levelKey, nextLevel);
    }
    
    // Save points
    await prefs.setInt(_pointsKey, points);
  }

  // 2. Function to load game data
  static Future<Map<String, int>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    // If the user is playing for the first time, assign Level 1 and 0 Points (?? means 'default value')
    int savedLevel = prefs.getInt(_levelKey) ?? 1;
    int savedPoints = prefs.getInt(_pointsKey) ?? 0;
    
    return {
      'level': savedLevel,
      'points': savedPoints,
    };
  }

  // 3. Function to reset game (for 'Reset Game' button in Settings)
  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

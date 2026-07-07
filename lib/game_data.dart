import 'package:shared_preferences/shared_preferences.dart';

class GameDataManager {
  // Keys (to avoid spelling mistakes)
  static const String _levelKey = 'unlocked_level';
  static const String _pointsKey = 'total_points';
  static const String _screenKey = 'last_screen';
  static const String _playingLevelKey = 'playing_level';
  static const String _levelTimeKey = 'level_time_';
  static const String _remainingArrowsKey = 'rem_arrows_lvl_';

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

  static Future<void> saveRemainingArrows(int level, List<int> arrowIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_remainingArrowsKey$level', arrowIds.join(','));
  }

  static Future<List<int>?> loadRemainingArrows(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_remainingArrowsKey$level');
    if (str == null) return null;
    if (str.isEmpty) return [];
    return str.split(',').map((e) => int.parse(e)).toList();
  }

  static Future<void> clearRemainingArrows(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_remainingArrowsKey$level');
  }

  // ---------- Star wallet (earned on level complete, spent in the shop) ----------
  static const String _starsKey = 'star_balance';
  static const String _themesKey = 'unlocked_themes';

  static Future<int> loadStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey) ?? 0;
  }

  static Future<int> addStars(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_starsKey) ?? 0) + amount;
    await prefs.setInt(_starsKey, total);
    return total;
  }

  /// Returns true and deducts if the balance covers [amount].
  static Future<bool> spendStars(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getInt(_starsKey) ?? 0;
    if (balance < amount) return false;
    await prefs.setInt(_starsKey, balance - amount);
    return true;
  }

  // ---------- Real progress + events (daily / weekly / milestones) ----------
  static const String _maxCompletedKey = 'max_completed_level';

  static String _dayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static String _weekKey() {
    final n = DateTime.now();
    final dayOfYear = n.difference(DateTime(n.year, 1, 1)).inDays;
    return '${n.year}_${dayOfYear ~/ 7}';
  }

  /// Called on every real (non-custom) level completion: records true
  /// progress and bumps this week's marathon counter.
  static Future<void> markLevelCompleted(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final prevMax = prefs.getInt(_maxCompletedKey) ?? 0;
    if (level > prevMax) await prefs.setInt(_maxCompletedKey, level);
    final wk = 'weekly_progress_${_weekKey()}';
    await prefs.setInt(wk, (prefs.getInt(wk) ?? 0) + 1);
  }

  /// Highest level the player has genuinely completed (not the inflated
  /// unlock count) — drives milestones.
  static Future<int> loadMaxCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxCompletedKey) ?? 0;
  }

  static Future<bool> isDailyDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_done_${_dayKey()}') ?? false;
  }

  static Future<void> markDailyDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_done_${_dayKey()}', true);
  }

  static Future<int> loadWeeklyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weekly_progress_${_weekKey()}') ?? 0;
  }

  static Future<bool> isWeeklyClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('weekly_claimed_${_weekKey()}') ?? false;
  }

  /// Claims the weekly reward. Returns true when it was actually granted.
  static Future<bool> claimWeeklyReward(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getInt('weekly_progress_${_weekKey()}') ?? 0;
    final claimed = prefs.getBool('weekly_claimed_${_weekKey()}') ?? false;
    if (progress < 10 || claimed) return false;
    await prefs.setBool('weekly_claimed_${_weekKey()}', true);
    await addStars(stars);
    return true;
  }

  static Future<bool> isMilestoneClaimed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('milestone_claimed_$id') ?? false;
  }

  /// Grants a milestone's stars exactly once. Returns true when granted.
  static Future<bool> claimMilestone(String id, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('milestone_claimed_$id') ?? false) return false;
    await prefs.setBool('milestone_claimed_$id', true);
    await addStars(stars);
    return true;
  }

  // Best stars ever earned per level (per game mode). The wallet is only
  // credited for IMPROVEMENT over this record, so replaying can never farm stars.
  static const String _bestStarsKey = 'best_stars_';

  static Future<int> loadBestStars(String mode, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_bestStarsKey${mode}_$level') ?? 0;
  }

  static Future<void> saveBestStars(String mode, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_bestStarsKey${mode}_$level', stars);
  }

  static Future<Set<int>> loadUnlockedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_themesKey) ?? [];
    return raw.map(int.parse).toSet();
  }

  static Future<void> unlockTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getStringList(_themesKey) ?? []).toSet();
    raw.add('$index');
    await prefs.setStringList(_themesKey, raw.toList());
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

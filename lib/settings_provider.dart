import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameTheme {
  final Color bg;
  final Color arrow;
  final Color dot;
  final Color ui;
  final String name;

  GameTheme({required this.bg, required this.arrow, required this.dot, required this.ui, required this.name});
}

final List<GameTheme> gameThemes = [
  GameTheme(bg: const Color(0xFFF5F0E6), arrow: const Color(0xFF7B5B3A), dot: const Color(0xFFCDBBA7), ui: const Color(0xFF7B5B3A), name: "Classic"),
  GameTheme(bg: const Color(0xFF0F172A), arrow: const Color(0xFF38BDF8), dot: const Color(0xFF334155), ui: Colors.white, name: "Neon Blue"),
  GameTheme(bg: const Color(0xFF064E3B), arrow: const Color(0xFF34D399), dot: const Color(0xFF065F46), ui: Colors.white, name: "Forest"),
  GameTheme(bg: const Color(0xFF4C1D95), arrow: const Color(0xFFC084FC), dot: const Color(0xFF5B21B6), ui: Colors.white, name: "Royal Purple"),
  GameTheme(bg: const Color(0xFF18181B), arrow: const Color(0xFFF4F4F5), dot: const Color(0xFF27272A), ui: Colors.white, name: "Midnight"),
];

class SettingsState {
  final bool isSoundOn;
  final bool isVibrationOn;
  final bool isGuidelineOn;
  final int themeIndex;

  SettingsState({
    this.isSoundOn = true,
    this.isVibrationOn = true,
    this.isGuidelineOn = false,
    this.themeIndex = 0,
  });

  GameTheme get currentTheme => gameThemes[themeIndex];

  SettingsState copyWith({bool? isSoundOn, bool? isVibrationOn, bool? isGuidelineOn, int? themeIndex}) {
    return SettingsState(
      isSoundOn: isSoundOn ?? this.isSoundOn,
      isVibrationOn: isVibrationOn ?? this.isVibrationOn,
      isGuidelineOn: isGuidelineOn ?? this.isGuidelineOn,
      themeIndex: themeIndex ?? this.themeIndex,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      isSoundOn: prefs.getBool('sound') ?? true,
      isVibrationOn: prefs.getBool('vibration') ?? true,
      isGuidelineOn: prefs.getBool('guideline') ?? false,
      themeIndex: prefs.getInt('themeIndex') ?? 0,
    );
  }

  Future<void> setTheme(int index) async {
    state = state.copyWith(themeIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeIndex', index);
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(isSoundOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', value);
  }

  Future<void> toggleVibration(bool value) async {
    state = state.copyWith(isVibrationOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);
  }

  Future<void> toggleGuideline(bool value) async {
    state = state.copyWith(isGuidelineOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guideline', value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

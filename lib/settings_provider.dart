import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_manager.dart';

class GameTheme {
  final Color bg;
  final Color arrow;
  final Color dot;
  final Color ui;
  final String name;

  /// Shop price in stars. 0 = free (always unlocked).
  final int price;

  /// Premium themes get an animated gradient backdrop instead of a flat bg.
  final List<Color>? gradient;

  /// Drifting particle style for premium themes:
  /// 'heart', 'petal', 'sparkle', 'bubble', 'ray', 'star',
  /// 'prism', 'ember', 'gem', 'neon', 'holo'.
  final String? particle;

  /// Particle / highlight color.
  final Color accent;

  /// Forces the arrow clear/fly animation to a specific effect so it matches
  /// the theme (0 echo, 1 dust, 2 warp, 3 portal, 4 ripple, 5 bolt).
  /// When null, the arrow uses the per-level rotation.
  final int? trailEffect;

  GameTheme({
    required this.bg,
    required this.arrow,
    required this.dot,
    required this.ui,
    required this.name,
    this.price = 0,
    this.gradient,
    this.particle,
    Color? accent,
    this.trailEffect,
  }) : accent = accent ?? arrow;

  bool get isPremium => price > 0;
}

/// Trail effect of the currently applied theme (or null for level rotation).
/// A plain global so game_state can match the clear SOUND to the theme without
/// depending on Riverpod. Kept in sync by SettingsNotifier.
int? activeTrailOverride;

final List<GameTheme> gameThemes = [
  GameTheme(bg: const Color(0xFFF5F0E6), arrow: const Color(0xFF7B5B3A), dot: const Color(0xFFCDBBA7), ui: const Color(0xFF7B5B3A), name: "Classic"),
  GameTheme(bg: const Color(0xFF0F172A), arrow: const Color(0xFF38BDF8), dot: const Color(0xFF334155), ui: Colors.white, name: "Neon Blue"),
  GameTheme(bg: const Color(0xFF064E3B), arrow: const Color(0xFF34D399), dot: const Color(0xFF065F46), ui: Colors.white, name: "Forest"),
  GameTheme(bg: const Color(0xFF4C1D95), arrow: const Color(0xFFC084FC), dot: const Color(0xFF5B21B6), ui: Colors.white, name: "Royal Purple"),
  GameTheme(bg: const Color(0xFF18181B), arrow: const Color(0xFFF4F4F5), dot: const Color(0xFF27272A), ui: Colors.white, name: "Midnight"),
  // ---------- Premium shop themes (bought with collected stars) ----------
  GameTheme(
    bg: const Color(0xFFFDF2F4), arrow: const Color(0xFFB76E79), dot: const Color(0xFFE8C4CB),
    ui: const Color(0xFF8E4E58), name: "Rose Gold", price: 15,
    gradient: const [Color(0xFFFFF0F3), Color(0xFFFAD4DC), Color(0xFFF3C1CC)],
    particle: 'heart', accent: const Color(0xFFD48A96),
  ),
  GameTheme(
    bg: const Color(0xFFFFF5F8), arrow: const Color(0xFFE0559A), dot: const Color(0xFFF4C6DC),
    ui: const Color(0xFFA83A72), name: "Sakura Bloom", price: 20,
    gradient: const [Color(0xFFFFF7FA), Color(0xFFFFDCE9), Color(0xFFFFC9DE)],
    particle: 'petal', accent: const Color(0xFFF48FB1),
  ),
  GameTheme(
    bg: const Color(0xFFF6F2FF), arrow: const Color(0xFF7C5CBF), dot: const Color(0xFFD5C8F0),
    ui: const Color(0xFF5B3E99), name: "Lavender Dream", price: 25,
    gradient: const [Color(0xFFF9F5FF), Color(0xFFE4D9F7), Color(0xFFD4C3F2)],
    particle: 'sparkle', accent: const Color(0xFFA98BE0),
  ),
  GameTheme(
    bg: const Color(0xFFEDFAFB), arrow: const Color(0xFF0E8C9C), dot: const Color(0xFFBBE5EA),
    ui: const Color(0xFF0B6A76), name: "Ocean Pearl", price: 30,
    gradient: const [Color(0xFFF0FCFD), Color(0xFFCDEFF3), Color(0xFFA9E2EA)],
    particle: 'bubble', accent: const Color(0xFF54BCC9),
  ),
  GameTheme(
    bg: const Color(0xFFFFF6EE), arrow: const Color(0xFFE0632C), dot: const Color(0xFFF7D3B8),
    ui: const Color(0xFFAE4413), name: "Sunset Glow", price: 40,
    gradient: const [Color(0xFFFFF3E4), Color(0xFFFFDCC0), Color(0xFFFDC6A6)],
    particle: 'ray', accent: const Color(0xFFF2955C),
  ),
  GameTheme(
    bg: const Color(0xFF19102E), arrow: const Color(0xFFE9B8FF), dot: const Color(0xFF3C2B5E),
    ui: Colors.white, name: "Galaxy Queen", price: 50,
    gradient: const [Color(0xFF1B1035), Color(0xFF2C1B52), Color(0xFF43216B)],
    particle: 'star', accent: const Color(0xFFF0C674),
  ),
  // ---------- New 3D themes: unique particles + theme-matched clear FX ----------
  GameTheme(
    bg: const Color(0xFF1E293B), arrow: const Color(0xFF38BDF8), dot: const Color(0xFF334155),
    ui: const Color(0xFF7DD3FC), name: "3D Prism", price: 60,
    gradient: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
    particle: 'prism', accent: const Color(0xFF818CF8),
    trailEffect: 2, // warp — refracted light streaks
  ),
  GameTheme(
    bg: const Color(0xFF18181B), arrow: const Color(0xFFF97316), dot: const Color(0xFF3F3F46),
    ui: const Color(0xFFFDBA74), name: "3D Obsidian", price: 75,
    gradient: const [Color(0xFF000000), Color(0xFF18181B), Color(0xFF27272A)],
    particle: 'ember', accent: const Color(0xFFFDBA74),
    trailEffect: 1, // dust — crumbling embers
  ),
  GameTheme(
    bg: const Color(0xFF064E3B), arrow: const Color(0xFFFBBF24), dot: const Color(0xFF047857),
    ui: const Color(0xFFFDE047), name: "3D Emerald", price: 90,
    gradient: const [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF047857)],
    particle: 'gem', accent: const Color(0xFFFDE047),
    trailEffect: 4, // ripple — gem shimmer
  ),
  GameTheme(
    bg: const Color(0xFF2E1065), arrow: const Color(0xFFF472B6), dot: const Color(0xFF4C1D95),
    ui: const Color(0xFF22D3EE), name: "3D Cyberpunk", price: 120,
    gradient: const [Color(0xFF170F2E), Color(0xFF2E1065), Color(0xFF4C1D95)],
    particle: 'neon', accent: const Color(0xFF06B6D4),
    trailEffect: 5, // bolt — electric surge
  ),
  GameTheme(
    bg: const Color(0xFF0A2A3A), arrow: const Color(0xFF7DF9FF), dot: const Color(0xFF124A5E),
    ui: const Color(0xFFA8ECFF), name: "3D Hologram", price: 150,
    gradient: const [Color(0xFF071E2C), Color(0xFF0E3A50), Color(0xFF1B5E7E)],
    particle: 'holo', accent: const Color(0xFF7DF9FF),
    trailEffect: 3, // portal — holographic warp gate
  ),
  GameTheme(
    bg: const Color(0xFF450A0A), arrow: const Color(0xFFFCA5A5), dot: const Color(0xFF7F1D1D),
    ui: const Color(0xFFFCA5A5), name: "3D Crimson", price: 200,
    gradient: const [Color(0xFF220505), Color(0xFF450A0A), Color(0xFF7F1D1D)],
    particle: 'ember', accent: const Color(0xFFF87171),
    trailEffect: 0, // echo — blazing afterimage
  ),
];

class SettingsState {
  final bool isSoundOn;
  final bool isMusicOn;
  final bool isVibrationOn;
  final bool isGuidelineOn;
  final int themeIndex;

  SettingsState({
    this.isSoundOn = true,
    this.isMusicOn = true,
    this.isVibrationOn = true,
    this.isGuidelineOn = false,
    this.themeIndex = 0,
  });

  GameTheme get currentTheme => gameThemes[themeIndex];

  SettingsState copyWith({bool? isSoundOn, bool? isMusicOn, bool? isVibrationOn, bool? isGuidelineOn, int? themeIndex}) {
    return SettingsState(
      isSoundOn: isSoundOn ?? this.isSoundOn,
      isMusicOn: isMusicOn ?? this.isMusicOn,
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
    final sound = prefs.getBool('sound') ?? true;
    final music = prefs.getBool('music') ?? true;
    state = SettingsState(
      isSoundOn: sound,
      isMusicOn: music,
      isVibrationOn: prefs.getBool('vibration') ?? true,
      isGuidelineOn: prefs.getBool('guideline') ?? false,
      themeIndex: prefs.getInt('themeIndex') ?? 0,
    );
    activeTrailOverride = gameThemes[state.themeIndex].trailEffect;
    // Sync SoundManager on load
    SoundManager().setSoundMute(!sound);
    SoundManager().setMusicMute(!music);
    if (music) {
      SoundManager().startBGM();
    }
  }

  Future<void> setTheme(int index) async {
    state = state.copyWith(themeIndex: index);
    activeTrailOverride = gameThemes[index].trailEffect;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeIndex', index);
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(isSoundOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', value);
    // Sync SoundManager on change
    SoundManager().setSoundMute(!value);
  }

  Future<void> toggleMusic(bool value) async {
    state = state.copyWith(isMusicOn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music', value);
    // Sync SoundManager on change
    SoundManager().setMusicMute(!value);
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

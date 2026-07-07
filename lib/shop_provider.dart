import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_data.dart';
import 'settings_provider.dart';

class ShopState {
  final int stars;
  final Set<int> unlocked;
  const ShopState({this.stars = 0, this.unlocked = const {}});

  bool isUnlocked(int themeIndex) =>
      !gameThemes[themeIndex].isPremium || unlocked.contains(themeIndex);

  ShopState copyWith({int? stars, Set<int>? unlocked}) =>
      ShopState(stars: stars ?? this.stars, unlocked: unlocked ?? this.unlocked);
}

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier() : super(const ShopState()) {
    refresh();
  }

  Future<void> refresh() async {
    final stars = await GameDataManager.loadStars();
    final unlocked = await GameDataManager.loadUnlockedThemes();
    if (!mounted) return;
    state = ShopState(stars: stars, unlocked: unlocked);
  }

  /// Buys [themeIndex] with stars; returns true on success.
  Future<bool> buy(int themeIndex) async {
    if (state.isUnlocked(themeIndex)) return true;
    final ok = await GameDataManager.spendStars(gameThemes[themeIndex].price);
    if (!ok) return false;
    await GameDataManager.unlockTheme(themeIndex);
    await refresh();
    return true;
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) => ShopNotifier());

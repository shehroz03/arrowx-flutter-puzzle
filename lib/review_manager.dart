import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages in-app review prompts for Play Store ASO.
///
/// Shows the native review dialog at strategic moments:
/// - After completing level 10 (first impression)
/// - After completing level 30 (engaged user)
/// - After completing level 75 (power user)
///
/// Each prompt is shown at most once. The native dialog itself is
/// rate-limited by the OS, so even if we call it, the system may
/// choose not to show it.
class ReviewManager {
  static final ReviewManager _instance = ReviewManager._();
  factory ReviewManager() => _instance;
  ReviewManager._();

  static const String _reviewShownKey = 'review_shown_at_levels';

  /// Levels at which we attempt to show the review dialog.
  static const List<int> _triggerLevels = [10, 30, 75];

  /// Call this whenever a level is completed.
  Future<void> onLevelComplete(int level) async {
    if (!_triggerLevels.contains(level)) return;

    final prefs = await SharedPreferences.getInstance();
    final shownLevels = prefs.getStringList(_reviewShownKey) ?? [];

    // Already prompted at this level? Skip.
    if (shownLevels.contains(level.toString())) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }

    // Mark this trigger level as done regardless of whether the dialog showed
    // (the OS may suppress it, but we shouldn't retry on the same level).
    shownLevels.add(level.toString());
    await prefs.setStringList(_reviewShownKey, shownLevels);
  }
}

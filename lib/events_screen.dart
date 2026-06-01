import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'game_board.dart';
import 'game_data.dart';
import 'sound_manager.dart';
import 'level_selection_screen.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Events",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E2C),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Special challenges & rewards",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Active Event — Daily Challenge
              _EventBanner(
                title: "Daily Challenge",
                subtitle: "Complete today's puzzle for bonus coins!",
                icon: Icons.calendar_today_rounded,
                gradient: const [Color(0xFF1E56D0), Color(0xFF4A90D9)],
                tag: "ACTIVE",
                tagColor: Colors.greenAccent,
                reward: "+50 Coins",
                timeLeft: _getTimeUntilMidnight(),
                onTap: () {
                  SoundManager().playTap();
                  GameDataManager.saveLastScreen('game');
                  // Load a pseudo-random level based on the day of the year
                  final dayLevel = (DateTime.now().difference(DateTime(2024, 1, 1)).inDays % 70) + 1;
                  ref.read(gameStateProvider.notifier).loadLevel(dayLevel);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameBoardScreen()),
                  ).then((_) => GameDataManager.saveLastScreen('home'));
                },
              ),

              const SizedBox(height: 16),

              // Weekly Challenge
              _EventBanner(
                title: "Weekly Marathon",
                subtitle: "Clear 10 levels this week to earn a trophy",
                icon: Icons.emoji_events_rounded,
                gradient: const [Color(0xFFE67E22), Color(0xFFF39C12)],
                tag: "IN PROGRESS",
                tagColor: Colors.orangeAccent,
                reward: "🏆 Trophy + 200 Coins",
                progress: (gameState.level % 10) / 10,
                progressLabel: "${gameState.level % 10}/10 Levels",
                onTap: () {
                  SoundManager().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Speed Tournament
              _EventBanner(
                title: "Speed Tournament",
                subtitle: "Fastest solver wins the leaderboard!",
                icon: Icons.speed_rounded,
                gradient: const [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
                tag: "COMING SOON",
                tagColor: Colors.grey,
                reward: "🥇 Top 3 Win 500 Coins",
                isLocked: true,
                onTap: () => _showComingSoon(context),
              ),

              const SizedBox(height: 28),

              // Section: Seasonal
              const Text(
                "SEASONAL EVENTS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Summer Showdown
              _SeasonalEventCard(
                title: "Summer Showdown",
                description: "Exclusive summer-themed arrow puzzles with special backgrounds and effects.",
                icon: Icons.wb_sunny_rounded,
                gradient: const [Color(0xFFF39C12), Color(0xFFE67E22)],
                reward: "🌴 Summer Skin + 300 Coins",
                daysLeft: 45,
                isLocked: true,
                onTap: () => _showComingSoon(context),
              ),

              const SizedBox(height: 14),

              // Holiday Special
              _SeasonalEventCard(
                title: "Holiday Special",
                description: "Festive puzzles with holiday themes. Double coins on every level!",
                icon: Icons.celebration_rounded,
                gradient: const [Color(0xFF9B59B6), Color(0xFFAF7AC5)],
                reward: "🎄 2x Coins All Week",
                daysLeft: 120,
                isLocked: true,
                onTap: () => _showComingSoon(context),
              ),

              const SizedBox(height: 28),

              // Section: Achievements
              const Text(
                "MILESTONES",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Milestone Cards Row
              Row(
                children: [
                  Expanded(
                    child: _MilestoneCard(
                      icon: Icons.bolt_rounded,
                      title: "First Win",
                      subtitle: gameState.level > 1 ? "Completed!" : "Clear Stage 1",
                      isCompleted: gameState.level > 1,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MilestoneCard(
                      icon: Icons.local_fire_department_rounded,
                      title: "5 Streak",
                      subtitle: gameState.level >= 5 ? "Completed!" : "${gameState.level}/5 Levels",
                      isCompleted: gameState.level >= 5,
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MilestoneCard(
                      icon: Icons.diamond_rounded,
                      title: "Master",
                      subtitle: gameState.level >= 25 ? "Completed!" : "${gameState.level}/25 Levels",
                      isCompleted: gameState.level >= 25,
                      color: const Color(0xFF1E56D0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MilestoneCard(
                      icon: Icons.military_tech_rounded,
                      title: "Legend",
                      subtitle: gameState.level >= 50 ? "Completed!" : "${gameState.level}/50 Levels",
                      isCompleted: gameState.level >= 50,
                      color: const Color(0xFF9B59B6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return "${hours}h ${minutes}m left";
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Coming Soon! Stay tuned.", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E56D0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String tag;
  final Color tagColor;
  final String reward;
  final String? timeLeft;
  final double? progress;
  final String? progressLabel;
  final bool isLocked;
  final VoidCallback onTap;

  const _EventBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tag,
    required this.tagColor,
    required this.reward,
    this.timeLeft,
    this.progress,
    this.progressLabel,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked 
                ? [Colors.grey.shade600, Colors.grey.shade700]
                : gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (isLocked ? Colors.grey : gradient[0]).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag + Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),

            const SizedBox(height: 14),

            // Progress or TimeLeft
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress!,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 6),
                Text(progressLabel!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
            ],

            // Reward + Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                if (timeLeft != null)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 4),
                      Text(timeLeft!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                if (isLocked)
                  const Icon(Icons.lock_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonalEventCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String reward;
  final int daysLeft;
  final bool isLocked;
  final VoidCallback onTap;

  const _SeasonalEventCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.reward,
    required this.daysLeft,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  if (isLocked)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 22),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey : const Color(0xFF1E1E2C))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("${daysLeft}d", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 2),
                  const SizedBox(height: 6),
                  Text(reward, style: TextStyle(color: gradient[0], fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isLocked ? Colors.grey.shade300 : const Color(0xFF1E56D0)),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color color;

  const _MilestoneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
        border: isCompleted ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : icon,
              color: isCompleted ? color : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCompleted ? color : Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: isCompleted ? Colors.green : Colors.grey.shade400, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

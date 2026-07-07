import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'shop_provider.dart';
import 'level_selection_screen.dart';
import 'sound_manager.dart';
import 'iq_test_screen.dart';
import 'maze_master_screen.dart';
import 'color_match_screen.dart';

class PuzzlesScreen extends ConsumerWidget {
  const PuzzlesScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Puzzles",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1E2C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Choose your challenge",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Consumer(builder: (context, ref2, _) {
                          final shop = ref2.watch(shopProvider);
                          return Text(
                            "${shop.stars}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E2C)),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E56D0), Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E56D0).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Your Progress", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            "Stage ${gameState.level} / 200",
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: gameState.level / 200,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${(gameState.level / 200 * 100).toInt()}%",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Puzzle Categories
              const Text(
                "GAME MODES",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Classic Arrow Puzzle — Main Game
              _PuzzleCategoryCard(
                icon: Icons.arrow_forward_rounded,
                title: "Classic Arrow",
                subtitle: "Tap arrows to clear the grid",
                levels: "200 Levels",
                progress: gameState.level - 1,
                totalLevels: 200,
                gradient: const [Color(0xFF1E56D0), Color(0xFF4A90D9)],
                onTap: () {
                  SoundManager().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LevelSelectionScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // IQ Test
              _PuzzleCategoryCard(
                icon: Icons.psychology_rounded,
                title: "IQ Test",
                subtitle: "Challenge your brain with logic puzzles",
                levels: "Test Mode",
                progress: 0,
                totalLevels: 1,
                gradient: const [Color(0xFFE91E63), Color(0xFFC2185B)],
                isLocked: false,
                onTap: () {
                  SoundManager().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IQTestScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Maze Master
              _PuzzleCategoryCard(
                icon: Icons.grid_view_rounded,
                title: "Maze Master",
                subtitle: "Navigate complex arrow mazes",
                levels: "30 Levels",
                progress: 0,
                totalLevels: 30,
                gradient: const [Color(0xFF9B59B6), Color(0xFFAF7AC5)],
                isLocked: false,
                onTap: () {
                  SoundManager().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MazeMasterScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Color Match
              _PuzzleCategoryCard(
                icon: Icons.palette_rounded,
                title: "Color Match",
                subtitle: "Match colored arrows to clear",
                levels: "25 Levels",
                progress: 0,
                totalLevels: 25,
                gradient: const [Color(0xFF2ECC71), Color(0xFF27AE60)],
                isLocked: false,
                onTap: () {
                  SoundManager().playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ColorMatchScreen()),
                  );
                },
              ),


              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

}

class _PuzzleCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String levels;
  final int progress;
  final int totalLevels;
  final List<Color> gradient;
  final bool isLocked;
  final VoidCallback onTap;

  const _PuzzleCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.levels,
    required this.progress,
    required this.totalLevels,
    required this.gradient,
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
            // Icon
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey : const Color(0xFF1E1E2C))),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("SOON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(levels, style: TextStyle(color: gradient[0], fontWeight: FontWeight.w700, fontSize: 12)),
                      if (!isLocked && totalLevels > 1) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / totalLevels,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(gradient[0]),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("$progress/$totalLevels", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
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

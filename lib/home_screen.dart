import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_board.dart';
import 'game_state.dart';
import 'game_data.dart';
import 'sound_manager.dart';
import 'puzzles_screen.dart';
import 'events_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'level_selection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeContent(showComingSoon: _showComingSoon),
          const PuzzlesScreen(),
          const EventsScreen(),
        ],
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onItemTap: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final void Function(BuildContext) showComingSoon;
  const _HomeContent({required this.showComingSoon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    
    return Stack(
      children: [
        // Background Blobs/Gradients
        Positioned(
          top: -100,
          left: -50,
          child: _BackgroundBlob(color: const Color(0xFF1E56D0).withValues(alpha: 0.1), size: 300),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _BackgroundBlob(color: const Color(0xFF4A90D9).withValues(alpha: 0.05), size: 400),
        ),
        
        SafeArea(
          child: Column(
            children: [
              // Top Bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(height: 36), // Preserve some spacing where coin counter was
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      
                      // Stage Progression
                      GestureDetector(
                        onTap: () {
                          SoundManager().playTap();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectionScreen()));
                        },
                        child: _StageProgression(current: gameState.level, total: 70),
                      ),
                      const SizedBox(height: 40),
                      
                      // Central Logo & Tagline
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _FloatingIcon(),
                          const SizedBox(height: 10),
                          const Text(
                            "MASTER THE MAZE",
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E56D0),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // Main Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PulsingPlayButton(
                            level: gameState.level,
                            onPressed: () {
                              SoundManager().playTap();
                              GameDataManager.saveLastScreen('game');
                              GameDataManager.savePlayingLevel(gameState.level);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GameBoardScreen()),
                              ).then((_) => GameDataManager.saveLastScreen('home'));
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Daily Challenges Card
                      _DailyChallengeCard(onTap: () {
                        SoundManager().playTap();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                      }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BackgroundBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _CoinCounter extends StatelessWidget {
  final int coins;
  const _CoinCounter({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            "$coins",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E2C)),
          ),
        ],
      ),
    );
  }
}

class _StageProgression extends StatelessWidget {
  final int current;
  final int total;
  const _StageProgression({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20),
            ],
          ),
          child: Row(
            children: List.generate(6, (i) {
              final isActive = i < (current / total * 6).ceil().clamp(1, 6);
              return Expanded(
                child: Container(
                  height: 30,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: isActive 
                      ? const LinearGradient(colors: [Color(0xFF1E56D0), Color(0xFF4A90D9)])
                      : null,
                    color: isActive ? null : Colors.grey.shade100,
                  ),
                ),
              );
            })..add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("$current/$total", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text("Stage Progression", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CircularIconButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF1E56D0), Color(0xFF4A90D9)]),
              boxShadow: [
                BoxShadow(color: const Color(0xFF1E56D0).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C), fontSize: 14)),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DailyChallengeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E56D0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1E56D0)),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Daily Challenges", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E2C))),
                  SizedBox(height: 4),
                  Text("Progress 10 / 50 minutes", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTap;
  const _CustomBottomNavBar({required this.currentIndex, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(icon: Icons.home_rounded, label: "Home", isActive: currentIndex == 0, onTap: () => onItemTap(0)),
          _NavBarItem(icon: Icons.extension_rounded, label: "Puzzles", isActive: currentIndex == 1, onTap: () => onItemTap(1)),
          _NavBarItem(icon: Icons.emoji_events_outlined, label: "Events", isActive: currentIndex == 2, onTap: () => onItemTap(2)),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavBarItem({required this.icon, required this.label, this.isActive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF1E56D0) : Colors.grey.shade400;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon();
  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Transform.translate(offset: Offset(0, _anim.value), child: child),
      child: SizedBox(
        width: 280,
        height: 180,
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.contain,
          color: const Color(0xFFF8FAFF),
          colorBlendMode: BlendMode.multiply,
        ),
      ),
    );
  }
}

class _PulsingPlayButton extends StatefulWidget {
  final int level;
  final VoidCallback onPressed;
  const _PulsingPlayButton({required this.level, required this.onPressed});

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutQuad));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        width: 180,
        height: 85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E56D0), Color(0xFF4A90D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E56D0).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          onPressed: widget.onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("START GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text("Stage ${widget.level}", style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

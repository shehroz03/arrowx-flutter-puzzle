import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_board.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'game_state.dart';
import 'game_data.dart';
import 'sound_manager.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // Clean premium white/off-white
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.blueGrey, size: 28),
            onPressed: () {
              GameDataManager.saveLastScreen('settings');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => GameDataManager.saveLastScreen('home'));
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        children: [
          // Subtle background texture/grid matching splash
          Positioned.fill(child: _LightGridBackground()),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _FloatingIcon(),
                const SizedBox(height: 25),
                const Text(
                  "ArrowX",
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E2C),
                    letterSpacing: 4.0,
                  ),
                ),
                const Text(
                  "MASTER THE MAZE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E56D0),
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 80),
                
                // Premium "Play" Button
                _PulsingPlayButton(
                  level: gameState.level,
                  onPressed: () {
                    SoundManager().playTap();
                    GameDataManager.saveLastScreen('game');
                    GameDataManager.savePlayingLevel(gameState.level);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameBoardScreen()),
                    ).then((_) {
                      GameDataManager.saveLastScreen('home');
                    });
                  },
                ),
                const SizedBox(height: 30),

                // Secondary Editor Access
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditorScreen()),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.blueGrey),
                  label: const Text("Custom Editor",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LightGridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.1,
      child: CustomPaint(
        painter: _GridPainter(step: 40),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double step;
  _GridPainter({required this.step});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E56D0)..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon();
  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(begin: -15, end: 15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E56D0).withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 15)),
          ],
        ),
        child: const Icon(Icons.alt_route_rounded, color: Color(0xFF1E56D0), size: 70),
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
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad));

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
        width: 240,
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF1E56D0), Color(0xFF4A90D9)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E56D0).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          onPressed: widget.onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("START GAME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
              Text("Stage ${widget.level}", style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

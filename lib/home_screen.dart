import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_board.dart';
import 'game_state.dart';
import 'game_data.dart';
import 'apna_maze_screen.dart';
import 'shop_provider.dart';
import 'shop_screen.dart';
import 'sound_manager.dart';
import 'puzzles_screen.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'level_selection_screen.dart';
import 'maze_builder.dart';
import 'fun_maze_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Handle link when app is in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'arrowx' && uri.host == 'maze') {
      final name = uri.queryParameters['name'];
      if (name != null && name.isNotEmpty) {
        final result = await buildNameMaze(name);
        if (result != null && mounted) {
          await FunMazeManager.add(name);
          if (!mounted) return;
          ref.read(gameStateProvider.notifier).loadCustomLevel(
                result.arrows,
                result.gridSize,
                mask: result.mask,
                title: name.trim().toUpperCase(),
              );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GameBoardScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not load this custom maze.'),
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeContent(showComingSoon: _showComingSoon),
          const PuzzlesScreen(),
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
        // Geometric Background Grid
        Positioned.fill(
          child: CustomPaint(
            painter: _GeometricBackgroundPainter(),
          ),
        ),
        // Background Blobs/Gradients
        Positioned(
          top: -100,
          left: -50,
          child: _BackgroundBlob(color: const Color(0xFF1E56D0).withValues(alpha: 0.12), size: 350),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _BackgroundBlob(color: const Color(0xFF00AAFF).withValues(alpha: 0.08), size: 450),
        ),
        
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      
                      // Stage Progression (Circular Indicator matching Image 1)
                      GestureDetector(
                        onTap: () {
                          SoundManager().playTap();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectionScreen()));
                        },
                        child: _CircularStageProgression(current: gameState.level, total: 200),
                      ),
                      const SizedBox(height: 45),
                      
                      // Central Logo & Tagline
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _FloatingIcon(),
                          const SizedBox(height: 12),
                          const Text(
                            "MASTER THE GRID",
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E56D0),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 55),
                      
                      // Main Action Button (Wide Gradient Pill Button)
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
                            ref.read(shopProvider.notifier).refresh();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 35),
                      

                      // Theme Shop Card (spend collected stars)
                      _ShopCard(onTap: () {
                        SoundManager().playTap();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))
                            .then((_) => ref.read(shopProvider.notifier).refresh());
                      }),
                      const SizedBox(height: 18),

                      // Apna Maze Card (name -> playable maze)
                      _ApnaMazeCard(onTap: () {
                        SoundManager().playTap();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApnaMazeScreen()));
                      }),
                      const SizedBox(height: 40),
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

class _GeometricBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E56D0).withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double spacing = 40.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
    
    for (double x = 0; x < size.width; x += spacing * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFF1E56D0).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc with sweep gradient
    final gradient = const SweepGradient(
      startAngle: -3.14159 / 2,
      endAngle: 3.14159 * 1.5,
      colors: [Color(0xFF1E56D0), Color(0xFF00AAFF), Color(0xFF1E56D0)],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;

    final sweepAngle = 2 * 3.14159 * progress.clamp(0.01, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CircularStageProgression extends StatelessWidget {
  final int current;
  final int total;
  const _CircularStageProgression({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Circular Progress
          SizedBox(
            width: 230,
            height: 230,
            child: CustomPaint(
              painter: _CircularProgressPainter(progress: current / total),
            ),
          ),
          // Inner Raised Disc
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Stage $current",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E2C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$current/$total",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _ShopCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _ShopCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF2F8), Color(0xFFF3E8FF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB76E79).withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF9B59B6).withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFB76E79), Color(0xFF9B59B6)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.palette_rounded, color: Colors.white),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Theme Shop",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E1E2C))),
                  SizedBox(height: 4),
                  Text("Unlock premium animated themes",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${shop.stars}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF7A5200))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApnaMazeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ApnaMazeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF2FF), Color(0xFFDCE9FF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E56D0).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1E56D0).withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E56D0), Color(0xFF00AAFF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.abc_rounded, color: Colors.white),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Fun",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E1E2C))),
                  SizedBox(height: 4),
                  Text("Turn your name into a playable maze",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
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
          'assets/icon_transparent.png',
          fit: BoxFit.contain,
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
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutQuad));

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
        width: double.infinity,
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E56D0), Color(0xFF00AAFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E56D0).withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(38)),
          ),
          onPressed: widget.onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "START GAME",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Stage ${widget.level}",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

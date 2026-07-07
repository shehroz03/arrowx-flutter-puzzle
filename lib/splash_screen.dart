import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'game_data.dart';
import 'game_board.dart';
import 'game_state.dart';
import 'level_selection_screen.dart';
import 'settings_screen.dart';

class SplashScreenSequence extends ConsumerStatefulWidget {
  const SplashScreenSequence({super.key});

  @override
  ConsumerState<SplashScreenSequence> createState() => _SplashScreenSequenceState();
}

class _SplashScreenSequenceState extends ConsumerState<SplashScreenSequence> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  int _sequenceIndex = 0; // 0: ArrowX, 1: Motto

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _runFullSequence();
  }

  Future<void> _runFullSequence() async {
    // 1. ArrowX Reveal Fade In
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    // Fade Out
    await _fadeController.reverse();

    // 2. Motto Reveal
    if (!mounted) return;
    setState(() => _sequenceIndex = 1);
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    // Final Fade Out before Home
    await _fadeController.reverse();

    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() async {
    String lastScreen = await GameDataManager.loadLastScreen();
    int playingLevel = await GameDataManager.loadPlayingLevel();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );

    if (lastScreen != 'home') {
       Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (lastScreen == 'game') {
          ref.read(gameStateProvider.notifier).loadLevel(playingLevel);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GameBoardScreen()));
        } else if (lastScreen == 'level_selection') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectionScreen()));
        } else if (lastScreen == 'settings') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // Premium white theme
      body: Center(
        child: FadeTransition(
          opacity: _fadeController,
          child: _sequenceIndex == 0 ? _buildLogo() : _buildMotto(),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const _FloatingSplashLogo();
  }

  Widget _buildMotto() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AnimatedArrowMottoIcon(),
          const SizedBox(height: 30),
          const Text(
            "BOOST FOCUS",
            style: TextStyle(fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold, color: Color(0xFF1E56D0)),
          ),
          const SizedBox(height: 15),
          const Text(
            "Play for 30 minutes daily to\nsharpen your mind and sleep better.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedArrowMottoIcon extends StatefulWidget {
  const _AnimatedArrowMottoIcon();
  @override
  State<_AnimatedArrowMottoIcon> createState() => _AnimatedArrowMottoIconState();
}

class _AnimatedArrowMottoIconState extends State<_AnimatedArrowMottoIcon> with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1E56D0);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Launch cycle: rest+bob -> shoot up with echo -> re-enter from below.
  double _arrowY(double t) {
    if (t < 0.30) return math.sin(t / 0.30 * math.pi * 2) * 3;
    if (t < 0.60) {
      final u = (t - 0.30) / 0.30;
      return -95 * u * u * u;
    }
    if (t < 0.72) return 300;
    final u = (t - 0.72) / 0.28;
    return 26 * (1 - Curves.easeOutBack.transform(u));
  }

  double _arrowOpacity(double t) {
    if (t < 0.30) return 1;
    if (t < 0.60) {
      final u = (t - 0.30) / 0.30;
      return 1 - u * u;
    }
    if (t < 0.72) return 0;
    return ((t - 0.72) / 0.28).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final t = _ctrl.value;
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Sonar ripples + rotating dashed ring + orbiting color dots
              CustomPaint(
                size: const Size(150, 150),
                painter: _MottoRingPainter(t),
              ),
              // Soft base circles
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue.withValues(alpha: 0.12),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue.withValues(alpha: 0.2),
                ),
              ),
              // Echo ghosts trailing the launching arrow
              for (int k = 3; k >= 1; k--)
                Transform.translate(
                  offset: Offset(0, _arrowY((t - k * 0.035).clamp(0.0, 1.0))),
                  child: Opacity(
                    opacity: (t > 0.32 && t < 0.62)
                        ? (_arrowOpacity(t) * (0.38 - k * 0.10)).clamp(0.0, 1.0)
                        : 0.0,
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 45,
                      color: _blue,
                    ),
                  ),
                ),
              // Main arrow
              Transform.translate(
                offset: Offset(0, _arrowY(t)),
                child: Opacity(
                  opacity: _arrowOpacity(t),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 45,
                    color: _blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sonar ripples, a slowly spinning dashed ring, and the five game colors
/// orbiting the badge — draws the eye without stealing it.
class _MottoRingPainter extends CustomPainter {
  static const _blue = Color(0xFF1E56D0);
  static const _palette = [
    Color(0xFFE5B142),
    Color(0xFF4A90E2),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFF2ECC71),
  ];

  final double t;
  _MottoRingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Expanding sonar ripples (two, half a phase apart)
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 2; i++) {
      final rt = (t + i * 0.5) % 1.0;
      ripple.color = _blue.withValues(alpha: (1 - rt) * 0.22);
      canvas.drawCircle(c, 42 + rt * 34, ripple);
    }

    // Rotating dashed ring
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..color = _blue.withValues(alpha: 0.35);
    final rect = Rect.fromCircle(center: c, radius: 52);
    final spin = t * 2 * math.pi;
    for (int k = 0; k < 8; k++) {
      canvas.drawArc(rect, spin + k * math.pi / 4, 0.42, false, dash);
    }

    // Orbiting dots in the five game arrow colors
    for (int i = 0; i < _palette.length; i++) {
      final ang = -t * 2 * math.pi + i * 2 * math.pi / _palette.length;
      final pulse = 2.6 + math.sin(t * 2 * math.pi * 2 + i) * 0.7;
      canvas.drawCircle(
        c + Offset(math.cos(ang), math.sin(ang)) * 62,
        pulse,
        Paint()..color = _palette[i].withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MottoRingPainter old) => old.t != t;
}

class _FloatingSplashLogo extends StatefulWidget {
  const _FloatingSplashLogo();
  @override
  State<_FloatingSplashLogo> createState() => _FloatingSplashLogoState();
}

class _FloatingSplashLogoState extends State<_FloatingSplashLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(begin: -12, end: 12).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: child,
      ),
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

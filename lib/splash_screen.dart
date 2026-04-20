import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'game_data.dart';
import 'game_board.dart';
import 'level_selection_screen.dart';
import 'settings_screen.dart';

class SplashScreenSequence extends StatefulWidget {
  const SplashScreenSequence({super.key});

  @override
  State<SplashScreenSequence> createState() => _SplashScreenSequenceState();
}

class _SplashScreenSequenceState extends State<SplashScreenSequence> with TickerProviderStateMixin {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1E56D0),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 25),
        const Text(
          "ARROWX",
          style: TextStyle(
            fontSize: 48,
            letterSpacing: 8,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildMotto() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_moon_rounded, size: 60, color: Color(0xFF1E56D0)),
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

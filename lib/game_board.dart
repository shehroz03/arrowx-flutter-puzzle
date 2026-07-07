import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'grid_painter.dart';
import 'set_free_reveal.dart';
import 'settings_provider.dart';
import 'shop_provider.dart';
import 'shop_screen.dart';
import 'sound_manager.dart';
import 'theme_backdrop.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  static const double defaultCellSize = 28.0;
  const GameBoardScreen({super.key});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  TransformationController _transformationController = TransformationController();
  int _lastLevelSetup = -1;
  void _showThemePicker(BuildContext context, WidgetRef ref, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: settings.currentTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Theme", 
                style: TextStyle(color: settings.currentTheme.ui, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                height: 116,
                child: Consumer(builder: (context, ref2, _) {
                  final shop = ref2.watch(shopProvider);
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gameThemes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (ctx2, i) {
                      final t = gameThemes[i];
                      final isSelected = settings.themeIndex == i;
                      final locked = !shop.isUnlocked(i);
                      return GestureDetector(
                        onTap: () {
                          if (locked) {
                            Navigator.pop(ctx);
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ShopScreen()));
                            return;
                          }
                          ref.read(settingsProvider.notifier).setTheme(i);
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: t.bg,
                                gradient: t.gradient != null
                                    ? LinearGradient(colors: t.gradient!)
                                    : null,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? t.arrow : Colors.grey.withValues(alpha: 0.3),
                                  width: 3
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: t.arrow.withValues(alpha: 0.5), blurRadius: 10)
                                ] : [],
                              ),
                              child: locked
                                  ? Icon(Icons.lock_rounded,
                                      color: t.arrow.withValues(alpha: 0.8), size: 24)
                                  : Icon(Icons.check,
                                      color: isSelected ? t.arrow : Colors.transparent),
                            ),
                            const SizedBox(height: 8),
                            Text(t.name,
                                style: TextStyle(color: settings.currentTheme.ui, fontSize: 12)),
                            if (locked)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                Text(' ${t.price}',
                                    style: TextStyle(
                                        color: settings.currentTheme.ui.withValues(alpha: 0.8),
                                        fontSize: 11, fontWeight: FontWeight.bold)),
                              ]),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsProvider);
          final theme = settings.currentTheme;
          return Dialog(
            backgroundColor: theme.bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Settings", 
                    style: TextStyle(
                      color: theme.ui, 
                      fontSize: 26, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 1. Sound Toggle
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(settings.isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: theme.ui, size: 28),
                    title: Text("Sound", style: TextStyle(color: theme.ui, fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () => ref.read(settingsProvider.notifier).toggleSound(!settings.isSoundOn),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(settings.isSoundOn ? "ON" : "OFF", 
                          style: TextStyle(
                            color: settings.isSoundOn ? Colors.greenAccent.shade700 : Colors.redAccent, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14,
                          )),
                        const SizedBox(width: 8),
                        Switch(
                          thumbColor: WidgetStateProperty.resolveWith((states) => 
                            states.contains(WidgetState.selected) ? Colors.greenAccent.shade700 : null),
                          trackColor: WidgetStateProperty.resolveWith((states) => 
                            states.contains(WidgetState.selected) ? Colors.greenAccent.shade700.withValues(alpha: 0.5) : null),
                          value: settings.isSoundOn,
                          onChanged: (v) => ref.read(settingsProvider.notifier).toggleSound(v),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.ui.withValues(alpha: 0.15), height: 16),
                  
                  // 2. Background Music Toggle
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(settings.isMusicOn ? Icons.music_note_rounded : Icons.music_off_rounded, color: theme.ui, size: 28),
                    title: Text("Music", style: TextStyle(color: theme.ui, fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () => ref.read(settingsProvider.notifier).toggleMusic(!settings.isMusicOn),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(settings.isMusicOn ? "ON" : "OFF", 
                          style: TextStyle(
                            color: settings.isMusicOn ? Colors.greenAccent.shade700 : Colors.redAccent, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14,
                          )),
                        const SizedBox(width: 8),
                        Switch(
                          thumbColor: WidgetStateProperty.resolveWith((states) => 
                            states.contains(WidgetState.selected) ? Colors.greenAccent.shade700 : null),
                          trackColor: WidgetStateProperty.resolveWith((states) => 
                            states.contains(WidgetState.selected) ? Colors.greenAccent.shade700.withValues(alpha: 0.5) : null),
                          value: settings.isMusicOn,
                          onChanged: (v) => ref.read(settingsProvider.notifier).toggleMusic(v),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.ui.withValues(alpha: 0.15), height: 16),
                  
                  // 3. Restart Level
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.refresh_rounded, color: theme.ui, size: 28),
                    title: Text("Restart Level", style: TextStyle(color: theme.ui, fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ref.read(gameStateProvider.notifier).tryAgain();
                      Navigator.pop(context);
                    },
                  ),
                  Divider(color: theme.ui.withValues(alpha: 0.15), height: 16),
                  
                  // 4. Exit to Home
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.home_rounded, color: theme.ui, size: 28),
                    title: Text("Exit to Home", style: TextStyle(color: theme.ui, fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () {
                      SoundManager().stopBGM();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundManager().startBGM();
    });
  }

  @override
  void dispose() {
    SoundManager().stopBGM();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final settings = ref.watch(settingsProvider);
    final theme = settings.currentTheme;
    final notifier = ref.read(gameStateProvider.notifier);
    // Dynamic cell size:
    // Level 1-5: small compact arrows
    // Level 6+: auto-fit to screen so arrows fill the full display like a dense maze
    final int lvl = gameState.level;
    final gs = gameState.gridSize;
    double cs;
    if (lvl <= 5) {
      cs = 22.0; // Small, simple arrows for easy early levels
    } else {
      // Levels 6 to 20: Arrows become larger, longer, and denser
      // Smoothly grow cell size from 30.0 to 50.0
      double t = ((lvl - 5) / 15.0).clamp(0.0, 1.0);
      cs = 30.0 + (t * 20.0); // 30.0 -> 50.0 (large, long arrows)
    }


    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // Animated gradient + drifting particles for premium shop themes
          if (theme.isPremium)
            Positioned.fill(
              child: RepaintBoundary(child: PremiumBackdrop(theme: theme)),
            ),
          SafeArea(
            child: Column(
            children: [
              // 1. Custom Premium Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button with soft circular background
                    Container(
                      decoration: BoxDecoration(
                        color: theme.ui.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: theme.ui, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    // Center Level Title & Badge
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gameState.isCustomLevel
                              ? (gameState.shapeName.isNotEmpty ? gameState.shapeName : 'My Fun')
                              : 'Level ${gameState.level}',
                          style: TextStyle(
                            color: gameState.isHardStage ? Colors.orangeAccent : theme.ui,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 0.5,
                            shadows: gameState.isHardStage ? [
                              const Shadow(color: Colors.orange, blurRadius: 10)
                            ] : null,
                          ),
                        ),
                        if (gameState.isHardStage)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.4), blurRadius: 8)],
                            ),
                            child: const Text(
                              'HARDCORE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                          )
                        else if (gameState.level >= 5)
                          Text(
                            'Advanced',
                            style: TextStyle(color: theme.ui.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    
                    // Right Action Buttons (Palette & Settings)
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.ui.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.palette_outlined, color: theme.ui, size: 20),
                            onPressed: () => _showThemePicker(context, ref, settings),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.ui.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.settings_outlined, color: theme.ui, size: 20),
                            onPressed: () => _showSettingsMenu(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 2. Beautiful Stats Card (Lives & Timer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.ui.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: theme.ui.withValues(alpha: 0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lives Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LIVES",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: theme.ui.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(gameState.level > 30 ? 4 : 3, (i) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AnimatedHeartWidget(
                                isAlive: i < gameState.chances,
                              ),
                            )),
                          ),
                        ],
                      ),
                      
                      // Timer Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "TIME LEFT",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: gameState.timeRemainingSeconds <= 10 ? Colors.redAccent : theme.ui.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: gameState.timeRemainingSeconds <= 10 ? Colors.redAccent : theme.ui,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${gameState.timeRemainingSeconds ~/ 60}:${(gameState.timeRemainingSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: gameState.timeRemainingSeconds <= 10 ? Colors.redAccent : theme.ui,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (gameState.gameMode == GameMode.colorMatch && gameState.targetColorIndex != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _getArrowColor(gameState.targetColorIndex!, Colors.white).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getArrowColor(gameState.targetColorIndex!, Colors.white), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("TARGET COLOR: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: _getArrowColor(gameState.targetColorIndex!, Colors.white),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int lvlMinX = 0, lvlMinY = 0, lvlMaxX = gs, lvlMaxY = gs;
                        if (gameState.arrows.isNotEmpty) {
                          lvlMinX = math.min(0, gameState.arrows.map((a) => a.bounds[0]).reduce(math.min));
                          lvlMinY = math.min(0, gameState.arrows.map((a) => a.bounds[1]).reduce(math.min));
                          lvlMaxX = math.max(gs, gameState.arrows.map((a) => a.bounds[2]).reduce(math.max));
                          lvlMaxY = math.max(gs, gameState.arrows.map((a) => a.bounds[3]).reduce(math.max));
                        }
                        
                        final gridW = (lvlMaxX - lvlMinX) * cs;
                        final gridH = (lvlMaxY - lvlMinY) * cs;

                        if (_lastLevelSetup != gameState.level) {
                          _lastLevelSetup = gameState.level;
                          final double scaleX = constraints.maxWidth / gridW;
                          final double scaleY = constraints.maxHeight / gridH;
                          final double initialScale = math.min(scaleX, scaleY).clamp(0.05, 1.0);
                          final double offsetX = (constraints.maxWidth - (gridW * initialScale)) / 2;
                          final double offsetY = (constraints.maxHeight - (gridH * initialScale)) / 2;
                          
                          final initialMatrix = Matrix4.identity()
                            ..translateByDouble(offsetX, offsetY, 0.0, 1.0)
                            ..scaleByDouble(initialScale, initialScale, initialScale, 1.0);
                            
                          _transformationController = TransformationController(initialMatrix);
                        }

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          boundaryMargin: const EdgeInsets.all(2000),
                          minScale: 0.05,
                          maxScale: 5.0,
                          constrained: false, // Changed from true to allow zooming/panning large grids
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(gameState.level), // Restart animation on level change
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        if (value == 1.0) return child!;
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: gridW,
                        height: gridH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -lvlMinX * cs,
                              top: -lvlMinY * cs,
                              width: gs * cs,
                              height: gs * cs,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: GridPainter(
                                    gridSize: gs, 
                                    cellSize: cs, 
                                    dotColor: theme.dot,
                                    isHardStage: gameState.isHardStage,
                                    occupiedCells: gameState.allOccupiedCells,
                                    revealedCells: gameState.revealedCells,
                                  ),
                                ),
                              ),
                            ),
                            if (settings.isGuidelineOn)
                              Positioned(
                                left: -lvlMinX * cs,
                                top: -lvlMinY * cs,
                                width: gs * cs,
                                height: gs * cs,
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: GuidelinePainter(gridSize: gs, cellSize: cs, color: theme.dot),
                                  ),
                                ),
                              ),
                            ...gameState.arrows.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final arrow = entry.value;
                              final ab = arrow.bounds;
                              final int minX = ab[0], minY = ab[1], maxX = ab[2], maxY = ab[3];
                              
                              // INCREASED HIT AREA: Use full cellSize as padding
                              double pad = cs; 
                              double targetLeft = (minX - lvlMinX) * cs - pad;
                              double targetTop = (minY - lvlMinY) * cs - pad;
                              double width = (maxX - minX) * cs + (pad * 2);
                              double height = (maxY - minY) * cs + (pad * 2);

                              return AnimatedPositioned(
                                key: ValueKey(arrow.id),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                left: targetLeft, // Use final positions directly
                                top: targetTop,
                                width: width,
                                height: height,
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey('${gameState.level}_${arrow.id}'),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 600 + math.min(index * 15, 1200).toInt()),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    if (value == 1.0) return child!;
                                    final dir = arrow.flyDirection;
                                    final slide = 26.0 * (1 - value);
                                    return Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: Transform.translate(
                                        offset: Offset(-dir[0] * slide, -dir[1] * slide),
                                        child: Transform.rotate(
                                          angle: (1 - value) * (arrow.id.isEven ? 0.09 : -0.09),
                                          child: Transform.scale(
                                            scale: 0.5 + (0.5 * value),
                                            child: child!,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          child: ArrowWidget(
                                            arrow: arrow,
                                            cellSize: cs,
                                            offsetX: minX,
                                            offsetY: minY,
                                            arrowColor: _getArrowColor(arrow.colorIndex, theme.arrow),
                                            padding: pad,
                                            isBigArrow: gameState.level > 4,
                                            trailEffect: theme.trailEffect ?? (gameState.level - 1) % 6,
                                            gridSize: gs,
                                            onTap: () {
                                              if (settings.isVibrationOn) {
                                                HapticFeedback.lightImpact();
                                              }
                                              notifier.onArrowTapped(arrow);
                                            },
                                          ),
                                        ),
                                      ),
                                      // Tutorial Hand Animation
                                      if (gameState.level <= 2 && !arrow.isSolved && _isHintArrow(gameState.level, arrow.id))
                                        const Positioned(
                                          top: 0,
                                          left: 0,
                                          child: _TutorialHand(),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
            ],
          ),
          ),
          if (gameState.isLevelComplete)
            Positioned.fill(
              child: _CompletionSequence(gameState: gameState, notifier: notifier),
            ),
          if (gameState.gameOver)
            Positioned.fill(
              child: _GameOverOverlay(gameState: gameState, notifier: notifier),
            ),
        ],
      ),
    );
  }
}

Color _getArrowColor(int index, Color defaultColor) {
  const palette = [
    Color(0xFFE5B142), // Gold
    Color(0xFF4A90E2), // Blue
    Color(0xFF9B59B6), // Purple
    Color(0xFFE67E22), // Orange
    Color(0xFF2ECC71), // Green
  ];
  if (index < 0 || index >= palette.length) return defaultColor;
  return palette[index];
}

class _Particle {
  final double x, y, size, delay;
  final Color color;
  const _Particle({required this.x, required this.y, required this.size, required this.delay, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      final px = p.x * size.width;
      final py = p.y * size.height - t * size.height * 0.45;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size * (1.0 - t * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}

/// Orchestrates level completion: first the "Set It Free" shape reveal
/// (skippable with a tap), then the score card.
class _CompletionSequence extends StatefulWidget {
  final GameState gameState;
  final GameNotifier notifier;
  const _CompletionSequence({required this.gameState, required this.notifier});

  @override
  State<_CompletionSequence> createState() => _CompletionSequenceState();
}

class _CompletionSequenceState extends State<_CompletionSequence> {
  bool _showCard = false;

  @override
  void initState() {
    super.initState();
    final hasReveal = widget.gameState.customMask.isNotEmpty ||
        widget.gameState.shapeName.isNotEmpty;
    if (!hasReveal || widget.gameState.gameMode == GameMode.speedRush) {
      _showCard = true;
    }
  }

  void _finishReveal() {
    if (mounted && !_showCard) setState(() => _showCard = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showCard) {
      return _LevelCompleteOverlay(
          gameState: widget.gameState, notifier: widget.notifier);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finishReveal,
      child: SetFreeReveal(
        shapeName: widget.gameState.shapeName,
        customMask: widget.gameState.customMask,
        gridSize: widget.gameState.gridSize,
        onFinished: _finishReveal,
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatefulWidget {
  final GameState gameState;
  final GameNotifier notifier;
  const _LevelCompleteOverlay({required this.gameState, required this.notifier});

  @override
  State<_LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<_LevelCompleteOverlay> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _btnPulseCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _cardOffset;
  late Animation<double> _cardFade;
  late Animation<double> _star1Anim;
  late Animation<double> _star2Anim;
  late Animation<double> _star3Anim;
  late Animation<double> _statsOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnScale;
  late Animation<double> _glowPulse;
  late Animation<double> _btnPulse;

  final List<_Particle> _particles = [];
  final _rng = math.Random(7);

  void _go() {
    if (widget.gameState.isCustomLevel) {
      // Apna Maze / editor test play: return to the previous screen
      Navigator.of(context).pop();
      return;
    }
    widget.notifier.loadLevel(widget.gameState.level + 1);
  }

  @override
  void initState() {
    super.initState();

    const particleColors = [
      Colors.amber, Colors.amberAccent, Colors.orangeAccent,
      Colors.yellowAccent, Colors.white,
    ];
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.55 + 0.05,
        size: _rng.nextDouble() * 5 + 3,
        delay: _rng.nextDouble() * 0.35,
        color: particleColors[_rng.nextInt(particleColors.length)],
      ));
    }

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _btnPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));

    _cardOffset = Tween<double>(begin: 90, end: 0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.28, curve: Curves.easeOut)));

    // Center star first, then wings
    _star2Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.20, 0.52, curve: Curves.elasticOut)));
    _star1Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.36, 0.66, curve: Curves.elasticOut)));
    _star3Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.44, 0.74, curve: Curves.elasticOut)));

    _statsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.50, 0.72, curve: Curves.easeIn)));

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.60, 0.84, curve: Curves.easeIn)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.60, 0.84, curve: Curves.easeOutCubic)));

    _btnScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.78, 1.0, curve: Curves.elasticOut)));

    _glowPulse = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _btnPulse = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _btnPulseCtrl, curve: Curves.easeInOut));

    _bgCtrl.forward();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _contentCtrl.forward();
        _particleCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    _btnPulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bgCtrl, _contentCtrl, _pulseCtrl, _btnPulseCtrl, _particleCtrl]),
      builder: (context, _) {
        return Stack(
          children: [
            // Frosted-glass backdrop
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 7.0 * _bgFade.value,
                  sigmaY: 7.0 * _bgFade.value,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.68 * _bgFade.value),
                ),
              ),
            ),

            // Confetti particles
            if (_particleCtrl.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlePainter(_particles, _particleCtrl.value),
                  ),
                ),
              ),

            // Close button
            Positioned(
              top: 44,
              right: 16,
              child: Opacity(
                opacity: _bgFade.value,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 32),
                  onPressed: () { SoundManager().playTap(); _go(); },
                ),
              ),
            ),

            // Main card
            Center(
              child: Transform.translate(
                offset: Offset(0, _cardOffset.value),
                child: Opacity(
                  opacity: _cardFade.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1C1C2E), Color(0xFF12122A)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.25 + 0.25 * _glowPulse.value),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.12 * _glowPulse.value),
                            blurRadius: 48,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stats row (lives + time)
                            Opacity(
                              opacity: _statsOpacity.value,
                              child: _buildStatsCard(),
                            ),
                            const SizedBox(height: 22),

                            // Stars
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStar(1, 72, _star1Anim.value, -0.24),
                                const SizedBox(width: 6),
                                _buildStar(2, 108, _star2Anim.value, 0.0),
                                const SizedBox(width: 6),
                                _buildStar(3, 72, _star3Anim.value, 0.24),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Title
                            FadeTransition(
                              opacity: _textOpacity,
                              child: SlideTransition(
                                position: _textSlide,
                                child: ShaderMask(
                                  shaderCallback: (rect) => const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFD54F), Colors.white],
                                    stops: [0.0, 0.5, 1.0],
                                  ).createShader(rect),
                                  child: Text(
                                    'LEVEL ${widget.gameState.level}\nCLEARED',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Next Level button
                            Transform.scale(
                              scale: _btnScale.value * _btnPulse.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.45 + 0.25 * _glowPulse.value),
                                      blurRadius: 18 + 10 * _glowPulse.value,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () { SoundManager().playTap(); _go(); },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 52, vertical: 16),
                                      child: Text(
                                        'NEXT LEVEL',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          letterSpacing: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final gs = widget.gameState;
    final livesCount = gs.level > 30 ? 4 : 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LIVES',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(livesCount, (i) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < gs.chances ? Icons.favorite : Icons.favorite_border,
                    color: i < gs.chances ? Colors.redAccent : Colors.grey.shade700,
                    size: 22,
                  ),
                )),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TIME LEFT',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${gs.timeRemainingSeconds ~/ 60}:${(gs.timeRemainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStar(int threshold, double size, double scale, double tiltAngle) {
    final bool active = widget.gameState.earnedStars >= threshold;
    final double s = scale.clamp(0.0, 1.0) * (active ? 1.0 : 0.82);
    return Transform.scale(
      scale: s,
      child: Transform.rotate(
        angle: tiltAngle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: size * 1.5,
                height: size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.amber.withValues(alpha: 0.32 * _glowPulse.value),
                    Colors.transparent,
                  ]),
                ),
              ),
            Icon(
              Icons.star_rounded,
              color: active ? const Color(0xFFFFD700) : Colors.grey.shade700,
              size: size,
              shadows: active
                  ? [
                      Shadow(color: Colors.amber.withValues(alpha: 0.9 * _glowPulse.value), blurRadius: 18),
                      Shadow(color: Colors.orangeAccent.withValues(alpha: 0.55 * _glowPulse.value), blurRadius: 38),
                    ]
                  : const [],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isHintArrow(int level, int arrowId) {
  if (level == 1) return arrowId == 1; // Suggest the first left arrow
  if (level == 2) return arrowId == 5; // Suggest the first down arrow
  return false;
}

class _TutorialHand extends StatefulWidget {
  const _TutorialHand();

  @override
  State<_TutorialHand> createState() => _TutorialHandState();
}

class _TutorialHandState extends State<_TutorialHand> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _offsetAnim = Tween<Offset>(begin: const Offset(0.2, 0.2), end: const Offset(0.5, 0.5))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnim,
      builder: (ctx, child) {
        return Transform.translate(
          offset: Offset(_offsetAnim.value.dx * 50, _offsetAnim.value.dy * 50),
          child: child,
        );
      },
      child: const IgnorePointer(
        child: Icon(Icons.touch_app_rounded, color: Colors.blueAccent, size: 40),
      ),
    );
  }
}

class StarryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    // Draw some static stars for a cosmic neon vibe
    final offsets = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.6),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.9),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.85),
    ];
    for (var offset in offsets) {
      canvas.drawCircle(offset, 1.5, paint);
      canvas.drawCircle(offset, 3.0, paint..color = Colors.white.withValues(alpha: 0.05));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GameOverOverlay extends StatefulWidget {
  final GameState gameState;
  final GameNotifier notifier;
  const _GameOverOverlay({required this.gameState, required this.notifier});

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTimeUp = widget.gameState.outOfTime;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 8,
                  )
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTimeUp ? Icons.timer_off_rounded : Icons.heart_broken_rounded,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isTimeUp ? "TIME'S UP!" : "OUT OF MOVES!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTimeUp ? "You ran out of time." : "You lost all your lives.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 260,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 6,
                          shadowColor: Colors.redAccent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          SoundManager().playTap();
                          widget.notifier.tryAgain();
                        },
                        child: const Text(
                          "TRY AGAIN",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedHeartWidget extends StatefulWidget {
  final bool isAlive;
  const AnimatedHeartWidget({super.key, required this.isAlive});

  @override
  State<AnimatedHeartWidget> createState() => _AnimatedHeartWidgetState();
}

class _AnimatedHeartWidgetState extends State<AnimatedHeartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
    ]).animate(_ctrl);
    
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(AnimatedHeartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAlive && !widget.isAlive) {
      // Life lost -> trigger breaking animation
      _ctrl.forward(from: 0.0);
    } else if (!oldWidget.isAlive && widget.isAlive) {
      // Life restored
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAlive) {
      return const Icon(Icons.favorite, color: Colors.redAccent, size: 30);
    } else {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          if (_ctrl.isAnimating) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _fadeAnim.value,
                child: const Icon(Icons.heart_broken, color: Colors.redAccent, size: 30),
              ),
            );
          } else {
            return Icon(Icons.favorite_border, color: Colors.grey.withValues(alpha: 0.3), size: 30);
          }
        },
      );
    }
  }
}

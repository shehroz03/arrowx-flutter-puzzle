import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'grid_painter.dart';
import 'settings_provider.dart';
import 'sound_manager.dart';

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
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: gameThemes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) {
                    final t = gameThemes[i];
                    final isSelected = settings.themeIndex == i;
                    return GestureDetector(
                      onTap: () {
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
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? t.arrow : Colors.grey.withValues(alpha: 0.3), 
                                width: 3
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: t.arrow.withValues(alpha: 0.5), blurRadius: 10)
                              ] : [],
                            ),
                            child: Icon(Icons.check, color: isSelected ? t.arrow : Colors.transparent),
                          ),
                          const SizedBox(height: 8),
                          Text(t.name, style: TextStyle(color: settings.currentTheme.ui, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
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
          return AlertDialog(
            backgroundColor: settings.currentTheme.bg,
            title: Text("Settings", style: TextStyle(color: settings.currentTheme.ui)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(settings.isSoundOn ? Icons.volume_up : Icons.volume_off, color: settings.currentTheme.ui),
                  title: Text("Sound", style: TextStyle(color: settings.currentTheme.ui)),
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
                const Divider(),
                ListTile(
                  leading: Icon(Icons.refresh, color: settings.currentTheme.ui),
                  title: Text("Restart Level", style: TextStyle(color: settings.currentTheme.ui)),
                  onTap: () {
                    ref.read(gameStateProvider.notifier).tryAgain();
                    Navigator.pop(context);
                  },
                ),
              ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.ui),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Level ${gameState.level}',
              style: TextStyle(
                color: gameState.isHardStage ? Colors.orangeAccent : theme.ui, 
                fontWeight: FontWeight.bold, 
                fontSize: 20,
                shadows: gameState.isHardStage ? [
                  const Shadow(color: Colors.orange, blurRadius: 10)
                ] : null,
              )),
            if (gameState.isHardStage)
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('HARDCORE', 
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              )
            else if (gameState.level >= 5)
              Text('Advanced', style: TextStyle(color: theme.ui.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: theme.ui, size: 24),
            onPressed: () => _showThemePicker(context, ref, settings),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.ui, size: 24),
            onPressed: () => _showSettingsMenu(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          if (gameState.level >= 11 && gameState.level <= 14)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: StarryBackgroundPainter(),
                ),
              ),
            ),
          SafeArea(
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(gameState.level > 30 ? 4 : 3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AnimatedHeartWidget(
                          isAlive: i < gameState.chances,
                        ),
                      )),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined, 
                          color: gameState.timeRemainingSeconds <= 10 ? Colors.red : theme.ui, 
                          size: 28
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${gameState.timeRemainingSeconds ~/ 60}:${(gameState.timeRemainingSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: gameState.timeRemainingSeconds <= 10 ? Colors.red : theme.ui,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                            ..translate(offsetX, offsetY)
                            ..scale(initialScale);
                            
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

                              // Center coordinates of the grid
                              double centerLeft = (gs * cs / 2) - (width / 2);
                              double centerTop = (gs * cs / 2) - (height / 2);

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
                                    return Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: Transform.scale(
                                        scale: 0.5 + (0.5 * value),
                                        child: child!,
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
                                            arrowColor: gameState.level > 10 
                                                ? _getArrowColor(arrow.id % 5, theme.arrow) 
                                                : _getArrowColor(arrow.colorIndex, theme.arrow),
                                            padding: pad,
                                            isBigArrow: gameState.level > 10,
                                            isNeon: gameState.level >= 11 && gameState.level <= 14,
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
                            }).toList(),
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
              child: _LevelCompleteOverlay(gameState: gameState, notifier: notifier),
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
  late Animation<double> _star1Anim;
  late Animation<double> _star2Anim;
  late Animation<double> _star3Anim;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _bgCtrl.forward();
    _contentCtrl.forward();

    _star1Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.1, 0.4, curve: Curves.elasticOut)));
    _star2Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.3, 0.6, curve: Curves.elasticOut)));
    _star3Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.5, 0.8, curve: Curves.elasticOut)));

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.6, 0.9, curve: Curves.easeIn)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic)));

    _btnScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.8, 1.0, curve: Curves.elasticOut)));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.75 * _bgCtrl.value),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStar(1, 70, _star1Anim.value, -0.3),
                        const SizedBox(width: 10),
                        _buildStar(2, 110, _star2Anim.value, 0.0),
                        const SizedBox(width: 10),
                        _buildStar(3, 70, _star3Anim.value, 0.3),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Text(
                          'LEVEL ${widget.gameState.level}\nCLEARED',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: 2,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8))],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Transform.scale(
                      scale: _btnScale.value,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          elevation: 10,
                          shadowColor: Colors.amber.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          SoundManager().playTap();
                          widget.notifier.loadLevel(widget.gameState.level + 1);
                        },
                        child: const Text("NEXT LEVEL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Opacity(
                  opacity: _bgCtrl.value,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                    onPressed: () {
                      SoundManager().playTap();
                      widget.notifier.loadLevel(widget.gameState.level + 1);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStar(int threshold, double size, double scale, double tiltAngle) {
    final bool active = widget.gameState.earnedStars >= threshold;
    return Transform.scale(
      scale: active ? scale : scale * 0.8,
      child: Transform.rotate(
        angle: tiltAngle,
        child: Opacity(
          opacity: scale.clamp(0.0, 1.0) * (active ? 1.0 : 0.4),
          child: Icon(
            Icons.star_rounded, 
            color: active ? Colors.amber : Colors.grey.shade400, 
            size: size,
            shadows: active ? const [
              Shadow(color: Colors.amberAccent, blurRadius: 20),
              Shadow(color: Colors.orangeAccent, blurRadius: 40)
            ] : [],
          ),
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
                    width: double.infinity,
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

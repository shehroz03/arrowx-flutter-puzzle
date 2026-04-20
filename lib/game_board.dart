import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'grid_painter.dart';
import 'settings_provider.dart';
import 'sound_manager.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  static const double cellSize = 28.0;
  const GameBoardScreen({super.key});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
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

  void _showSettingsMenu(BuildContext context, WidgetRef ref, SettingsState settings, GameState gameState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: settings.currentTheme.bg,
        title: Text("Settings", style: TextStyle(color: settings.currentTheme.ui)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(settings.isSoundOn ? Icons.volume_up : Icons.volume_off, color: settings.currentTheme.ui),
              title: Text("Sound", style: TextStyle(color: settings.currentTheme.ui)),
              trailing: Switch(
                value: settings.isSoundOn,
                onChanged: (v) {
                  ref.read(settingsProvider.notifier).toggleSound(v);
                  if (v) {
                    SoundManager().toggle(); 
                  } else if (!SoundManager().isMuted) {
                    SoundManager().toggle();
                  }
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: settings.currentTheme.ui),
              title: Text("Restart Level", style: TextStyle(color: settings.currentTheme.ui)),
              onTap: () {
                ref.read(gameStateProvider.notifier).tryAgain();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final settings = ref.watch(settingsProvider);
    final theme = settings.currentTheme;
    final notifier = ref.read(gameStateProvider.notifier);
    const cs = GameBoardScreen.cellSize;
    final gs = gameState.gridSize;

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
          children: [
            Text('Level ${gameState.level}',
              style: TextStyle(color: theme.ui, fontWeight: FontWeight.bold, fontSize: 20)),
            if (gameState.level >= 5)
              Text('Hard', style: TextStyle(color: theme.ui.withValues(alpha: 0.7), fontSize: 12)),
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
            onPressed: () => _showSettingsMenu(context, ref, settings, gameState),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.water_drop,
                          color: i < gameState.chances
                              ? const Color(0xFF4A90D9)
                              : Colors.grey.shade300,
                          size: 30,
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
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(400),
                  minScale: 0.3,
                  maxScale: 5.0,
                  constrained: false,
                  child: Center(
                    child: SizedBox(
                      width: gs * cs,
                      height: gs * cs,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(gridSize: gs, cellSize: cs, dotColor: theme.dot),
                            ),
                          ),
                          if (settings.isGuidelineOn)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GuidelinePainter(gridSize: gs, cellSize: cs, color: theme.dot),
                              ),
                            ),
                          ...gameState.arrows.map((arrow) {
                            final b = arrow.bounds;
                            final int minX = b[0], minY = b[1], maxX = b[2], maxY = b[3];
                            double pad = cs / 2;
                            double left = minX * cs - pad;
                            double top = minY * cs - pad;
                            double width = (maxX - minX) * cs + cs;
                            double height = (maxY - minY) * cs + cs;

                            if (arrow.isSolved) {
                              final dir = arrow.flyDirection;
                              // Move the entire box off-screen to prevent clipping
                              left += dir[0] * gs * cs * 2;
                              top += dir[1] * gs * cs * 2;
                            }

                            return AnimatedPositioned(
                              key: ValueKey(arrow.id),
                              duration: Duration(milliseconds: arrow.isSolved ? 1000 : 350),
                              curve: arrow.isSolved ? Curves.easeInCubic : Curves.easeInBack,
                              left: left,
                              top: top,
                              width: width,
                              height: height,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: arrow.isSolved ? 1.0 : 0.0),
                                duration: Duration(milliseconds: arrow.isSolved ? 1000 : 350),
                                curve: Curves.easeInOutCubic,
                                builder: (context, flyValue, child) {
                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: arrow.isSolved && flyValue > 0.9 ? 0.0 : 1.0,
                                    child: ArrowSegmentWidget(
                                      arrow: arrow,
                                      cellSize: cs,
                                      offsetX: minX,
                                      offsetY: minY,
                                      arrowColor: theme.arrow,
                                      flyProgress: flyValue,
                                      onTap: () {
                                        if (settings.isVibrationOn) {
                                          HapticFeedback.lightImpact();
                                        }
                                        notifier.onArrowTapped(arrow);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (gameState.gameOver)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  child: Column(children: [
                    Text(gameState.outOfTime ? "TIME'S UP!" : "OUT OF MOVES!",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => notifier.tryAgain(),
                      child: const Text("TRY AGAIN"),
                    ),
                  ]),
                ),
            ],
          ),
          if (gameState.isLevelComplete)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.6 * value.clamp(0.0, 1.0)),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Center(
                          child: Transform.scale(
                            scale: value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AnimatedStarsRow(earnedStars: gameState.earnedStars),
                                const SizedBox(height: 20),
                                Text(
                                  'LEVEL ${gameState.level}\nCLEARED',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  onPressed: () {
                                    SoundManager().playTap();
                                    notifier.loadLevel(gameState.level + 1);
                                  },
                                  child: const Text("NEXT LEVEL", 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 20,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                            onPressed: () {
                              SoundManager().playTap();
                              notifier.loadLevel(gameState.level + 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedStarsRow extends StatelessWidget {
  final int earnedStars;
  const _AnimatedStarsRow({required this.earnedStars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStar(1, 60),
        _buildStar(2, 100),
        _buildStar(3, 60),
      ],
    );
  }

  Widget _buildStar(int threshold, double size) {
    final bool active = earnedStars >= threshold;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: active ? 1.0 : 0.6),
      duration: Duration(milliseconds: 400 + (threshold * 300)),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: Icon(
              Icons.star_rounded, 
              color: active ? Colors.amber : Colors.grey.shade800, 
              size: size,
              shadows: active ? const [Shadow(color: Colors.amber, blurRadius: 20)] : [],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_provider.dart';
import 'grid_painter.dart';
import 'game_state.dart';
import 'game_board.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const double cs = 28.0;

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final gs = es.gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Level Editor',
              style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: es.arrows.isEmpty
                    ? Colors.grey.shade200
                    : es.isSolvable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: es.arrows.isEmpty
                      ? Colors.grey
                      : es.isSolvable ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    es.arrows.isEmpty
                        ? Icons.circle_outlined
                        : es.isSolvable ? Icons.check_circle : Icons.error,
                    color: es.arrows.isEmpty
                        ? Colors.grey
                        : es.isSolvable ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    es.arrows.isEmpty ? 'Empty' : es.isSolvable ? 'Solvable' : 'Locked!',
                    style: TextStyle(
                      color: es.arrows.isEmpty
                          ? Colors.grey.shade600
                          : es.isSolvable ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildToolbar(es, notifier),
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(400),
              minScale: 0.3,
              maxScale: 5.0,
              constrained: false,
              child: Center(
                child: GestureDetector(
                  onTapUp: (details) {
                    final lp = details.localPosition;
                    int dotX = (lp.dx / cs).round();
                    int dotY = (lp.dy / cs).round();
                    if (dotX >= 0 && dotX < gs && dotY >= 0 && dotY < gs) {
                      notifier.onDotTapped(dotX, dotY);
                    }
                  },
                  child: SizedBox(
                    width: gs * cs,
                    height: gs * cs,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(gridSize: gs, cellSize: cs, dotColor: const Color(0xFFCDBBA7)),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GuidelinePainter(gridSize: gs, cellSize: cs, color: Colors.brown),
                          ),
                        ),
                        ...es.arrows.map((arrow) {
                          final b = arrow.bounds;
                          final int minX = b[0], minY = b[1], maxX = b[2], maxY = b[3];
                          double pad = cs / 2;
                          double left = minX * cs - pad;
                          double top = minY * cs - pad;
                          double width = (maxX - minX) * cs + cs;
                          double height = (maxY - minY) * cs + cs;
                          bool isSelected = es.selectedArrowId == arrow.id;

                          return Positioned(
                            key: ValueKey('editor_${arrow.id}'),
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: GestureDetector(
                              onTap: () {
                                notifier.cycleDirection(arrow.id);
                              },
                              onLongPress: () {
                                notifier.removeArrow(arrow.id);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: isSelected ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue.withValues(alpha: 0.05),
                                ) : null,
                                child: CustomPaint(
                                  painter: ArrowPathPainter(
                                    arrow: arrow,
                                    cellSize: cs,
                                    offsetX: minX,
                                    offsetY: minY,
                                    arrowColor: const Color(0xFF7B5B3A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildBottomBar(es, notifier),
        ],
      ),
    );
  }

  Widget _buildToolbar(EditorState es, EditorNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.brown.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: Colors.brown.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Dir ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 6),
              ...['right', 'down', 'left', 'up'].map((dir) {
                IconData icon;
                switch (dir) {
                  case 'right': icon = Icons.arrow_forward; break;
                  case 'left': icon = Icons.arrow_back; break;
                  case 'down': icon = Icons.arrow_downward; break;
                  default: icon = Icons.arrow_upward;
                }
                bool isActive = es.currentDirection == dir;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => notifier.setCurrentDirection(dir),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF7B5B3A) : Colors.brown.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isActive ? [
                          BoxShadow(color: Colors.brown.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                        ] : null,
                      ),
                      child: Icon(icon, color: isActive ? Colors.white : Colors.brown, size: 18),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${es.arrows.length} arrows',
                  style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Grid ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.brown.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${es.gridSize}×${es.gridSize}',
                  style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF7B5B3A),
                    inactiveTrackColor: Colors.brown.withValues(alpha: 0.15),
                    thumbColor: const Color(0xFF7B5B3A),
                    overlayColor: Colors.brown.withValues(alpha: 0.1),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: es.gridSize.toDouble(),
                    min: 10,
                    max: 40,
                    divisions: 30,
                    onChanged: (v) => notifier.setGridSize(v.round()),
                  ),
                ),
              ),
            ],
          ),
          if (es.selectedArrowId != null)
            _buildLengthControls(es, notifier),
        ],
      ),
    );
  }

  Widget _buildLengthControls(EditorState es, EditorNotifier notifier) {
    final arrow = es.arrows.firstWhere(
      (a) => a.id == es.selectedArrowId,
      orElse: () => es.arrows.first,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Text('Length ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          _miniButton(Icons.remove, Colors.orange, () {
            notifier.changeLength(es.selectedArrowId!, arrow.length - 1);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text('${arrow.length}',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          _miniButton(Icons.add, Colors.orange, () {
            notifier.changeLength(es.selectedArrowId!, arrow.length + 1);
          }),
          const SizedBox(width: 12),
          Text('Arrow #${arrow.id}',
            style: TextStyle(color: Colors.brown.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildBottomBar(EditorState es, EditorNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.brown.withValues(alpha: 0.06),
        border: Border(top: BorderSide(color: Colors.brown.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              icon: Icons.delete_sweep_rounded,
              label: 'Clear',
              color: Colors.red,
              onTap: () => _confirmClear(notifier),
            ),
            _actionButton(
              icon: Icons.save_rounded,
              label: 'Save',
              color: const Color(0xFF7B5B3A),
              onTap: () {
                if (es.arrows.isEmpty) {
                  _snack('Add arrows first!');
                  return;
                }
                notifier.saveAsNewLevel();
                _snack('💾 Level saved! Play it from Home.');
              },
            ),
            _actionButton(
              icon: Icons.copy_rounded,
              label: 'Export',
              color: Colors.blue,
              onTap: () {
                if (es.arrows.isEmpty) {
                  _snack('Add arrows first!');
                  return;
                }
                notifier.exportJSON();
                _snack('📋 JSON copied to clipboard!');
              },
            ),
            _actionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Test',
              color: Colors.green,
              onTap: () {
                if (es.arrows.isEmpty) {
                  _snack('Add arrows first!');
                  return;
                }
                ref.read(gameStateProvider.notifier).loadCustomLevel(
                  es.arrows, es.gridSize,
                );
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GameBoardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmClear(EditorNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will remove all arrows from the grid.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

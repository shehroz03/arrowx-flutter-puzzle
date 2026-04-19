import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'grid_painter.dart';

class GameBoardScreen extends ConsumerWidget {
  final int columns = 15;
  final int rows = 20;
  final double cellSize = 40.0; 

  const GameBoardScreen({super.key});

  // Core Math Logic: Pixels to Grid Index
  void _handleTouch(Offset localPosition, WidgetRef ref) {
    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();

    // Boundary Check: Grid se bahar touch draw na ho
    if (col >= 0 && col < columns && row >= 0 && row < rows) {
      ref.read(gameStateProvider.notifier).addPathPoint(col, row);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Level ${gameState.level}\n${gameState.isHardLevel ? "Hard" : "Normal"}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: gameState.isHardLevel ? Colors.purple : Colors.brown,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: List.generate(
                3,
                (index) => Icon(
                  Icons.water_drop,
                  color: index < gameState.chances ? Colors.blue : Colors.grey.shade300,
                  size: 35,
                ),
              ),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100.0),
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: GestureDetector(
                  // Touch start aur drag dono par trigger hoga
                  onPanStart: (details) => _handleTouch(details.localPosition, ref),
                  onPanUpdate: (details) => _handleTouch(details.localPosition, ref),
                  // Jab ungli uthao, toh path clear ho jaye (testing ke liye)
                  onPanEnd: (details) => ref.read(gameStateProvider.notifier).clearPath(),
                  
                  child: CustomPaint(
                    size: Size(columns * cellSize, rows * cellSize),
                    painter: GridPainter(
                      rows: rows, 
                      columns: columns, 
                      cellSize: cellSize,
                      currentPath: gameState.currentPath, // State se path pass kar rahe hain
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

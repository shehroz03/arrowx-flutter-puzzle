import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_data.dart'; 
import 'game_board.dart';
import 'game_state.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _unlockedLevel = 1;
  int _totalPoints = 0;
  final int _totalLevels = 50; // Game mein total kitne levels hain
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Data Load Karne ka function
  Future<void> _loadData() async {
    Map<String, int> data = await GameDataManager.loadProgress();
    setState(() {
      _unlockedLevel = data['level']!;
      _totalPoints = data['points']!;
      _isLoading = false;
    });
  }

  // Data Reset Karne ka function
  Future<void> _resetGame() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Reset Progress?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Kya aap waqai apni sari progress delete karna chahte hain? Yeh wapis nahi aayegi.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await GameDataManager.clearData();
              if (mounted) {
                navigator.pop();
                _loadData(); // UI ko refresh karein
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text("Game progress reset ho gayi hai.")),
                );
              }
            },
            child: const Text("Yes, Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF14142B),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF14142B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
            Text("Total Points: $_totalPoints 🌟", style: const TextStyle(fontSize: 14, color: Colors.amberAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _resetGame, // Settings / Reset button
            tooltip: "Settings",
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive Grid: Mobile par 3 columns, Tablet par 5 columns
              int crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _totalLevels,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  int levelNumber = index + 1;
                  bool isUnlocked = levelNumber <= _unlockedLevel;
                  bool isCurrentLevel = levelNumber == _unlockedLevel;

                  return _buildLevelCard(levelNumber, isUnlocked, isCurrentLevel);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Level Card Design
  Widget _buildLevelCard(int level, bool isUnlocked, bool isCurrentLevel) {
    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              GameDataManager.savePlayingLevel(level);
              GameDataManager.saveLastScreen('game');
              ref.read(gameStateProvider.notifier).loadLevel(level);
              
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameBoardScreen()),
              ).then((_) => GameDataManager.saveLastScreen('level_selection'));
              debugPrint("Level $level Start!");
            } else {
              // Locked level par click karne par chota sa message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Pehle Level ${level - 1} clear karein!"),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              // Agar unlocked hai toh Blue Gradient, warna dark grey
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: isCurrentLevel 
                          ? [Colors.blueAccent, Colors.purpleAccent] // Current level thora special
                          : [Colors.blue.shade800, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: isCurrentLevel ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isUnlocked
                  ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Center(
              child: isUnlocked
                  ? Text(
                      "$level",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : const Icon(Icons.lock_rounded, color: Colors.white54, size: 32),
            ),
          ),
        );
      },
    );
  }
}

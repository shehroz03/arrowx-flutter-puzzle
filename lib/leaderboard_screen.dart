import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1a1a2e)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Leaderboard', style: TextStyle(color: Color(0xFF1a1a2e), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 10),
            const Text(
              "Global Rankings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e)),
            ),
            const SizedBox(height: 30),
            _buildPlayerRow(rank: 1, name: 'Alex H.', score: 8520, isMe: false),
            const SizedBox(height: 12),
            _buildPlayerRow(rank: 2, name: 'Samira99', score: 7840, isMe: false),
            const SizedBox(height: 12),
            _buildPlayerRow(rank: 3, name: 'ProGamerX', score: 7100, isMe: false),
            const SizedBox(height: 12),
            _buildPlayerRow(rank: 142, name: 'You', score: 1250, isMe: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow({required int rank, required String name, required int score, required bool isMe}) {
    Color medalColor;
    if (rank == 1) medalColor = Colors.amber;
    else if (rank == 2) medalColor = Colors.grey.shade400;
    else if (rank == 3) medalColor = Colors.brown.shade400;
    else medalColor = Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1E56D0).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: const Color(0xFF1E56D0).withOpacity(0.3), width: 1.5) : null,
        boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: rank <= 3 ? medalColor : Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                fontSize: 16,
                color: isMe ? const Color(0xFF1E56D0) : const Color(0xFF1a1a2e),
              ),
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

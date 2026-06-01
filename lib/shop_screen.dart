import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1a1a2e)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shop', style: TextStyle(color: Color(0xFF1a1a2e), fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text('${gameState.points}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1a1a2e))),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Power-ups'),
            const SizedBox(height: 12),
            _buildShopItem(
              context,
              icon: Icons.undo,
              title: 'Undo Move',
              description: 'Takes back your last move.',
              price: 50,
            ),
            const SizedBox(height: 12),
            _buildShopItem(
              context,
              icon: Icons.lightbulb,
              title: 'Hint',
              description: 'Shows the best next arrow to click.',
              price: 150,
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('Themes (Coming Soon)'),
            const SizedBox(height: 12),
            _buildShopItem(
              context,
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              description: 'A sleek, easy-on-the-eyes theme.',
              price: 500,
              isLocked: true,
            ),
            const SizedBox(height: 12),
            _buildShopItem(
              context,
              icon: Icons.color_lens,
              title: 'Neon Glow',
              description: 'Cyberpunk inspired glowing arrows.',
              price: 1000,
              isLocked: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e)),
    );
  }

  Widget _buildShopItem(BuildContext context, {required IconData icon, required String title, required String description, required int price, bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade200 : const Color(0xFF1E56D0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isLocked ? Colors.grey : const Color(0xFF1E56D0), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey : const Color(0xFF1a1a2e))),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isLocked ? null : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchased successfully!')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56D0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text('$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

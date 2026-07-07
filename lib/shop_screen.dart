import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'shop_provider.dart';
import 'sound_manager.dart';
import 'theme_backdrop.dart';

/// Theme Shop — spend collected stars on premium animated themes.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopProvider.notifier).refresh());
  }

  Future<void> _buy(int index) async {
    final t = gameThemes[index];
    final shop = ref.read(shopProvider);
    if (shop.stars < t.price) {
      SoundManager().playError();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF8E4E58),
        content: Text(
            'Need ${t.price - shop.stars} more stars — complete levels to earn them!'),
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Unlock ${t.name}?'),
        content: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          Text(' ${t.price} stars will be spent',
              style: const TextStyle(fontSize: 15)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: t.arrow),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref.read(shopProvider.notifier).buy(index);
    if (ok && mounted) {
      SoundManager().playLevelComplete();
      ref.read(settingsProvider.notifier).setTheme(index);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.arrow,
        content: Text('${t.name} unlocked and applied!'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProvider);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF5B3E99), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text('Theme Shop',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5B3E99))),
                  const Spacer(),
                  // Star balance pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFE082), Color(0xFFFFC94D)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFF9C6B00), size: 22),
                      const SizedBox(width: 5),
                      Text('${shop.stars}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7A5200))),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Complete levels to earn stars, then unlock premium animated themes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: gameThemes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) => _ThemeCard(
                  theme: gameThemes[i],
                  owned: shop.isUnlocked(i),
                  applied: settings.themeIndex == i,
                  onBuy: () => _buy(i),
                  onApply: () {
                    SoundManager().playTap();
                    ref.read(settingsProvider.notifier).setTheme(i);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final GameTheme theme;
  final bool owned;
  final bool applied;
  final VoidCallback onBuy;
  final VoidCallback onApply;

  const _ThemeCard({
    required this.theme,
    required this.owned,
    required this.applied,
    required this.onBuy,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: applied ? theme.arrow : Colors.black.withValues(alpha: 0.06),
          width: applied ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: (theme.isPremium ? theme.arrow : Colors.black)
                  .withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Live animated preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  theme.isPremium
                      ? PremiumBackdrop(theme: theme, particleCount: 8)
                      : Container(color: theme.bg),
                  Center(
                    child: CustomPaint(
                        size: const Size(64, 64),
                        painter: _MiniArrowsPainter(theme.arrow)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(theme.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.isPremium
                                ? theme.arrow
                                : Colors.blueGrey.shade800)),
                  ),
                  if (theme.isPremium) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.arrow, theme.accent]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('PREMIUM',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(
                  theme.isPremium
                      ? 'Animated background & matching arrows'
                      : 'Classic flat theme',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
                ),
                const SizedBox(height: 10),
                _buildButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (applied) {
      return _pill('APPLIED', Icons.check_rounded,
          theme.arrow.withValues(alpha: 0.15), theme.arrow, null);
    }
    if (owned) {
      return _pill('APPLY', Icons.brush_rounded, theme.arrow, Colors.white, onApply);
    }
    return _pill('UNLOCK  ★ ${theme.price}', Icons.lock_open_rounded,
        const Color(0xFFFFC94D), const Color(0xFF7A5200), onBuy);
  }

  Widget _pill(String label, IconData icon, Color bg, Color fg, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

/// Three little game arrows so every card previews its arrow color.
class _MiniArrowsPainter extends CustomPainter {
  final Color color;
  _MiniArrowsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    void arrow(Offset a, Offset b) {
      canvas.drawLine(a, b, p);
      final dir = (b - a).direction;
      const wl = 7.0;
      canvas.drawLine(b, b + Offset.fromDirection(dir + 2.5, wl), p);
      canvas.drawLine(b, b + Offset.fromDirection(dir - 2.5, wl), p);
    }

    arrow(Offset(8, size.height * 0.25), Offset(size.width - 12, size.height * 0.25));
    arrow(Offset(size.width - 8, size.height * 0.55), Offset(12, size.height * 0.55));
    arrow(Offset(size.width * 0.5, size.height * 0.95),
        Offset(size.width * 0.5, size.height * 0.72));
  }

  @override
  bool shouldRepaint(covariant _MiniArrowsPainter old) => old.color != color;
}

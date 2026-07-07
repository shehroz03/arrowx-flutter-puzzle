import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'game_board.dart';
import 'game_state.dart';
import 'maze_builder.dart';
import 'sound_manager.dart';
import 'fun_maze_manager.dart';

/// "Fun" — type your name, get a playable arrow maze shaped like it.
/// Now with local save, completion tracking, and social sharing.
class ApnaMazeScreen extends ConsumerStatefulWidget {
  const ApnaMazeScreen({super.key});

  @override
  ConsumerState<ApnaMazeScreen> createState() => _ApnaMazeScreenState();
}

class _ApnaMazeScreenState extends ConsumerState<ApnaMazeScreen> {
  final _controller = TextEditingController();
  bool _building = false;
  List<FunMazeEntry> _savedMazes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMazes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedMazes() async {
    final mazes = await FunMazeManager.loadAll();
    if (mounted) setState(() => _savedMazes = mazes.reversed.toList());
  }

  Future<void> _build({String? existingName}) async {
    final text = (existingName ?? _controller.text).trim();
    if (text.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Type at least 2 letters'),
      ));
      return;
    }
    setState(() => _building = true);
    final result = await buildNameMaze(text);
    if (!mounted) return;
    setState(() => _building = false);
    if (result == null) {
      SoundManager().playError();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Could not build a maze from that — try different letters'),
      ));
      return;
    }
    SoundManager().playTap();

    // Save the maze locally
    await FunMazeManager.add(text);
    await _loadSavedMazes();

    ref.read(gameStateProvider.notifier).loadCustomLevel(
          result.arrows,
          result.gridSize,
          mask: result.mask,
          title: text.trim().toUpperCase(),
        );
    if (mounted) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const GameBoardScreen()));
      // Refresh list when coming back (might have completed it)
      _loadSavedMazes();
    }
  }

  Future<void> _deleteMaze(FunMazeEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${entry.name}"?'),
        content: const Text('This maze will be removed from your saved list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FunMazeManager.delete(entry.name);
      _loadSavedMazes();
    }
  }

  void _shareMaze(FunMazeEntry entry) {
    final status = entry.isCompleted ? '✅ COMPLETED' : '🎯 IN PROGRESS';
    final starsText = entry.isCompleted && entry.stars != null
        ? '⭐'.padRight(entry.stars! * 2, '⭐')
        : '';
        
    final nameEncoded = Uri.encodeComponent(entry.name);
    final deepLink = 'arrowx://maze?name=$nameEncoded';
    
    final text = '🎮 I created a Fun Arrow Maze!\n\n'
        '📝 Name: ${entry.name}\n'
        '$status $starsText\n\n'
        'Tap here to play my exact maze in your game:\n'
        '👉 $deepLink\n\n'
        'Don\'t have the game? Download ArrowX:\n'
        '📲 https://play.google.com/store/apps/details?id=com.shehroz.arrowpuzzlegame';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF1E56D0), size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Icon(Icons.abc_rounded,
                          size: 64, color: Color(0xFF1E56D0)),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text('My Fun',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E56D0))),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Type your name — we will turn it into\na playable arrow maze!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.blueGrey.shade400),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Text Field ──
                    TextField(
                      controller: _controller,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Color(0xFF1E1E2C)),
                      decoration: InputDecoration(
                        hintText: 'ALI',
                        hintStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Colors.blueGrey.shade200),
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _building ? null : _build(),
                    ),
                    const SizedBox(height: 24),

                    // ── Create Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E56D0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _building ? null : _build,
                        child: _building
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : const Text('CREATE MAZE',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'A brand new maze every time — try your friends\' names too!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.blueGrey.shade300),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Saved Mazes Section ──
            if (_savedMazes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          size: 22, color: Colors.blueGrey.shade600),
                      const SizedBox(width: 8),
                      Text('Your Mazes',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueGrey.shade700)),
                      const Spacer(),
                      Text('${_savedMazes.length}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueGrey.shade400)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = _savedMazes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SavedMazeCard(
                          entry: entry,
                          onPlay: () => _build(existingName: entry.name),
                          onShare: () => _shareMaze(entry),
                          onDelete: () => _deleteMaze(entry),
                        ),
                      );
                    },
                    childCount: _savedMazes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card for a single saved Fun maze entry.
class _SavedMazeCard extends StatelessWidget {
  final FunMazeEntry entry;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _SavedMazeCard({
    required this.entry,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.isCompleted;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade200
              : const Color(0xFFE8E8F0),
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : Colors.blueGrey)
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Name circle ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [Colors.green.shade300, Colors.green.shade500]
                      : [const Color(0xFF1E56D0), const Color(0xFF3F78E0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  entry.name.length > 2
                      ? entry.name.substring(0, 2)
                      : entry.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(entry.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1E2C))),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text('DONE',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade700,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isCompleted && entry.stars != null)
                        Row(
                          children: List.generate(
                            3,
                            (i) => Icon(
                              i < entry.stars!
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: i < entry.stars!
                                  ? Colors.amber
                                  : Colors.blueGrey.shade200,
                            ),
                          ),
                        )
                      else
                        Text('Tap to play',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Action Buttons ──
            // Share button
            IconButton(
              onPressed: onShare,
              icon: Icon(Icons.share_rounded,
                  size: 20, color: Colors.blueGrey.shade400),
              tooltip: 'Share',
            ),
            // Play button
            GestureDetector(
              onTap: onPlay,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [const Color(0xFF1E56D0), const Color(0xFF3F78E0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(isCompleted ? 'REPLAY' : 'PLAY',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1)),
              ),
            ),
            // Delete (long press or small icon)
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.red.shade300),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'game_board.dart';
import 'game_data.dart';
import 'maze_builder.dart';
import 'shop_provider.dart';
import 'sound_manager.dart';
import 'speed_rush_screen.dart';
import 'level_selection_screen.dart';

/// Fully functional events: a real daily shape maze, a real weekly counter
/// with a claimable reward, real milestones — all paid in stars.
class EventsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const EventsScreen({super.key, this.onBack});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _Milestone {
  final String id;
  final String title;
  final int need;
  final int reward;
  final IconData icon;
  final Color color;
  const _Milestone(this.id, this.title, this.need, this.reward, this.icon, this.color);
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  static const int _dailyReward = 5;
  static const int _weeklyReward = 20;

  // A friendly shape for every day of the year.
  static const _dailyShapes = [
    'Heart', 'Star', 'Rocket', 'Butterfly', 'Flower', 'Crown', 'Fish', 'Sun',
    'Smiley', 'Balloon', 'Owl', 'Rainbow', 'Cat', 'Trophy', 'Elephant',
    'Penguin', 'Whale', 'Snowman', 'Gift', 'Strawberry', 'Ghost', 'Turtle',
    'Dove', 'Cupcake', 'Anchor', 'Gear', 'Atom', 'Pumpkin',
  ];

  static const _milestones = [
    _Milestone('first_win', 'First Win', 1, 3, Icons.bolt_rounded, Color(0xFFF39C12)),
    _Milestone('streak_10', 'On Fire', 10, 10, Icons.local_fire_department_rounded, Color(0xFFE74C3C)),
    _Milestone('master_50', 'Master', 50, 25, Icons.diamond_rounded, Color(0xFF1E56D0)),
    _Milestone('legend_100', 'Legend', 100, 50, Icons.military_tech_rounded, Color(0xFF9B59B6)),
  ];

  bool _loading = true;
  bool _dailyDone = false;
  int _weeklyProgress = 0;
  bool _weeklyClaimed = false;
  int _maxCompleted = 0;
  Set<String> _claimedMilestones = {};

  int get _dayOfYear =>
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

  String get _todayShape => _dailyShapes[_dayOfYear % _dailyShapes.length];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final dailyDone = await GameDataManager.isDailyDone();
    final weekly = await GameDataManager.loadWeeklyProgress();
    final weeklyClaimed = await GameDataManager.isWeeklyClaimed();
    final maxCompleted = await GameDataManager.loadMaxCompleted();
    final claimed = <String>{};
    int granted = 0;
    for (final m in _milestones) {
      if (await GameDataManager.isMilestoneClaimed(m.id)) {
        claimed.add(m.id);
      } else if (maxCompleted >= m.need) {
        // Newly achieved milestone: grant its stars exactly once.
        if (await GameDataManager.claimMilestone(m.id, m.reward)) {
          claimed.add(m.id);
          granted += m.reward;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _dailyDone = dailyDone;
      _weeklyProgress = weekly;
      _weeklyClaimed = weeklyClaimed;
      _maxCompleted = maxCompleted;
      _claimedMilestones = claimed;
    });
    if (granted > 0) {
      SoundManager().playLevelComplete();
      ref.read(shopProvider.notifier).refresh();
      _snack('Milestone reward: +$granted stars!', const Color(0xFF9B59B6));
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _playDaily() async {
    SoundManager().playTap();
    if (_dailyDone) {
      _snack('Already completed — come back tomorrow!', const Color(0xFF1E56D0));
      return;
    }
    final seed = DateTime.now().year * 1000 + _dayOfYear;
    final result = buildShapeMaze(_todayShape, seed: seed);
    if (result == null) {
      _snack('Could not build today\'s maze, try again', Colors.redAccent);
      return;
    }
    ref.read(gameStateProvider.notifier).loadCustomLevel(
          result.arrows,
          result.gridSize,
          mask: result.mask,
          title: 'Daily: $_todayShape',
        );
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const GameBoardScreen()));
    if (!mounted) return;
    final gs = ref.read(gameStateProvider);
    if (gs.isCustomLevel && gs.isLevelComplete && !_dailyDone) {
      await GameDataManager.markDailyDone();
      await GameDataManager.addStars(_dailyReward);
      ref.read(shopProvider.notifier).refresh();
      SoundManager().playLevelComplete();
      _snack('Daily Challenge complete! +$_dailyReward stars', const Color(0xFF2ECC71));
    }
    _reload();
  }

  Future<void> _onWeeklyTap() async {
    SoundManager().playTap();
    if (_weeklyClaimed) {
      _snack('Weekly reward already collected — new marathon starts next week!',
          const Color(0xFFE67E22));
      return;
    }
    if (_weeklyProgress >= 10) {
      final ok = await GameDataManager.claimWeeklyReward(_weeklyReward);
      if (ok) {
        ref.read(shopProvider.notifier).refresh();
        SoundManager().playLevelComplete();
        _snack('Weekly Marathon complete! +$_weeklyReward stars', const Color(0xFF2ECC71));
        _reload();
      }
      return;
    }
    if (!mounted) return;
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LevelSelectionScreen()))
        .then((_) => _reload());
  }

  String _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    return "${diff.inHours}h ${diff.inMinutes % 60}m left";
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + star balance
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E2C)),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                    ),
                    const Expanded(
                      child: Text(
                        "Events",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1E2C),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10),
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 5),
                        Text('${shop.stars}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E1E2C))),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Real challenges, real star rewards",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Daily Challenge — a fresh shape maze every day
                _EventBanner(
                  title: "Daily Challenge",
                  subtitle: _dailyDone
                      ? "Done for today — a new shape arrives at midnight!"
                      : "Solve today's $_todayShape maze for bonus stars",
                  icon: Icons.calendar_today_rounded,
                  gradient: _dailyDone
                      ? const [Color(0xFF2ECC71), Color(0xFF27AE60)]
                      : const [Color(0xFF1E56D0), Color(0xFF4A90D9)],
                  tag: _dailyDone ? "COMPLETED" : "ACTIVE",
                  tagColor: _dailyDone ? Colors.white : Colors.greenAccent,
                  reward: "+$_dailyReward Stars",
                  timeLeft: _getTimeUntilMidnight(),
                  onTap: _loading ? () {} : _playDaily,
                ),

                const SizedBox(height: 16),

                // Weekly Marathon — real completion counter
                _EventBanner(
                  title: "Weekly Marathon",
                  subtitle: _weeklyClaimed
                      ? "Reward collected — see you next week!"
                      : (_weeklyProgress >= 10
                          ? "Goal reached — tap to claim your stars!"
                          : "Clear 10 levels this week to earn stars"),
                  icon: Icons.emoji_events_rounded,
                  gradient: const [Color(0xFFE67E22), Color(0xFFF39C12)],
                  tag: _weeklyClaimed
                      ? "COMPLETED"
                      : (_weeklyProgress >= 10 ? "CLAIM NOW" : "IN PROGRESS"),
                  tagColor: _weeklyProgress >= 10 && !_weeklyClaimed
                      ? Colors.yellowAccent
                      : Colors.orangeAccent,
                  reward: "+$_weeklyReward Stars",
                  progress: (_weeklyProgress / 10).clamp(0.0, 1.0),
                  progressLabel:
                      "${_weeklyProgress.clamp(0, 10)}/10 Levels this week",
                  onTap: _loading ? () {} : _onWeeklyTap,
                ),

                const SizedBox(height: 16),

                // Speed Rush — real game mode
                _EventBanner(
                  title: "Speed Rush",
                  subtitle: "Race the clock through random levels!",
                  icon: Icons.speed_rounded,
                  gradient: const [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
                  tag: "ACTIVE",
                  tagColor: Colors.greenAccent,
                  reward: "Beat your best time",
                  onTap: () {
                    SoundManager().playTap();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SpeedRushScreen()));
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  "MILESTONES",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                for (int row = 0; row < 2; row++) ...[
                  Row(children: [
                    for (int col = 0; col < 2; col++) ...[
                      Expanded(child: _buildMilestone(_milestones[row * 2 + col])),
                      if (col == 0) const SizedBox(width: 12),
                    ],
                  ]),
                  if (row == 0) const SizedBox(height: 12),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestone(_Milestone m) {
    final done = _maxCompleted >= m.need || _claimedMilestones.contains(m.id);
    return _MilestoneCard(
      icon: m.icon,
      title: m.title,
      subtitle: done
          ? "Completed! +${m.reward} stars"
          : "${_maxCompleted.clamp(0, m.need)}/${m.need} levels",
      isCompleted: done,
      color: m.color,
    );
  }
}

class _EventBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String tag;
  final Color tagColor;
  final String reward;
  final String? timeLeft;
  final double? progress;
  final String? progressLabel;
  final VoidCallback onTap;

  const _EventBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tag,
    required this.tagColor,
    required this.reward,
    this.timeLeft,
    this.progress,
    this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag + Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),

            const SizedBox(height: 14),

            // Progress or TimeLeft
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress!,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 6),
                Text(progressLabel!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
            ],

            // Reward + Time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                if (timeLeft != null)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 4),
                      Text(timeLeft!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color color;

  const _MilestoneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
        border: isCompleted ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : icon,
              color: isCompleted ? color : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCompleted ? color : Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: isCompleted ? Colors.green : Colors.grey.shade400, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

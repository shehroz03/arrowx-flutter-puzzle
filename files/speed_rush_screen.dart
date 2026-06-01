// ─────────────────────────────────────────────────────────────
// SPEED RUSH — Math puzzle timed mode
// Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedRushScreen()));
// pubspec: shared_preferences: ^2.2.2
// ─────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kP  = Color(0xFFFF6B35);
const _kP2 = Color(0xFFFF9A5C);
const _kBg = Color(0xFFFFF5F0);

class SpeedRushScreen extends StatefulWidget {
  const SpeedRushScreen({super.key});
  @override State<SpeedRushScreen> createState() => _SpeedRushState();
}

class _SpeedRushState extends State<SpeedRushScreen> with SingleTickerProviderStateMixin {
  String _screen = 'start';
  int _timeLeft = 60, _score = 0, _combo = 0, _maxCombo = 0, _correct = 0, _wrong = 0;
  int? _bestScore;
  Timer? _timer;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late String _equation;
  late int _answer;
  late List<int> _opts;
  int? _sel;
  bool? _selCorrect;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 8).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
    _loadBest();
    _nextQuestion();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _bestScore = p.getInt('sr_best'));
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    if (_bestScore == null || _score > _bestScore!) {
      await p.setInt('sr_best', _score);
      setState(() => _bestScore = _score);
    }
    final hist = jsonDecode(p.getString('sr_history') ?? '[]') as List;
    hist.add({'score': _score, 'correct': _correct, 'wrong': _wrong, 'combo': _maxCombo});
    await p.setString('sr_history', jsonEncode(hist.length > 20 ? hist.sublist(hist.length - 20) : hist));
  }

  void _nextQuestion() {
    final level = min(5, _score ~/ 5);
    final ops = level < 1 ? ['+'] : level < 2 ? ['+', '-'] : level < 3 ? ['+', '-', '×'] : ['+', '-', '×', '÷'];
    final op = ops[_rng.nextInt(ops.length)];
    int a, b, ans;
    switch (op) {
      case '+': a = _rng.nextInt(20 * (level + 1)) + 1; b = _rng.nextInt(20 * (level + 1)) + 1; ans = a + b;
      case '-': a = _rng.nextInt(50) + 10; b = _rng.nextInt(a) + 1; ans = a - b;
      case '×': a = _rng.nextInt(10 * (level + 1)) + 2; b = _rng.nextInt(12) + 2; ans = a * b;
      case '÷': b = _rng.nextInt(10) + 2; ans = _rng.nextInt(12) + 2; a = ans * b;
      default:  a = 5; b = 3; ans = 8;
    }
    final opts = <int>{ans};
    while (opts.length < 4) {
      final d = _rng.nextInt(15) - 7;
      if (d != 0) opts.add(ans + d);
    }
    final optList = opts.toList()..shuffle(_rng);
    setState(() { _equation = '$a $op $b = ?'; _answer = ans; _opts = optList; _sel = null; _selCorrect = null; });
  }

  void _startGame() {
    setState(() { _screen = 'quiz'; _timeLeft = 60; _score = 0; _combo = 0; _maxCombo = 0; _correct = 0; _wrong = 0; });
    _nextQuestion();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_timeLeft > 0) { _timeLeft--; }
        else { _timer?.cancel(); _screen = 'result'; _saveBest(); }
      });
    });
  }

  void _pick(int i, int val) {
    if (_sel != null) return;
    final ok = val == _answer;
    setState(() {
      _sel = i; _selCorrect = ok;
      if (ok) { _combo++; _maxCombo = max(_maxCombo, _combo); _score += (1 + _combo ~/ 3); _correct++; }
      else     { _combo = 0; _wrong++; }
    });
    if (!ok) { _shakeCtrl.forward(from: 0); }
    Future.delayed(const Duration(milliseconds: 350), _nextQuestion);
  }

  @override
  void dispose() { _timer?.cancel(); _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg, body: SafeArea(child: switch (_screen) {
      'quiz'   => _buildQuiz(),
      'result' => _buildResult(),
      _        => _buildStart(),
    }));
  }

  Widget _buildStart() {
    return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      Container(width: 56, height: 56,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _kP.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 8))]),
        child: const Center(child: Text('⚡', style: TextStyle(fontSize: 28)))),
      const SizedBox(height: 14),
      const Text('Speed Rush', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e))),
      const Text('Solve math puzzles before time runs out!', style: TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 24),
      Row(children: [
        _infoCard('60s', 'Time Limit', Icons.timer),
        const SizedBox(width: 10),
        _infoCard('×3', 'Combo Bonus', Icons.local_fire_department),
        const SizedBox(width: 10),
        _infoCard('∞', 'No Limit', Icons.all_inclusive),
      ]),
      const SizedBox(height: 16),
      if (_bestScore != null) Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2]), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Best Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$_bestScore pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ]),
        ])),
      const SizedBox(height: 24),
      _btn('Start Rush ⚡', _startGame),
    ]));
  }

  Widget _buildQuiz() {
    final timerColor = _timeLeft > 30 ? _kP : _timeLeft > 10 ? Colors.orange : Colors.red;
    return Column(children: [
      // Header
      Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE', style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1)),
            Text('$_score', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1a1a2e))),
          ]),
          Column(children: [
            Text('$_timeLeft', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: timerColor)),
            Text('seconds', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('COMBO', style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1)),
            Row(children: [Text('×${1 + _combo ~/ 3}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: _kP)),
              if (_combo >= 3) const Text(' 🔥', style: TextStyle(fontSize: 16))]),
          ]),
        ])),
      // Timer bar
      Container(margin: const EdgeInsets.symmetric(horizontal: 12), height: 5,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(99)),
        child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: _timeLeft / 60,
          child: Container(decoration: BoxDecoration(color: timerColor, borderRadius: BorderRadius.circular(99))))),
      // Equation
      const Spacer(),
      AnimatedBuilder(animation: _shakeAnim, builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value * sin(_shakeCtrl.value * pi * 4), 0), child: child),
        child: Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 20)]),
          child: Column(children: [
            if (_combo >= 3) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: _kP.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
              child: Text('🔥 $_combo Combo! +${1 + _combo ~/ 3}x', style: const TextStyle(color: _kP, fontWeight: FontWeight.w700, fontSize: 13))),
            Text(_equation, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e))),
          ])),
      ),
      const Spacer(),
      // Options
      Padding(padding: const EdgeInsets.all(16), child: GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.4,
        children: List.generate(4, (i) {
          final val = _opts[i];
          Color bg = Colors.white; Color fg = const Color(0xFF1a1a2e);
          if (_sel == i) { bg = _selCorrect! ? const Color(0xFF16a34a) : Colors.red; fg = Colors.white; }
          return GestureDetector(
            onTap: () => _pick(i, val),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)]),
              child: Center(child: Text('$val', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)))),
          );
        }))),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildResult() {
    final best = _bestScore ?? _score;
    final isNewBest = _score >= best;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 20),
      if (isNewBest) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF84cc16)]), borderRadius: BorderRadius.circular(99)),
        child: const Text('🏆 NEW HIGH SCORE!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
      Container(width: 110, height: 110,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_kP, _kP2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: _kP.withOpacity(.35), blurRadius: 36, offset: const Offset(0, 10))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36, height: 1)),
          const Text('pts', style: TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
      const SizedBox(height: 16),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.6,
        children: [
          _statCard('✅', 'Correct', '$_correct'),
          _statCard('❌', 'Wrong', '$_wrong'),
          _statCard('🔥', 'Best Combo', '×$_maxCombo'),
          _statCard('🏆', 'Best Score', '$best'),
        ]),
      const SizedBox(height: 20),
      _btn('Play Again ⚡', () => setState(() { _screen = 'start'; })),
      const SizedBox(height: 10),
      GestureDetector(onTap: () => Navigator.pop(context),
        child: const Text('← Back to Menu', style: TextStyle(color: Colors.grey, fontSize: 14))),
    ]));
  }

  Widget _infoCard(String v, String l, IconData ic) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)]),
    child: Column(children: [Icon(ic, color: _kP, size: 20), const SizedBox(height: 4),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1a1a2e))),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ])));

  Widget _statCard(String e, String l, String v) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(e, style: const TextStyle(fontSize: 20)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1a1a2e))),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));

  Widget _btn(String t, VoidCallback fn) => GestureDetector(onTap: fn, child: Container(width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2]), borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: _kP.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))));
}

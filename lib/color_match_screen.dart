// ─────────────────────────────────────────────────────────────
// COLOR MATCH — Stroop effect game
// Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorMatchScreen()));
// ─────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kP  = Color(0xFF059669);
const _kP2 = Color(0xFF34D399);
const _kBg = Color(0xFFF0FDF4);

class _ColorDef {
  final String name;
  final Color color;
  const _ColorDef(this.name, this.color);
}

const _colors = [
  _ColorDef('RED',    Color(0xFFef4444)),
  _ColorDef('BLUE',   Color(0xFF3b82f6)),
  _ColorDef('GREEN',  Color(0xFF22c55e)),
  _ColorDef('YELLOW', Color(0xFFeab308)),
  _ColorDef('PURPLE', Color(0xFF8b5cf6)),
  _ColorDef('ORANGE', Color(0xFFf97316)),
];

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({super.key});
  @override State<ColorMatchScreen> createState() => _ColorMatchState();
}

class _ColorMatchState extends State<ColorMatchScreen> with SingleTickerProviderStateMixin {
  String _screen = 'start';
  int _score = 0, _lives = 3, _timeLeft = 60, _combo = 0, _maxCombo = 0;
  int? _bestScore;
  Timer? _timer;

  late _ColorDef _wordColor;    // the color the TEXT is written in
  late _ColorDef _wordText;     // what the WORD says
  late List<_ColorDef> _opts;   // 4 answer options
  int? _sel;
  bool? _selOk;
  bool _roundFlash = false;

  late AnimationController _flashCtrl;
  late Animation<Color?> _flashAnim;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flashAnim = ColorTween(begin: Colors.transparent, end: Colors.transparent).animate(_flashCtrl);
    _loadBest();
    _nextRound();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _bestScore = p.getInt('cm_best'));
  }

  Future<void> _saveBest() async {
    final p = await SharedPreferences.getInstance();
    if (_bestScore == null || _score > _bestScore!) await p.setInt('cm_best', _score);
    setState(() => _bestScore = max(_bestScore ?? 0, _score));
  }

  void _nextRound() {
    final shuffled = List.of(_colors)..shuffle(_rng);
    _wordText  = shuffled[0];
    _wordColor = shuffled[1 % shuffled.length]; // different from text
    while (_wordColor == _wordText) _wordColor = shuffled[_rng.nextInt(shuffled.length)];
    final opts = <_ColorDef>{_wordColor};
    while (opts.length < 4) opts.add(_colors[_rng.nextInt(_colors.length)]);
    _opts = opts.toList()..shuffle(_rng);
    setState(() { _sel = null; _selOk = null; });
  }

  void _startGame() {
    setState(() { _screen = 'game'; _score = 0; _lives = 3; _timeLeft = 60; _combo = 0; _maxCombo = 0; });
    _nextRound();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_timeLeft > 0 && _lives > 0) { _timeLeft--; }
        else { _timer?.cancel(); _screen = 'result'; _saveBest(); }
      });
    });
  }

  void _pick(int i) {
    if (_sel != null) return;
    final ok = _opts[i] == _wordColor;
    setState(() {
      _sel = i; _selOk = ok;
      if (ok) { _combo++; _maxCombo = max(_maxCombo, _combo); _score += (1 + _combo ~/ 3); }
      else     { _combo = 0; _lives = max(0, _lives - 1); if (_lives == 0) { _timer?.cancel(); _screen = 'result'; _saveBest(); } }
    });
    Future.delayed(const Duration(milliseconds: 380), () { if (mounted) { _nextRound(); if (_lives > 0) setState(() {}); } });
  }

  @override
  void dispose() { _timer?.cancel(); _flashCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg, body: SafeArea(child: switch (_screen) {
      'game'   => _buildGame(),
      'result' => _buildResult(),
      _        => _buildStart(),
    }));
  }

  Widget _buildStart() => Stack(children: [
    SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
    Container(width: 56, height: 56,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _kP.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: const Center(child: Text('🎨', style: TextStyle(fontSize: 28)))),
    const SizedBox(height: 14),
    const Text('Color Match', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1a1a2e))),
    const Text('Tap the COLOR of the word — not what it says!', style: TextStyle(color: Colors.grey, fontSize: 14)),
    const SizedBox(height: 20),

    // Demo card
    Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12)]),
      child: Column(children: [
        const Text('Example:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text('GREEN', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 2)),
        const SizedBox(height: 8),
        const Text('→ Tap RED (the ink color)', style: TextStyle(color: Colors.grey, fontSize: 13)),
      ])),
    const SizedBox(height: 16),

    Row(children: [
      _infoCard('3', 'Lives', Icons.favorite),
      const SizedBox(width: 10),
      _infoCard('60s', 'Timer', Icons.timer),
      const SizedBox(width: 10),
      _infoCard('🔥', 'Combo', Icons.local_fire_department),
    ]),
    const SizedBox(height: 14),

    if (_bestScore != null) Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kP, _kP2]), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Best Score', style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text('$_bestScore pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        ]),
      ])),
    const SizedBox(height: 20),
    _btn('Play 🎨', _startGame),
    ])),
    Positioned(
      top: 10, left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  ]);

  Widget _buildGame() {
    return Column(children: [
      // Header
      Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () { _timer?.cancel(); Navigator.pop(context); },
                child: const Icon(Icons.arrow_back, color: Colors.grey, size: 26),
              ),
              const SizedBox(width: 8),
              Row(children: List.generate(3, (i) => Icon(i < _lives ? Icons.favorite : Icons.favorite_border,
                  color: i < _lives ? Colors.red : Colors.grey, size: 22))),
            ],
          ),
          Text('$_timeLeft', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26,
              color: _timeLeft > 20 ? _kP : _timeLeft > 10 ? Colors.orange : Colors.red)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$_score pts', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1a1a2e))),
            if (_combo >= 2) Text('🔥 $_combo', style: const TextStyle(color: _kP, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ])),

      // Timer bar
      Container(margin: const EdgeInsets.symmetric(horizontal: 12), height: 5,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(99)),
        child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: _timeLeft / 60,
          child: Container(decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(99))))),

      const Spacer(),

      // Question card
      Container(margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 20)]),
        child: Column(children: [
          const Text('What color is this text?', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Text(_wordText.name, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900,
              color: _wordColor.color, letterSpacing: 3,
              shadows: [Shadow(color: _wordColor.color.withOpacity(.3), blurRadius: 12)])),
          const SizedBox(height: 8),
          if (_combo >= 3) Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: _kP.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
            child: Text('🔥 Combo ×${1 + _combo ~/ 3}', style: const TextStyle(color: _kP, fontWeight: FontWeight.w700, fontSize: 12))),
        ])),

      const Spacer(),

      // Options
      Padding(padding: const EdgeInsets.all(16), child: GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5,
        children: List.generate(4, (i) {
          final c = _opts[i];
          Color bg = c.color; Color fg = Colors.white;
          if (_sel == i) { bg = _selOk! ? const Color(0xFF16a34a) : Colors.red; }
          return GestureDetector(
            onTap: () => _pick(i),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: bg.withOpacity(.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Center(child: Text(c.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg, letterSpacing: 1)))),
          );
        }))),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildResult() {
    final isNew = _score > (_bestScore ?? -1);
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 20),
      if (isNew) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _statCard('🔥', 'Best Combo', '×$_maxCombo'),
          _statCard('❤️', 'Lives Left', '$_lives/3'),
          _statCard('🏆', 'Best Score', '${_bestScore ?? _score}'),
          _statCard('⏱️', 'Time Used', '${60 - _timeLeft}s'),
        ]),
      const SizedBox(height: 20),
      _btn('Play Again 🎨', () => setState(() => _screen = 'start')),
      const SizedBox(height: 10),
      GestureDetector(onTap: () => Navigator.pop(context),
        child: const Text('← Back to Menu', style: TextStyle(color: Colors.grey, fontSize: 14))),
    ]));
  }

  Widget _infoCard(String v, String l, IconData ic) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)]),
    child: Column(children: [Icon(ic, color: _kP, size: 20), const SizedBox(height: 4),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1a1a2e))),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))])));

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

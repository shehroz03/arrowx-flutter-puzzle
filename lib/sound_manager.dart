import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isSoundMuted = false;
  bool _isMusicMuted = false;

  bool get isSoundMuted => _isSoundMuted;
  bool get isMusicMuted => _isMusicMuted;

  // Sync Sound Effects Mute
  void setSoundMute(bool shouldMute) {
    _isSoundMuted = shouldMute;
  }

  // Sync Music Mute
  void setMusicMute(bool shouldMute) {
    if (_isMusicMuted == shouldMute) return;
    _isMusicMuted = shouldMute;
    if (_isMusicMuted) {
      _musicPlayer.stop();
    } else {
      startBGM(); // Resume BGM if unmuted
    }
  }

  // For backwards compatibility
  void setMute(bool shouldMute) {
    setSoundMute(shouldMute);
    setMusicMute(shouldMute);
  }

  void playTap() {
    if (_isSoundMuted) return;
    _playSound('tap.wav'); 
  }

  void playClear() {
    if (_isSoundMuted) return;
    _playSound('whoosh.wav');
  }

  // One sound per fly-trail effect, same order as ArrowPathPainter.trailEffect:
  // 0 echo, 1 dust, 2 warp, 3 portal, 4 grid ripple, 5 bolt.
  static const _trailSounds = [
    'trail_echo.wav',
    'trail_dust.wav',
    'trail_warp.wav',
    'trail_portal.wav',
    'trail_ripple.wav',
    'trail_bolt.wav',
  ];

  void playTrail(int effect) {
    if (_isSoundMuted) return;
    _playSound(_trailSounds[effect % _trailSounds.length]);
  }

  void playError() {
    if (_isSoundMuted) return;
    _playSound('error.wav');
  }

  void playLevelComplete() {
    if (_isSoundMuted) return;
    _playSound('success.wav');
  }

  Future<void> startBGM() async {
    if (_isMusicMuted) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('sounds/bgm.wav'), volume: 0.4);
    } catch (e) {
      // Audio load failed
    }
  }

  void stopBGM() {
    _musicPlayer.stop();
  }

  // Fixed pool of reusable players. Creating a fresh AudioPlayer per sound
  // exhausts native audio resources, which is why SFX played once and then
  // went silent. Round-robin reuse keeps every tap/fly sound working.
  static const int _poolSize = 8;
  final List<AudioPlayer> _sfxPool = [];
  int _poolIndex = 0;
  bool _poolReady = false;

  Future<void> _ensurePool() async {
    if (_poolReady) return;
    _poolReady = true;
    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop); // stay reusable after playing
      _sfxPool.add(p);
    }
  }

  Future<void> _playSound(String assetName) async {
    try {
      await _ensurePool();
      final player = _sfxPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource('sounds/$assetName'));
    } catch (e) {
      // Audio load failed
    }
  }
}

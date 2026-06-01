import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isMuted = false;

  bool get isMuted => _isMuted;

  // Sync with Global Settings
  void setMute(bool shouldMute) {
    if (_isMuted == shouldMute) return;
    _isMuted = shouldMute;
    if (_isMuted) {
      _sfxPlayer.stop();
      _musicPlayer.stop();
    } else {
      startBGM(); // Resume BGM if unmuted
    }
  }

  void playTap() {
    if (_isMuted) return;
    _playSound('tap.wav'); 
  }

  void playClear() {
    if (_isMuted) return;
    _playSound('whoosh.wav');
  }

  void playError() {
    if (_isMuted) return;
    _playSound('error.wav');
  }

  void playLevelComplete() {
    if (_isMuted) return;
    _playSound('success.wav');
  }

  Future<void> startBGM() async {
    if (_isMuted) return;
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

  Future<void> _playSound(String assetName) async {
    try {
      // Use low latency for SFX to avoid glitches
      await _sfxPlayer.play(AssetSource('sounds/$assetName'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Audio load failed
    }
  }
}

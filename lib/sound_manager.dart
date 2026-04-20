import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggle() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _sfxPlayer.stop();
      _musicPlayer.stop();
    }
  }

  void toggleMute(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      _sfxPlayer.stop();
      _musicPlayer.stop();
    }
  }

  Future<void> preloads() async {
    // If you add file assets later, preload them here.
    // e.g. await AudioCache.instance.loadAll(['tap.mp3', 'whoosh.mp3', 'error.mp3', 'success.mp3']);
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

  Future<void> _playSound(String assetName) async {
    try {
      await _sfxPlayer.stop(); // Stop current play to reset for mobile
      await _sfxPlayer.play(AssetSource('sounds/$assetName'));
    } catch (e) {
      // Ignore if files aren't added yet
      debugPrint("Audio missing: $assetName");
    }
  }
}

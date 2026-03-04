import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound effect types
enum SoundEffect {
  correct,
  wrong,
  timeout,
  gameOver,
  win,
  lifeline,
  tick,
  streak,
}

/// Service for playing game sound effects
class SoundService {
  static const String _prefSoundEnabled = 'sound_enabled';

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _initialized = false;

  /// Initialize sound service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
    _initialized = true;
  }

  /// Whether sound is enabled
  bool get isSoundEnabled => _soundEnabled;

  /// Toggle sound on/off
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, _soundEnabled);
  }

  /// Set sound enabled/disabled
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, enabled);
  }

  /// Play a sound effect
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled || !_initialized) return;

    try {
      final filename = _getFilename(effect);
      await _player.stop();
      await _player.play(AssetSource('audio/$filename'));
    } catch (e) {
      // Silently fail - sound is non-critical
    }
  }

  String _getFilename(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.correct:
        return 'correct.wav';
      case SoundEffect.wrong:
        return 'wrong.wav';
      case SoundEffect.timeout:
        return 'timeout.wav';
      case SoundEffect.gameOver:
        return 'game_over.wav';
      case SoundEffect.win:
        return 'win.wav';
      case SoundEffect.lifeline:
        return 'lifeline.wav';
      case SoundEffect.tick:
        return 'tick.wav';
      case SoundEffect.streak:
        return 'streak.wav';
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

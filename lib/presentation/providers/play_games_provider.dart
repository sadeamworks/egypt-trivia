import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/play_games_service.dart';

/// Singleton service instance
final playGamesServiceProvider = Provider<PlayGamesService>((ref) {
  return PlayGamesService();
});

/// Sign-in state — true when the player is signed into Play Games
class PlayGamesNotifier extends StateNotifier<bool> {
  final PlayGamesService _service;

  PlayGamesNotifier(this._service) : super(false) {
    _silentSignIn();
  }

  Future<void> _silentSignIn() async {
    await _service.signInSilently();
    state = _service.isSignedIn;
  }

  /// Called from the Settings screen "Connect Google Play" button
  Future<bool> signIn() async {
    final success = await _service.signIn();
    state = success;
    return success;
  }

  bool get isSignedIn => state;
}

final playGamesProvider =
    StateNotifierProvider<PlayGamesNotifier, bool>((ref) {
  final service = ref.watch(playGamesServiceProvider);
  return PlayGamesNotifier(service);
});

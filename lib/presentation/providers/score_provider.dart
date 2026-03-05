import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/score_entry.dart';
import '../../data/models/game_result.dart';
import '../../data/repositories/score_repository.dart';
import '../../domain/services/play_games_service.dart';
import 'play_games_provider.dart';

/// Provider for the score repository
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

/// Provider for the overall high score
final highScoreProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(scoreRepositoryProvider);
  await repository.init();
  return repository.getOverallHighScore();
});

/// Provider for top scores
final topScoresProvider = FutureProvider<List<ScoreEntry>>((ref) async {
  final repository = ref.watch(scoreRepositoryProvider);
  await repository.init();
  return repository.getTopScores(limit: 10);
});

/// Notifier for managing scores
class ScoreNotifier extends StateNotifier<AsyncValue<void>> {
  final ScoreRepository _repository;
  final PlayGamesService _playGames;

  ScoreNotifier(this._repository, this._playGames)
      : super(const AsyncValue.data(null));

  /// Save a game result as a score entry and submit to GPGS leaderboard
  Future<void> saveGameResult(GameResult result) async {
    state = const AsyncValue.loading();
    try {
      final entry = ScoreEntry(
        category: result.category,
        score: result.score,
        streak: result.bestStreak,
        correctAnswers: result.correctAnswers,
        date: DateTime.now(),
      );
      await _repository.saveScore(entry);
      // Submit to Google Play Games leaderboard (no-op if not signed in)
      await _playGames.submitScore(result.score);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for score operations
final scoreNotifierProvider =
    StateNotifierProvider<ScoreNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  final playGames = ref.watch(playGamesServiceProvider);
  return ScoreNotifier(repository, playGames);
});

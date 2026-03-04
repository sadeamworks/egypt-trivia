import '../../core/constants/game_config.dart';
import '../../data/models/question.dart';

/// Handles game logic and scoring calculations
class GameService {
  /// Calculate score for a correct answer
  int calculateScore({
    required int currentStreak,
    required int basePoints,
  }) {
    final multiplier = GameConfig.getStreakMultiplier(currentStreak);
    return basePoints * multiplier;
  }

  /// Get the current streak multiplier display
  String getMultiplierDisplay(int streak) {
    final multiplier = GameConfig.getStreakMultiplier(streak);
    return '×$multiplier';
  }

  /// Check if answer is correct
  bool checkAnswer(Question question, int answerIndex) {
    return question.answers[answerIndex].isCorrect;
  }

  /// Get the correct answer index
  int getCorrectAnswerIndex(Question question) {
    return question.answers.indexWhere((a) => a.isCorrect);
  }

  /// Apply 50/50 lifeline - returns indices of answers to hide
  List<int> applyFiftyFifty(Question question) {
    final wrongAnswers = <int>[];
    for (int i = 0; i < question.answers.length; i++) {
      if (!question.answers[i].isCorrect) {
        wrongAnswers.add(i);
      }
    }
    // Shuffle and take 2 wrong answers to hide
    wrongAnswers.shuffle();
    return wrongAnswers.take(2).toList();
  }
}

/// Game configuration constants
class GameConfig {
  GameConfig._();

  // Gameplay
  static const int questionsPerRound = 10;
  static const int timerDurationSeconds = 15;
  static const int initialLives = 3;
  static const int maxLives = 3;

  // Scoring
  static const int basePointsPerQuestion = 150;
  static const int streakMultiplierCap = 5; // Max ×5 multiplier

  // Streak thresholds for multiplier
  static int getStreakMultiplier(int streak) {
    if (streak >= 4) return 4;
    if (streak >= 3) return 3;
    if (streak >= 2) return 2;
    return 1;
  }

  // Animation durations
  static const Duration answerFeedbackDuration = Duration(milliseconds: 300);
  static const Duration transitionDuration = Duration(milliseconds: 250);
}

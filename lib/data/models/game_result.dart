import 'package:equatable/equatable.dart';

/// Represents the result of a completed game round
class GameResult extends Equatable {
  final String category;
  final int score;
  final int bestStreak;
  final int correctAnswers;
  final int totalQuestions;

  const GameResult({
    required this.category,
    required this.score,
    required this.bestStreak,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  double get accuracyPercentage =>
      (correctAnswers / totalQuestions) * 100;

  @override
  List<Object?> get props => [category, score, bestStreak, correctAnswers, totalQuestions];
}

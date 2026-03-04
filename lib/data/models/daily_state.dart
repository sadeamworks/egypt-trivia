import 'package:hive/hive.dart';

/// State for the daily challenge feature
class DailyState extends HiveObject {
  final String dateKey; // Format: '2026-03-03' (Cairo date)
  final bool completed;
  final int score;
  final int correctAnswers;
  final int currentStreak; // Consecutive days
  final int bestStreak;

  DailyState({
    required this.dateKey,
    this.completed = false,
    this.score = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  DailyState copyWith({
    String? dateKey,
    bool? completed,
    int? score,
    int? correctAnswers,
    int? currentStreak,
    int? bestStreak,
  }) {
    return DailyState(
      dateKey: dateKey ?? this.dateKey,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }
}

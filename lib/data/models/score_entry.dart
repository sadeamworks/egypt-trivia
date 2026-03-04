import 'package:equatable/equatable.dart';

/// Represents a high score entry
class ScoreEntry extends Equatable {
  final String category;
  final int score;
  final int streak;
  final int correctAnswers;
  final DateTime date;

  const ScoreEntry({
    required this.category,
    required this.score,
    required this.streak,
    required this.correctAnswers,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'score': score,
        'streak': streak,
        'correctAnswers': correctAnswers,
        'date': date.toIso8601String(),
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      category: json['category'] as String,
      score: json['score'] as int,
      streak: json['streak'] as int,
      correctAnswers: json['correctAnswers'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  List<Object?> get props => [category, score, streak, correctAnswers, date];
}

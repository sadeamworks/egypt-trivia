import 'package:equatable/equatable.dart';

/// Represents a trivia question
class Question extends Equatable {
  final int id;
  final String category;
  final String question;
  final List<Answer> answers;

  const Question({
    required this.id,
    required this.category,
    required this.question,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      category: json['category'] as String,
      question: json['question'] as String,
      answers: (json['answers'] as List)
          .map((a) => Answer.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'question': question,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  Answer get correctAnswer => answers.firstWhere((a) => a.isCorrect);

  @override
  List<Object?> get props => [id, category, question, answers];
}

/// Represents an answer option
class Answer extends Equatable {
  final String text;
  final bool isCorrect;

  const Answer({
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      text: json['text'] as String,
      isCorrect: json['correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'correct': isCorrect,
      };

  @override
  List<Object?> get props => [text, isCorrect];
}

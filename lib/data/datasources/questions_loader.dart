import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/question.dart';

/// Loads questions from JSON asset
class QuestionsLoader {
  List<Question>? _cachedQuestions;
  final Random _random = Random();

  /// Load all questions from JSON asset
  Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/data/questions.json',
    );

    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> questionsJson = jsonData['questions'] as List<dynamic>;

    _cachedQuestions = questionsJson
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();

    return _cachedQuestions!;
  }

  /// Shuffle answers within a question while maintaining correct answer tracking
  Question _shuffleAnswers(Question question) {
    final answers = List<Answer>.from(question.answers);
    // Fisher-Yates shuffle
    for (int i = answers.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = answers[i];
      answers[i] = answers[j];
      answers[j] = temp;
    }
    return Question(
      id: question.id,
      category: question.category,
      question: question.question,
      answers: answers,
    );
  }

  /// Get questions for a specific category
  Future<List<Question>> getQuestionsByCategory(String categoryName) async {
    final allQuestions = await loadQuestions();
    return allQuestions.where((q) => q.category == categoryName).toList();
  }

  /// Get random questions for a game round with shuffled answers
  Future<List<Question>> getRandomQuestions({
    required String categoryName,
    required int count,
  }) async {
    final categoryQuestions = await getQuestionsByCategory(categoryName);
    categoryQuestions.shuffle();

    // Shuffle answers within each question
    return categoryQuestions.take(count).map(_shuffleAnswers).toList();
  }

  /// Get question count for a category
  Future<int> getCategoryQuestionCount(String categoryName) async {
    final categoryQuestions = await getQuestionsByCategory(categoryName);
    return categoryQuestions.length;
  }

  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedQuestions = null;
  }
}

import 'dart:math';
import '../../data/models/question.dart';
import '../../data/models/daily_state.dart';
import '../../data/datasources/questions_loader.dart';

/// Service for managing the daily challenge
class DailyService {
  final QuestionsLoader _questionsLoader;

  static const int _questionsPerDay = 5;

  DailyService({
    QuestionsLoader? questionsLoader,
  })  : _questionsLoader = questionsLoader ?? QuestionsLoader();

  /// Get Cairo date as a string key (YYYY-MM-DD)
  /// Cairo is UTC+2
  String getTodayDateKey() {
    final now = DateTime.now().toUtc();
    final cairoTime = now.add(const Duration(hours: 2));
    return '${cairoTime.year}-${cairoTime.month.toString().padLeft(2, '0')}-${cairoTime.day.toString().padLeft(2, '0')}';
  }

  /// Get yesterday's date key for streak checking
  String getYesterdayDateKey() {
    final now = DateTime.now().toUtc();
    final cairoTime = now.add(const Duration(hours: 2)).subtract(const Duration(days: 1));
    return '${cairoTime.year}-${cairoTime.month.toString().padLeft(2, '0')}-${cairoTime.day.toString().padLeft(2, '0')}';
  }

  /// Generate deterministic question IDs for a given date
  /// Uses the date as a seed for reproducibility
  Future<List<int>> getDailyQuestionIds(String dateKey) async {
    final allQuestions = await _questionsLoader.loadQuestions();

    // Create a deterministic seed from the date
    final seed = _dateToSeed(dateKey);
    final random = Random(seed);

    // Shuffle questions deterministically
    final shuffled = List<Question>.from(allQuestions)..shuffle(random);

    // Take first 5 questions
    return shuffled.take(_questionsPerDay).map((q) => q.id).toList();
  }

  /// Get the daily challenge questions with shuffled answers
  Future<List<Question>> getDailyQuestions(String dateKey) async {
    final ids = await getDailyQuestionIds(dateKey);
    final allQuestions = await _questionsLoader.loadQuestions();
    final seed = _dateToSeed(dateKey);

    final questions = <Question>[];
    for (int i = 0; i < ids.length; i++) {
      final question = allQuestions.firstWhere((q) => q.id == ids[i]);
      // Use deterministic shuffle based on date + question index
      questions.add(_shuffleAnswersDeterministic(question, seed + i));
    }

    return questions;
  }

  /// Shuffle answers deterministically using a seed
  Question _shuffleAnswersDeterministic(Question question, int seed) {
    final random = Random(seed);
    final answers = List<Answer>.from(question.answers);

    // Fisher-Yates shuffle with seeded random
    for (int i = answers.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
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

  /// Calculate the streak based on previous state
  DailyState calculateNewStreak(DailyState? previousState, String todayKey) {
    if (previousState == null) {
      // First time playing
      return DailyState(
        dateKey: todayKey,
        currentStreak: 1,
        bestStreak: 1,
      );
    }

    if (previousState.dateKey == todayKey) {
      // Same day, return existing state
      return previousState;
    }

    final yesterdayKey = getYesterdayDateKey();
    if (previousState.dateKey == yesterdayKey && previousState.completed) {
      // Consecutive day - increment streak
      final newStreak = previousState.currentStreak + 1;
      return DailyState(
        dateKey: todayKey,
        currentStreak: newStreak,
        bestStreak: newStreak > previousState.bestStreak
            ? newStreak
            : previousState.bestStreak,
      );
    }

    // Streak broken - reset
    return DailyState(
      dateKey: todayKey,
      currentStreak: 1,
      bestStreak: previousState.bestStreak,
    );
  }

  /// Convert date string to a numeric seed
  int _dateToSeed(String dateKey) {
    // Parse YYYY-MM-DD
    final parts = dateKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    // Create a unique number for each date
    return year * 10000 + month * 100 + day;
  }

  /// Get calendar streak for display (last 7 days)
  List<bool> getCalendarStreak(int currentStreak) {
    final streak = <bool>[];
    for (int i = 6; i >= 0; i--) {
      // Days from current streak are true
      streak.add(i < currentStreak);
    }
    return streak;
  }
}

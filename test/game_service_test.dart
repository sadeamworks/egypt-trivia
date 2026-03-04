import 'package:flutter_test/flutter_test.dart';
import 'package:egypt_trivia/domain/services/game_service.dart';
import 'package:egypt_trivia/data/models/question.dart';

void main() {
  late GameService gameService;

  setUp(() {
    gameService = GameService();
  });

  final sampleQuestion = Question(
    id: 1,
    category: 'تاريخ مصر',
    question: 'من هو أول فرعون لمصر الموحدة؟',
    answers: const [
      Answer(text: 'نارمر (مينا)', isCorrect: true),
      Answer(text: 'خوفو', isCorrect: false),
      Answer(text: 'رمسيس الثاني', isCorrect: false),
      Answer(text: 'توت عنخ آمون', isCorrect: false),
    ],
  );

  group('calculateScore', () {
    test('returns base points when streak is 0', () {
      final score = gameService.calculateScore(
        currentStreak: 0,
        basePoints: 150,
      );
      expect(score, 150);
    });

    test('returns base points when streak is 1', () {
      final score = gameService.calculateScore(
        currentStreak: 1,
        basePoints: 150,
      );
      expect(score, 150);
    });

    test('applies x2 multiplier at streak 2', () {
      final score = gameService.calculateScore(
        currentStreak: 2,
        basePoints: 150,
      );
      expect(score, 300);
    });

    test('applies x3 multiplier at streak 3', () {
      final score = gameService.calculateScore(
        currentStreak: 3,
        basePoints: 150,
      );
      expect(score, 450);
    });

    test('applies x4 multiplier at streak 4+', () {
      final score = gameService.calculateScore(
        currentStreak: 4,
        basePoints: 150,
      );
      expect(score, 600);
    });

    test('caps multiplier at x4 for very high streaks', () {
      final score = gameService.calculateScore(
        currentStreak: 10,
        basePoints: 150,
      );
      expect(score, 600);
    });
  });

  group('checkAnswer', () {
    test('returns true for correct answer', () {
      expect(gameService.checkAnswer(sampleQuestion, 0), true);
    });

    test('returns false for wrong answer', () {
      expect(gameService.checkAnswer(sampleQuestion, 1), false);
      expect(gameService.checkAnswer(sampleQuestion, 2), false);
      expect(gameService.checkAnswer(sampleQuestion, 3), false);
    });
  });

  group('getCorrectAnswerIndex', () {
    test('returns index of correct answer', () {
      expect(gameService.getCorrectAnswerIndex(sampleQuestion), 0);
    });

    test('finds correct answer in any position', () {
      final questionWithCorrectLast = Question(
        id: 2,
        category: 'تاريخ مصر',
        question: 'test',
        answers: const [
          Answer(text: 'wrong1', isCorrect: false),
          Answer(text: 'wrong2', isCorrect: false),
          Answer(text: 'wrong3', isCorrect: false),
          Answer(text: 'correct', isCorrect: true),
        ],
      );
      expect(gameService.getCorrectAnswerIndex(questionWithCorrectLast), 3);
    });
  });

  group('applyFiftyFifty', () {
    test('returns exactly 2 indices', () {
      final hidden = gameService.applyFiftyFifty(sampleQuestion);
      expect(hidden.length, 2);
    });

    test('never hides the correct answer', () {
      // Run multiple times to account for randomness
      for (int i = 0; i < 20; i++) {
        final hidden = gameService.applyFiftyFifty(sampleQuestion);
        final correctIdx = gameService.getCorrectAnswerIndex(sampleQuestion);
        expect(hidden.contains(correctIdx), false);
      }
    });

    test('only hides wrong answers', () {
      for (int i = 0; i < 20; i++) {
        final hidden = gameService.applyFiftyFifty(sampleQuestion);
        for (final idx in hidden) {
          expect(sampleQuestion.answers[idx].isCorrect, false);
        }
      }
    });
  });
}

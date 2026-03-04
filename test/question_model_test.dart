import 'package:flutter_test/flutter_test.dart';
import 'package:egypt_trivia/data/models/question.dart';

void main() {
  group('Question.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'id': 1,
        'category': 'تاريخ مصر',
        'question': 'من هو أول فرعون لمصر الموحدة؟',
        'answers': [
          {'text': 'نارمر (مينا)', 'correct': true},
          {'text': 'خوفو', 'correct': false},
          {'text': 'رمسيس الثاني', 'correct': false},
          {'text': 'توت عنخ آمون', 'correct': false},
        ],
      };

      final question = Question.fromJson(json);
      expect(question.id, 1);
      expect(question.category, 'تاريخ مصر');
      expect(question.answers.length, 4);
      expect(question.correctAnswer.text, 'نارمر (مينا)');
    });

    test('toJson round-trips correctly', () {
      final original = Question(
        id: 42,
        category: 'جغرافيا',
        question: 'ما عاصمة مصر؟',
        answers: const [
          Answer(text: 'القاهرة', isCorrect: true),
          Answer(text: 'الإسكندرية', isCorrect: false),
          Answer(text: 'الجيزة', isCorrect: false),
          Answer(text: 'أسوان', isCorrect: false),
        ],
      );

      final json = original.toJson();
      final restored = Question.fromJson(json);
      expect(restored, original);
    });
  });

  group('Answer', () {
    test('equality works correctly', () {
      const a1 = Answer(text: 'test', isCorrect: true);
      const a2 = Answer(text: 'test', isCorrect: true);
      const a3 = Answer(text: 'test', isCorrect: false);

      expect(a1, a2);
      expect(a1, isNot(a3));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:egypt_trivia/domain/services/daily_service.dart';
import 'package:egypt_trivia/data/models/daily_state.dart';

void main() {
  late DailyService dailyService;

  setUp(() {
    dailyService = DailyService();
  });

  group('calculateNewStreak', () {
    test('first time playing starts streak at 1', () {
      final result = dailyService.calculateNewStreak(null, '2026-03-03');
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 1);
      expect(result.dateKey, '2026-03-03');
    });

    test('same day returns existing state', () {
      final existing = DailyState(
        dateKey: '2026-03-03',
        currentStreak: 5,
        bestStreak: 5,
        completed: true,
        score: 100,
      );
      final result = dailyService.calculateNewStreak(existing, '2026-03-03');
      expect(result.dateKey, '2026-03-03');
      expect(result.currentStreak, 5);
    });

    test('breaks streak if previous day was not completed', () {
      final existing = DailyState(
        dateKey: dailyService.getYesterdayDateKey(),
        currentStreak: 5,
        bestStreak: 10,
        completed: false,
      );
      final result = dailyService.calculateNewStreak(
          existing, dailyService.getTodayDateKey());
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 10); // best streak preserved
    });

    test('increments streak on consecutive completed day', () {
      final yesterdayKey = dailyService.getYesterdayDateKey();
      final todayKey = dailyService.getTodayDateKey();

      final existing = DailyState(
        dateKey: yesterdayKey,
        currentStreak: 3,
        bestStreak: 5,
        completed: true,
      );
      final result = dailyService.calculateNewStreak(existing, todayKey);
      expect(result.currentStreak, 4);
      expect(result.dateKey, todayKey);
    });

    test('updates best streak when current exceeds it', () {
      final yesterdayKey = dailyService.getYesterdayDateKey();
      final todayKey = dailyService.getTodayDateKey();

      final existing = DailyState(
        dateKey: yesterdayKey,
        currentStreak: 5,
        bestStreak: 5,
        completed: true,
      );
      final result = dailyService.calculateNewStreak(existing, todayKey);
      expect(result.currentStreak, 6);
      expect(result.bestStreak, 6);
    });

    test('resets streak if gap is more than 1 day', () {
      final existing = DailyState(
        dateKey: '2026-02-28',
        currentStreak: 10,
        bestStreak: 10,
        completed: true,
      );
      final result = dailyService.calculateNewStreak(existing, '2026-03-03');
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 10);
    });
  });

  group('getTodayDateKey', () {
    test('returns valid date format', () {
      final key = dailyService.getTodayDateKey();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key), true);
    });
  });

  group('getCalendarStreak', () {
    test('returns 7 booleans', () {
      final streak = dailyService.getCalendarStreak(3);
      expect(streak.length, 7);
    });

    test('marks correct number of days', () {
      final streak = dailyService.getCalendarStreak(3);
      final trueCount = streak.where((s) => s).length;
      expect(trueCount, 3);
    });

    test('zero streak means all false', () {
      final streak = dailyService.getCalendarStreak(0);
      expect(streak.every((s) => !s), true);
    });

    test('7+ streak means all true', () {
      final streak = dailyService.getCalendarStreak(7);
      expect(streak.every((s) => s), true);
    });
  });
}

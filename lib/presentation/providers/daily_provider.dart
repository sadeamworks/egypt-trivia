import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/question.dart';
import '../../data/models/daily_state.dart';
import '../../data/models/achievement.dart';
import '../../domain/services/daily_service.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/services/sound_service.dart';
import 'analytics_provider.dart';
import 'sound_provider.dart';
import 'achievement_provider.dart';

/// Daily challenge state
enum DailyStatus {
  idle,
  loading,
  playing,
  answering,
  completed,
}

class DailyGameState {
  final DailyStatus status;
  final List<Question> questions;
  final int currentIndex;
  final int selectedAnswerIndex;
  final bool? lastAnswerCorrect;
  final int correctAnswers;
  final DailyState? dailyState;

  const DailyGameState({
    this.status = DailyStatus.idle,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswerIndex = -1,
    this.lastAnswerCorrect,
    this.correctAnswers = 0,
    this.dailyState,
  });

  Question? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;
  int get totalQuestions => questions.length;

  DailyGameState copyWith({
    DailyStatus? status,
    List<Question>? questions,
    int? currentIndex,
    int? selectedAnswerIndex,
    bool? lastAnswerCorrect,
    int? correctAnswers,
    DailyState? dailyState,
  }) {
    return DailyGameState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswerIndex: selectedAnswerIndex ?? this.selectedAnswerIndex,
      lastAnswerCorrect: lastAnswerCorrect,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      dailyState: dailyState ?? this.dailyState,
    );
  }
}

class DailyNotifier extends StateNotifier<DailyGameState> {
  final DailyService _dailyService;
  final AnalyticsService? _analyticsService;
  final SoundService? _soundService;
  final AchievementNotifier? _achievementNotifier;
  Box<DailyState>? _dailyBox;

  DailyNotifier({
    DailyService? dailyService,
    AnalyticsService? analyticsService,
    SoundService? soundService,
    AchievementNotifier? achievementNotifier,
  })  : _dailyService = dailyService ?? DailyService(),
        _analyticsService = analyticsService,
        _soundService = soundService,
        _achievementNotifier = achievementNotifier,
        super(const DailyGameState());

  Future<void> initBox() async {
    _dailyBox ??= await Hive.openBox<DailyState>('dailyChallenge');
  }

  /// Start today's daily challenge
  Future<void> startDailyChallenge() async {
    state = state.copyWith(status: DailyStatus.loading);

    try {
      await initBox();

      final todayKey = _dailyService.getTodayDateKey();
      final questions = await _dailyService.getDailyQuestions(todayKey);

      // Check if already completed today
      final existingState = _dailyBox!.get('current');
      DailyState dailyState;

      if (existingState?.dateKey == todayKey && existingState!.completed) {
        // Already completed today
        state = state.copyWith(
          status: DailyStatus.completed,
          dailyState: existingState,
        );
        return;
      }

      // Calculate streak
      dailyState = _dailyService.calculateNewStreak(existingState, todayKey);

      state = state.copyWith(
        status: DailyStatus.playing,
        questions: questions,
        currentIndex: 0,
        correctAnswers: 0,
        dailyState: dailyState,
      );

      // Track daily challenge start
      _analyticsService?.logDailyChallengeStart(streakDays: dailyState.currentStreak);
    } catch (e) {
      state = state.copyWith(status: DailyStatus.idle);
    }
  }

  /// Select an answer
  void selectAnswer(int answerIndex) {
    if (state.status != DailyStatus.playing) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = question.answers[answerIndex].isCorrect;

    // Play sound feedback
    if (isCorrect) {
      _soundService?.play(SoundEffect.correct);
    } else {
      _soundService?.play(SoundEffect.wrong);
    }

    state = state.copyWith(
      status: DailyStatus.answering,
      selectedAnswerIndex: answerIndex,
      lastAnswerCorrect: isCorrect,
      correctAnswers: isCorrect ? state.correctAnswers + 1 : state.correctAnswers,
    );

    // Move to next question after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _moveToNext();
    });
  }

  void _moveToNext() {
    if (state.isLastQuestion) {
      _completeChallenge();
      return;
    }

    state = state.copyWith(
      status: DailyStatus.playing,
      currentIndex: state.currentIndex + 1,
      selectedAnswerIndex: -1,
      lastAnswerCorrect: null,
    );
  }

  void _completeChallenge() async {
    final completedState = state.dailyState?.copyWith(
      completed: true,
      score: state.correctAnswers * 100,
      correctAnswers: state.correctAnswers,
    );

    if (completedState != null && _dailyBox != null) {
      await _dailyBox!.put('current', completedState);
    }

    // Play win sound
    _soundService?.play(SoundEffect.win);

    state = state.copyWith(
      status: DailyStatus.completed,
      dailyState: completedState,
    );

    // Track daily challenge complete
    if (completedState != null) {
      _analyticsService?.logDailyChallengeComplete(
        score: completedState.score,
        streakDays: completedState.currentStreak,
        correctAnswers: completedState.correctAnswers,
      );

      // Update achievements
      if (_achievementNotifier != null) {
        // First game
        await _achievementNotifier!.incrementProgress(AchievementType.firstGame);
        // Games played
        await _achievementNotifier!.incrementProgress(AchievementType.gamesPlayed10);
        await _achievementNotifier!.incrementProgress(AchievementType.gamesPlayed50);
        // Daily challenge streak achievements
        await _achievementNotifier!.updateProgress(
          AchievementType.dailyChallenge7,
          completedState.currentStreak,
        );
        await _achievementNotifier!.updateProgress(
          AchievementType.dailyChallenge30,
          completedState.currentStreak,
        );
        // Points achievements
        await _achievementNotifier!.updateProgress(
          AchievementType.points1000,
          completedState.score,
        );
        await _achievementNotifier!.updateProgress(
          AchievementType.points5000,
          completedState.score,
        );
      }
    }
  }

  /// Reset daily challenge state
  void reset() {
    state = const DailyGameState();
  }
}

/// Provider for daily challenge state
final dailyProvider = StateNotifierProvider<DailyNotifier, DailyGameState>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final soundService = ref.watch(soundServiceProvider);
  // Use ref.read to avoid rebuilding dailyProvider when achievement state changes
  final achievementNotifier = ref.read(achievementProvider.notifier);
  return DailyNotifier(
    analyticsService: analyticsService,
    soundService: soundService,
    achievementNotifier: achievementNotifier,
  );
});

/// Provider to check if daily challenge is completed today
final dailyCompletedProvider = FutureProvider<bool>((ref) async {
  final box = await Hive.openBox<DailyState>('dailyChallenge');
  final state = box.get('current');
  final dailyService = DailyService();
  final todayKey = dailyService.getTodayDateKey();
  return state?.dateKey == todayKey && (state?.completed ?? false);
});

/// Provider for current streak
final dailyStreakProvider = FutureProvider<int>((ref) async {
  final box = await Hive.openBox<DailyState>('dailyChallenge');
  final state = box.get('current');
  return state?.currentStreak ?? 0;
});

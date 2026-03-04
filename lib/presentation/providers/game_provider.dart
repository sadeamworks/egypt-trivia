import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_config.dart';
import '../../data/models/question.dart';
import '../../data/models/game_result.dart';
import '../../data/datasources/questions_loader.dart';
import '../../domain/services/game_service.dart';
import '../../domain/services/analytics_service.dart';
import '../../domain/services/sound_service.dart';
import 'analytics_provider.dart';
import 'sound_provider.dart';

/// Game state enum
enum GameStatus {
  idle,
  loading,
  playing,
  answering,
  roundComplete,
  gameOver,
  error,
}

/// Immutable game state
class GameState {
  final GameStatus status;
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final int streak;
  final int bestStreak;
  final int lives;
  final int correctAnswers;
  final String? selectedAnswerId;
  final bool? lastAnswerCorrect;
  final bool fiftyFiftyUsed;
  final List<int> hiddenAnswers;
  final int? timerValue;
  final String category;
  final String? errorMessage;

  const GameState({
    this.status = GameStatus.idle,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lives = GameConfig.initialLives,
    this.correctAnswers = 0,
    this.selectedAnswerId,
    this.lastAnswerCorrect,
    this.fiftyFiftyUsed = false,
    this.hiddenAnswers = const [],
    this.timerValue,
    this.category = 'تاريخ مصر',
    this.errorMessage,
  });

  Question? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;
  int get totalQuestions => questions.length;

  GameState copyWith({
    GameStatus? status,
    List<Question>? questions,
    int? currentIndex,
    int? score,
    int? streak,
    int? bestStreak,
    int? lives,
    int? correctAnswers,
    String? selectedAnswerId,
    bool? lastAnswerCorrect,
    bool? fiftyFiftyUsed,
    List<int>? hiddenAnswers,
    int? timerValue,
    String? category,
    String? errorMessage,
  }) {
    return GameState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      lives: lives ?? this.lives,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      selectedAnswerId: selectedAnswerId,
      lastAnswerCorrect: lastAnswerCorrect,
      fiftyFiftyUsed: fiftyFiftyUsed ?? this.fiftyFiftyUsed,
      hiddenAnswers: hiddenAnswers ?? this.hiddenAnswers,
      timerValue: timerValue,
      category: category ?? this.category,
      errorMessage: errorMessage,
    );
  }
}

/// Game state notifier
class GameNotifier extends StateNotifier<GameState> {
  final QuestionsLoader _questionsLoader;
  final GameService _gameService;
  final AnalyticsService? _analyticsService;
  final SoundService? _soundService;
  Timer? _timer;

  GameNotifier({
    QuestionsLoader? questionsLoader,
    GameService? gameService,
    AnalyticsService? analyticsService,
    SoundService? soundService,
  })  : _questionsLoader = questionsLoader ?? QuestionsLoader(),
        _gameService = gameService ?? GameService(),
        _analyticsService = analyticsService,
        _soundService = soundService,
        super(const GameState());

  /// Start a new game
  Future<void> startGame({String categoryName = 'تاريخ مصر'}) async {
    state = state.copyWith(status: GameStatus.loading, errorMessage: null);

    try {
      final questions = await _questionsLoader.getRandomQuestions(
        categoryName: categoryName,
        count: GameConfig.questionsPerRound,
      );

      // Check if we got any questions
      if (questions.isEmpty) {
        state = state.copyWith(
          status: GameStatus.error,
          errorMessage: 'لا توجد أسئلة في هذا القسم',
        );
        return;
      }

      state = GameState(
        status: GameStatus.playing,
        questions: questions,
        category: categoryName,
      );

      // Track game start
      _analyticsService?.logGameStart(
        category: categoryName,
        questionsCount: questions.length,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: 'حدث خطأ أثناء تحميل الأسئلة',
      );
    }
  }

  /// Start the question timer
  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(timerValue: GameConfig.timerDurationSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newValue = (state.timerValue ?? 0) - 1;

      if (newValue <= 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        if (newValue <= 5) {
          _soundService?.play(SoundEffect.tick);
        }
        state = state.copyWith(timerValue: newValue);
      }
    });
  }

  /// Handle timer running out
  void _handleTimeout() {
    _processAnswer(-1, isTimeout: true);
  }

  /// Select an answer
  void selectAnswer(int answerIndex) {
    if (state.status != GameStatus.playing) return;

    _timer?.cancel();
    _processAnswer(answerIndex);
  }

  /// Process the selected answer
  void _processAnswer(int answerIndex, {bool isTimeout = false}) {
    final question = state.currentQuestion;
    if (question == null) return;

    bool isCorrect = false;
    if (!isTimeout && answerIndex >= 0) {
      isCorrect = _gameService.checkAnswer(question, answerIndex);
    }

    int newScore = state.score;
    int newStreak = state.streak;
    int newBestStreak = state.bestStreak;
    int newLives = state.lives;
    int newCorrectAnswers = state.correctAnswers;

    if (isCorrect) {
      newStreak++;
      if (newStreak > newBestStreak) {
        newBestStreak = newStreak;
      }
      newCorrectAnswers++;
      newScore += _gameService.calculateScore(
        currentStreak: newStreak,
        basePoints: GameConfig.basePointsPerQuestion,
      );
      // Play sound
      if (newStreak >= 3) {
        _soundService?.play(SoundEffect.streak);
      } else {
        _soundService?.play(SoundEffect.correct);
      }
    } else {
      newStreak = 0;
      newLives--;
      if (isTimeout) {
        _soundService?.play(SoundEffect.timeout);
      } else {
        _soundService?.play(SoundEffect.wrong);
      }
    }

    state = state.copyWith(
      status: GameStatus.answering,
      selectedAnswerId: answerIndex >= 0 ? answerIndex.toString() : null,
      lastAnswerCorrect: isCorrect,
      score: newScore,
      streak: newStreak,
      bestStreak: newBestStreak,
      lives: newLives,
      correctAnswers: newCorrectAnswers,
    );

    // Track answer selection
    _analyticsService?.logAnswerSelected(
      correct: isCorrect,
      timeRemaining: state.timerValue ?? 0,
      usedLifeline: state.fiftyFiftyUsed,
    );

    // Move to next question after delay
    Future.delayed(GameConfig.answerFeedbackDuration, () {
      _moveToNextQuestion();
    });
  }

  /// Move to the next question or end game
  void _moveToNextQuestion() {
    if (state.lives <= 0) {
      state = state.copyWith(status: GameStatus.gameOver);
      _soundService?.play(SoundEffect.gameOver);
      // Track game over
      _analyticsService?.logGameOver(
        category: state.category,
        score: state.score,
        livesRemaining: 0,
      );
      return;
    }

    if (state.isLastQuestion) {
      state = state.copyWith(status: GameStatus.roundComplete);
      _soundService?.play(SoundEffect.win);
      // Track game complete
      _analyticsService?.logGameComplete(
        category: state.category,
        score: state.score,
        streak: state.bestStreak,
        correctAnswers: state.correctAnswers,
        totalQuestions: state.totalQuestions,
      );
      // Update engagement tier
      _analyticsService?.updateEngagementTier();
      return;
    }

    state = state.copyWith(
      status: GameStatus.playing,
      currentIndex: state.currentIndex + 1,
      selectedAnswerId: null,
      lastAnswerCorrect: null,
      hiddenAnswers: const [],
    );

    _startTimer();
  }

  /// Use 50/50 lifeline
  void useFiftyFifty() {
    if (state.fiftyFiftyUsed || state.status != GameStatus.playing) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final hiddenAnswers = _gameService.applyFiftyFifty(question);
    _soundService?.play(SoundEffect.lifeline);

    state = state.copyWith(
      fiftyFiftyUsed: true,
      hiddenAnswers: hiddenAnswers,
      timerValue: state.timerValue,
    );
  }

  /// Get the game result
  GameResult getGameResult() {
    return GameResult(
      category: state.category,
      score: state.score,
      bestStreak: state.bestStreak,
      correctAnswers: state.correctAnswers,
      totalQuestions: state.totalQuestions,
    );
  }

  /// Reset the game
  void resetGame() {
    _timer?.cancel();
    state = const GameState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the game state
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final soundService = ref.watch(soundServiceProvider);
  return GameNotifier(
    analyticsService: analyticsService,
    soundService: soundService,
  );
});

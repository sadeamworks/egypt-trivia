import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/game_provider.dart';
import '../../../routing/routes.dart';
import '../../widgets/common/egyptian_background.dart';
import '../../widgets/animated_streak_display.dart';
import '../../widgets/animated_answer_button.dart';
import 'widgets/question_card.dart';
import 'widgets/timer_display.dart';
import 'widgets/lives_display.dart';

/// Main game screen where trivia is played
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    // Listen for game state changes
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.status == GameStatus.roundComplete) {
        final result = ref.read(gameProvider.notifier).getGameResult();
        context.pushReplacement(Routes.score, extra: result);
      } else if (next.status == GameStatus.gameOver) {
        context.pushReplacement(Routes.gameOver);
      } else if (next.status == GameStatus.idle) {
        // If game is idle (not started), go back to home
        context.go(Routes.home);
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: _buildContent(context, ref, gameState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GameState gameState) {
    switch (gameState.status) {
      case GameStatus.loading:
        return _buildLoading(context);
      case GameStatus.idle:
        return _buildLoading(context); // Will redirect via listener
      case GameStatus.error:
        return _buildError(context, ref, gameState);
      case GameStatus.playing:
      case GameStatus.answering:
        return _buildGameContent(context, ref, gameState);
      case GameStatus.roundComplete:
      case GameStatus.gameOver:
        return _buildLoading(context); // Will redirect via listener
    }
  }

  Widget _buildError(BuildContext context, WidgetRef ref, GameState gameState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              gameState.errorMessage ?? 'حدث خطأ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).resetGame();
                context.go(Routes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل الأسئلة...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
  ) {
    final question = gameState.currentQuestion;

    if (question == null) {
      return _buildLoading(context);
    }

    return Column(
      children: [
        _buildTopBar(context, ref, gameState),
        const SizedBox(height: 16),
        AnimatedStreakDisplay(
          streak: gameState.streak,
          score: gameState.score,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                QuestionCard(
                  question: question.question,
                  questionNumber: gameState.currentIndex + 1,
                  totalQuestions: gameState.totalQuestions,
                ),
                const SizedBox(height: 24),
                ...List.generate(4, (index) {
                  final isHidden = gameState.hiddenAnswers.contains(index);
                  final isSelected =
                      gameState.selectedAnswerId == index.toString();
                  final isCorrect = question.answers[index].isCorrect;
                  final showResult = gameState.status == GameStatus.answering;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedAnswerButton(
                      answer: question.answers[index].text,
                      index: index,
                      isHidden: isHidden,
                      isSelected: isSelected,
                      isCorrect: isCorrect,
                      showResult: showResult,
                      onTap: gameState.status == GameStatus.playing
                          ? () => ref
                              .read(gameProvider.notifier)
                              .selectAnswer(index)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        _buildBottomBar(context, ref, gameState),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(gameProvider.notifier).resetGame();
              context.go(Routes.home);
            },
          ),
          const Spacer(),
          // Category name
          Text(
            gameState.category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          // Timer
          TimerDisplay(seconds: gameState.timerValue ?? 0),
          const SizedBox(width: 8),
          // Lives
          LivesDisplay(lives: gameState.lives),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.papyrus,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 50/50 lifeline button
          _buildLifelineButton(
            context: context,
            icon: Icons.filter_2,
            label: '50/50',
            isUsed: gameState.fiftyFiftyUsed,
            onTap: gameState.fiftyFiftyUsed || gameState.status != GameStatus.playing
                ? null
                : () => ref.read(gameProvider.notifier).useFiftyFifty(),
          ),
        ],
      ),
    );
  }

  Widget _buildLifelineButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isUsed,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isUsed ? AppColors.heartEmpty : AppColors.gold,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUsed ? Colors.transparent : AppColors.goldDark,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isUsed ? AppColors.textSecondary : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isUsed ? AppColors.textSecondary : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

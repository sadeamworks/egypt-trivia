import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/daily_provider.dart';
import '../../widgets/common/egyptian_background.dart';
import '../../../routing/routes.dart';

/// Daily Challenge screen
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: _buildContent(context, ref, dailyState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dailyState) {
    switch (dailyState.status) {
      case DailyStatus.idle:
      case DailyStatus.loading:
        return _buildLoading(context, ref);
      case DailyStatus.playing:
      case DailyStatus.answering:
        return _buildGameContent(context, ref, dailyState);
      case DailyStatus.completed:
        return _buildCompleted(context, ref, dailyState);
      default:
        return _buildLoading(context, ref);
    }
  }

  Widget _buildLoading(BuildContext context, WidgetRef ref) {
    // Auto-start the challenge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyProvider.notifier).startDailyChallenge();
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل التحدي اليومي...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, WidgetRef ref, dailyState) {
    final question = dailyState.currentQuestion;

    if (question == null) {
      return _buildLoading(context, ref);
    }

    return Column(
      children: [
        _buildTopBar(context, ref, dailyState),
        const SizedBox(height: 24),
        _buildStreakDisplay(context, dailyState),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildQuestionCard(context, dailyState),
                const SizedBox(height: 24),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnswerButton(
                      context,
                      ref,
                      question.answers[index].text,
                      index,
                      question.answers[index].isCorrect,
                      dailyState,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, dailyState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(dailyProvider.notifier).reset();
              context.go(Routes.home);
            },
          ),
          const Spacer(),
          Text(
            'التحدي اليومي',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStreakDisplay(BuildContext context, dailyState) {
    final streak = dailyState.dailyState?.currentStreak ?? 0;
    final calendarStreak = List.generate(7, (i) => i < streak);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '$streak أيام متتالية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: calendarStreak[index]
                        ? AppColors.success
                        : AppColors.heartEmpty,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: calendarStreak[index]
                          ? AppColors.success
                          : AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: calendarStreak[index]
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, dailyState) {
    final question = dailyState.currentQuestion!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.papyrus,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'سؤال ${dailyState.currentIndex + 1} من ${dailyState.totalQuestions}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(
    BuildContext context,
    WidgetRef ref,
    String answer,
    int index,
    bool isCorrect,
    dailyState,
  ) {
    final isSelected = dailyState.selectedAnswerIndex == index;
    final showResult = dailyState.status == DailyStatus.answering;

    Color bgColor = AppColors.papyrus;
    Color textColor = AppColors.textPrimary;
    Color borderColor = AppColors.gold;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppColors.success;
        textColor = Colors.white;
        borderColor = AppColors.success;
      } else if (isSelected && !isCorrect) {
        bgColor = AppColors.error;
        textColor = Colors.white;
        borderColor = AppColors.error;
      }
    }

    return GestureDetector(
      onTap: dailyState.status == DailyStatus.playing
          ? () => ref.read(dailyProvider.notifier).selectAnswer(index)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  ['أ', 'ب', 'ج', 'د'][index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted(BuildContext context, WidgetRef ref, dailyState) {
    final correctAnswers = dailyState.correctAnswers;
    final totalQuestions = dailyState.totalQuestions;
    final score = correctAnswers * 100;
    final streak = dailyState.dailyState?.currentStreak ?? 0;
    final bestStreak = dailyState.dailyState?.bestStreak ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'أحسنت!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'نقطة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.papyrus,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        '$correctAnswers/$totalQuestions إجابات صحيحة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '$streak أيام متتالية',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  if (bestStreak > streak) ...[
                    const SizedBox(height: 8),
                    Text(
                      'أفضل سلسلة: $bestStreak يوم',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(dailyProvider.notifier).reset();
                context.go(Routes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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
}

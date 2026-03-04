import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/common/egyptian_background.dart';
import '../../../routing/routes.dart';

/// Achievements screen showing all achievements and progress
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildProgressSummary(context, achievementState),
                Expanded(
                  child: _buildAchievementsList(context, ref, achievementState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => context.go(Routes.home),
          ),
          const Spacer(),
          Text(
            'الإنجازات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context, AchievementState state) {
    final completion = state.totalAchievements > 0
        ? state.totalUnlocked / state.totalAchievements
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                '${state.totalUnlocked}/${state.totalAchievements}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتمل ${(completion * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(
    BuildContext context,
    WidgetRef ref,
    AchievementState state,
  ) {
    final achievements = ref.read(achievementProvider.notifier).getAllAchievements();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final definition = achievement['definition'] as AchievementDefinition;
        final isUnlocked = achievement['isUnlocked'] as bool;
        final progress = achievement['progress'] as int;
        final progressPercent = achievement['progressPercent'] as double;

        return _buildAchievementCard(
          context: context,
          definition: definition,
          isUnlocked: isUnlocked,
          progress: progress,
          progressPercent: progressPercent,
        );
      },
    );
  }

  Widget _buildAchievementCard({
    required BuildContext context,
    required AchievementDefinition definition,
    required bool isUnlocked,
    required int progress,
    required double progressPercent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.papyrus : AppColors.papyrus.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? AppColors.gold : AppColors.gold.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.gold.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                definition.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.nameAr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isUnlocked ? AppColors.textPrimary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  definition.descriptionAr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUnlocked ? AppColors.textSecondary : Colors.grey,
                      ),
                ),
                if (!isUnlocked && definition.targetValue > 1) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnlocked ? AppColors.success : AppColors.gold,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress/${definition.targetValue}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          // Status
          if (isUnlocked)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
        ],
      ),
    );
  }
}

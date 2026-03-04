import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/game_config.dart';

/// Displays current streak and score
class StreakDisplay extends StatelessWidget {
  final int streak;
  final int score;

  const StreakDisplay({
    super.key,
    required this.streak,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = GameConfig.getStreakMultiplier(streak);
    final hasStreak = streak >= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: hasStreak ? AppColors.gold.withOpacity(0.2) : AppColors.papyrus,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStreak ? AppColors.gold : AppColors.gold.withOpacity(0.3),
          width: hasStreak ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streak fire icon
          if (hasStreak) ...[
            Text(
              '🔥',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
          ],
          // Streak count
          if (streak > 0)
            Text(
              'streak: $streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (hasStreak) ...[
            const SizedBox(width: 8),
            // Multiplier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '×$multiplier',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
          const SizedBox(width: 24),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.papyrus,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

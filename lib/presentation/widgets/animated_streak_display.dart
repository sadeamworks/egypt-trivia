import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/game_config.dart';

/// Animated streak display with fire effect
class AnimatedStreakDisplay extends StatefulWidget {
  final int streak;
  final int score;

  const AnimatedStreakDisplay({
    super.key,
    required this.streak,
    required this.score,
  });

  @override
  State<AnimatedStreakDisplay> createState() => _AnimatedStreakDisplayState();
}

class _AnimatedStreakDisplayState extends State<AnimatedStreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _previousStreak = widget.streak;
  }

  @override
  void didUpdateWidget(AnimatedStreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > _previousStreak) {
      // Streak increased - trigger animation
      _controller.forward().then((_) => _controller.reverse());
    }
    _previousStreak = widget.streak;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = GameConfig.getStreakMultiplier(widget.streak);
    final hasStreak = widget.streak >= 2;

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
          // Animated streak fire
          if (hasStreak)
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: const Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
            ),
          if (hasStreak) const SizedBox(width: 8),
          // Streak count
          if (widget.streak > 0)
            Text(
              'streak: ${widget.streak}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (hasStreak) ...[
            const SizedBox(width: 8),
            // Multiplier badge
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
          // Score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.papyrus,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedScore(
              score: widget.score,
              textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

/// Animated score counter that counts up
class AnimatedScore extends StatefulWidget {
  final int score;
  final TextStyle? textStyle;

  const AnimatedScore({
    super.key,
    required this.score,
    this.textStyle,
  });

  @override
  State<AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score != oldWidget.score) {
      _animation = IntTween(begin: oldWidget.score, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: widget.textStyle,
        );
      },
    );
  }
}

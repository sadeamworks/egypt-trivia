import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/game_config.dart';

/// Displays remaining lives as hearts
class LivesDisplay extends StatelessWidget {
  final int lives;

  const LivesDisplay({
    super.key,
    required this.lives,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        GameConfig.maxLives,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              index < lives ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(index < lives),
              color: index < lives ? AppColors.heart : AppColors.heartEmpty,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

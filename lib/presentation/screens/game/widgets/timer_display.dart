import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Timer display showing remaining seconds
class TimerDisplay extends StatelessWidget {
  final int seconds;

  const TimerDisplay({
    super.key,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    final isWarning = seconds <= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.timer : Icons.timer_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$seconds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (seconds <= 3) return AppColors.timerCritical;
    if (seconds <= 7) return AppColors.timerWarning;
    return AppColors.timerNormal;
  }
}

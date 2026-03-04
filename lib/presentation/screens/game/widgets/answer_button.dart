import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Answer option button with visual feedback
class AnswerButton extends StatelessWidget {
  final String answer;
  final bool isHidden;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const AnswerButton({
    super.key,
    required this.answer,
    this.isHidden = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHidden) {
      return const SizedBox.shrink();
    }

    Color backgroundColor = AppColors.papyrus;
    Color borderColor = AppColors.gold.withOpacity(0.3);
    Color textColor = AppColors.textPrimary;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = AppColors.success;
        borderColor = AppColors.success;
        textColor = Colors.white;
      } else if (isSelected && !isCorrect) {
        backgroundColor = AppColors.error;
        borderColor = AppColors.error;
        textColor = Colors.white;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.gold;
      borderColor = AppColors.gold;
      textColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Answer indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: textColor, width: 2),
                  ),
                  child: Center(
                    child: showResult
                        ? Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: textColor,
                            size: 20,
                          )
                        : Text(
                            _getAnswerLetter(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Answer text
                Expanded(
                  child: Text(
                    answer,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAnswerLetter() {
    // Arabic letters for answers: أ، ب، ج، د
    const letters = ['أ', 'ب', 'ج', 'د'];
    // Use the answer index based on context
    return letters[0]; // Default, will be improved with index
  }
}

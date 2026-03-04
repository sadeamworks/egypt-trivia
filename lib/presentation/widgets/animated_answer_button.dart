import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated answer button with shake and pulse effects
class AnimatedAnswerButton extends StatefulWidget {
  final String answer;
  final bool isHidden;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;
  final int index;

  const AnimatedAnswerButton({
    super.key,
    required this.answer,
    required this.index,
    this.isHidden = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.onTap,
  });

  @override
  State<AnimatedAnswerButton> createState() => _AnimatedAnswerButtonState();
}

class _AnimatedAnswerButtonState extends State<AnimatedAnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _wasWrong = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Shake animation for wrong answers
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedAnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation when wrong answer is shown
    if (widget.showResult && widget.isSelected && !widget.isCorrect && !_wasWrong) {
      _controller.forward();
      _wasWrong = true;
    }
    if (!widget.showResult) {
      _wasWrong = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAnswerLetter() {
    const letters = ['أ', 'ب', 'ج', 'د'];
    return letters[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHidden) {
      // Show disabled/greyed-out button instead of hiding completely
      // This prevents layout shifts that cause phantom taps
      return Opacity(
        opacity: 0.3,
        child: IgnorePointer(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: Center(
                    child: Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.answer,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Color backgroundColor = AppColors.papyrus;
    Color borderColor = AppColors.gold.withValues(alpha: 0.3);
    Color textColor = AppColors.textPrimary;

    if (widget.showResult) {
      if (widget.isSelected && widget.isCorrect) {
        // Only highlight green if user SELECTED the correct answer
        backgroundColor = AppColors.success;
        borderColor = AppColors.success;
        textColor = Colors.white;
      } else if (widget.isSelected && !widget.isCorrect) {
        backgroundColor = AppColors.error;
        borderColor = AppColors.error;
        textColor = Colors.white;
      } else if (widget.isCorrect) {
        // Show correct answer with subtle highlight (not selected, but reveal)
        borderColor = AppColors.success;
      }
    } else if (widget.isSelected) {
      backgroundColor = AppColors.gold;
      borderColor = AppColors.gold;
      textColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Apply shake for wrong answers, scale for press
        final shakeOffset = widget.isSelected && !widget.isCorrect && widget.showResult
            ? _shakeAnimation.value
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
        onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
        onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
        onTap: widget.onTap,
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
                color: borderColor.withValues(alpha: 0.3),
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
                  child: widget.showResult
                      ? Icon(
                          widget.isCorrect ? Icons.check : Icons.close,
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
                  widget.answer,
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
    );
  }
}

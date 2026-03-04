import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Egyptian-themed background with pyramid/sand pattern
class EgyptianBackground extends StatelessWidget {
  final Widget child;

  const EgyptianBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sand,
            AppColors.papyrus,
            AppColors.sandLight,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Pyramid pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: PyramidPatternPainter(),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
}

/// Custom painter for pyramid pattern
class PyramidPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle pyramid shapes
    _drawPyramid(canvas, size, paint, size.width * 0.1, size.height * 0.8, 40);
    _drawPyramid(canvas, size, paint, size.width * 0.85, size.height * 0.85, 30);
    _drawPyramid(canvas, size, paint, size.width * 0.05, size.height * 0.9, 25);

    // Draw subtle hieroglyphic-like dots
    final dotPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 47.0) % size.width;
      final y = (i * 31.0) % size.height;
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  void _drawPyramid(Canvas canvas, Size size, Paint paint, double x, double y, double pyramidSize) {
    final path = Path()
      ..moveTo(x, y - pyramidSize)
      ..lineTo(x + pyramidSize * 0.8, y)
      ..lineTo(x - pyramidSize * 0.8, y)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

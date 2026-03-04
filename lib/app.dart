import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Main app widget with Egyptian theme and RTL support
class EgyptTriviaApp extends StatelessWidget {
  const EgyptTriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'تريفيا مصر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      // Force RTL for the entire app
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Ensure text scaling is appropriate
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

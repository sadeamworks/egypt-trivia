import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/game/game_screen.dart';
import '../presentation/screens/score/score_screen.dart';
import '../presentation/screens/game_over/game_over_screen.dart';
import '../presentation/screens/daily/daily_screen.dart';
import '../presentation/screens/achievements/achievements_screen.dart';
import '../data/models/game_result.dart';
import 'routes.dart';

/// App router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  // Deep linking: redirect unknown deep link paths to home
  redirect: (context, state) {
    final path = state.uri.path;
    final validPaths = [
      Routes.home, Routes.game, Routes.score,
      Routes.gameOver, Routes.daily, Routes.achievements,
    ];
    if (!validPaths.contains(path)) {
      return Routes.home;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.game,
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: Routes.score,
      builder: (context, state) {
        // Get game result from state extra
        final result = state.extra as GameResult?;
        return ScoreScreen(result: result);
      },
    ),
    GoRoute(
      path: Routes.gameOver,
      builder: (context, state) => const GameOverScreen(),
    ),
    GoRoute(
      path: Routes.daily,
      builder: (context, state) => const DailyScreen(),
    ),
    GoRoute(
      path: Routes.achievements,
      builder: (context, state) => const AchievementsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'الصفحة غير موجودة',
        style: Theme.of(context).textTheme.headlineMedium,
        textDirection: TextDirection.rtl,
      ),
    ),
  ),
);

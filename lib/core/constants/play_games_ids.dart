import 'package:flutter/foundation.dart';

/// Google Play Games Services IDs
///
/// Fill these in from the Play Console → Play Games Services → Achievements / Leaderboards
/// after you configure them there.
class PlayGamesIds {
  // ────────────────────────────────────────────────
  // App ID — from Play Console → Play Games Services → Setup & Management → Configuration
  // Add as meta-data in android/app/src/main/res/values/strings.xml
  // ────────────────────────────────────────────────

  // ────────────────────────────────────────────────
  // Leaderboard IDs
  // ────────────────────────────────────────────────
  static const String leaderboardAllTime = 'YOUR_LEADERBOARD_ID_ALL_TIME';

  // ────────────────────────────────────────────────
  // Achievement IDs  (match the `id` in AchievementDefinition)
  // ────────────────────────────────────────────────
  static const Map<String, String> achievementIds = {
    'first_game':    'YOUR_ACHIEVEMENT_ID_FIRST_GAME',
    'perfect_score': 'YOUR_ACHIEVEMENT_ID_PERFECT_SCORE',
    'streak_7':      'YOUR_ACHIEVEMENT_ID_STREAK_7',
    'streak_30':     'YOUR_ACHIEVEMENT_ID_STREAK_30',
    'points_1000':   'YOUR_ACHIEVEMENT_ID_POINTS_1000',
    'points_5000':   'YOUR_ACHIEVEMENT_ID_POINTS_5000',
    'daily_7':       'YOUR_ACHIEVEMENT_ID_DAILY_7',
    'daily_30':      'YOUR_ACHIEVEMENT_ID_DAILY_30',
    'games_10':      'YOUR_ACHIEVEMENT_ID_GAMES_10',
    'games_50':      'YOUR_ACHIEVEMENT_ID_GAMES_50',
  };

  // ────────────────────────────────────────────────
  // Pre-release guard — call from PlayGamesService.initialize()
  // ────────────────────────────────────────────────

  /// Logs a loud warning in debug mode for every ID still set to a placeholder.
  /// Call this once at app startup. Silent in release builds.
  static void validate() {
    if (!kDebugMode) return;

    final issues = <String>[];

    if (leaderboardAllTime.startsWith('YOUR_')) {
      issues.add('leaderboardAllTime');
    }

    for (final entry in achievementIds.entries) {
      if (entry.value.startsWith('YOUR_')) {
        issues.add('achievement:${entry.key}');
      }
    }

    // strings.xml App ID reminder
    issues.add('strings.xml → app_id (YOUR_PLAY_GAMES_APP_ID)');

    debugPrint(
      '\n╔══════════════════════════════════════════════════════╗\n'
      '║  [PlayGames] ⚠️  GPGS IDs NOT CONFIGURED (${issues.length} items) ║\n'
      '╠══════════════════════════════════════════════════════╣\n'
      '${issues.map((i) => '║  • $i').join('\n')}\n'
      '╠══════════════════════════════════════════════════════╣\n'
      '║  → lib/core/constants/play_games_ids.dart            ║\n'
      '║  → android/app/src/main/res/values/strings.xml       ║\n'
      '╚══════════════════════════════════════════════════════╝\n',
    );
  }
}

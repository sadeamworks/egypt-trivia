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
  static const String leaderboardAllTime = 'CgkIg4ixlY0PEAIQDA';

  // ────────────────────────────────────────────────
  // Achievement IDs  (match the `id` in AchievementDefinition)
  // ────────────────────────────────────────────────
  static const Map<String, String> achievementIds = {
    'first_game':    'CgkIg4ixlY0PEAIQBQ',
    'perfect_score': 'CgkIg4ixlY0PEAIQBg',
    'streak_7':      'CgkIg4ixlY0PEAIQCA',
    'streak_30':     'CgkIg4ixlY0PEAIQCQ',
    'points_1000':   'CgkIg4ixlY0PEAIQBw',
    'points_5000':   'CgkIg4ixlY0PEAIQAg',
    'daily_7':       'CgkIg4ixlY0PEAIQBA',
    'daily_30':      'CgkIg4ixlY0PEAIQAw',
    'games_10':      'CgkIg4ixlY0PEAIQCw',
    'games_50':      'CgkIg4ixlY0PEAIQCg',
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

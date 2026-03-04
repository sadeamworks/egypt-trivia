import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking analytics events
/// Gracefully falls back to console logging when Firebase is not configured
class AnalyticsService {
  static const String _prefTotalGames = 'analytics_total_games';
  static const String _prefFirstOpenDate = 'analytics_first_open';
  static const String _prefFavoriteCategory = 'analytics_favorite_category';

  bool _isInitialized = false;
  bool _firebaseAvailable = false;
  FirebaseAnalytics? _analytics;

  /// Initialize analytics service
  Future<void> initialize() async {
    try {
      _firebaseAvailable = await _checkFirebaseAvailability();

      if (_firebaseAvailable) {
        _analytics = FirebaseAnalytics.instance;
        debugPrint('[Analytics] Firebase Analytics initialized successfully');
      } else {
        debugPrint('[Analytics] Firebase not configured, using console logging');
      }

      // Track first open
      await _trackFirstOpen();

      // Track app opened
      await logAppOpened();

      _isInitialized = true;
    } catch (e) {
      debugPrint('[Analytics] Initialization error: $e');
      _firebaseAvailable = false;
    }
  }

  /// Check if Firebase is available
  Future<bool> _checkFirebaseAvailability() async {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Track first app open
  Future<void> _trackFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final firstOpen = prefs.getString(_prefFirstOpenDate);

    if (firstOpen == null) {
      await prefs.setString(
          _prefFirstOpenDate, DateTime.now().toIso8601String());
      _logEvent('first_open', {});
    }
  }

  /// Log an analytics event
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    if (!_isInitialized) {
      debugPrint('[Analytics] Warning: Service not initialized');
    }

    _logEvent(name, parameters);
  }

  void _logEvent(String name, Map<String, dynamic> parameters) {
    if (_firebaseAvailable && _analytics != null) {
      // Convert parameters to supported types
      final safeParams = <String, Object>{};
      for (final entry in parameters.entries) {
        if (entry.value != null) {
          safeParams[entry.key] = entry.value;
        }
      }
      _analytics!.logEvent(name: name, parameters: safeParams);
    }

    // Always log to console for debugging
    if (kDebugMode) {
      final params = parameters.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      debugPrint('[Analytics] $name {$params}');
    }
  }

  /// Set user property
  Future<void> setUserProperty(String name, String value) async {
    if (_firebaseAvailable && _analytics != null) {
      await _analytics!.setUserProperty(name: name, value: value);
    }

    if (kDebugMode) {
      debugPrint('[Analytics] UserProperty: $name = $value');
    }
  }

  // ============================================
  // Game Events
  // ============================================

  /// Track game start
  Future<void> logGameStart({
    required String category,
    required int questionsCount,
  }) async {
    await logEvent('game_start', {
      'category': category,
      'questions_count': questionsCount,
    });

    // Update total games played
    final prefs = await SharedPreferences.getInstance();
    final totalGames = (prefs.getInt(_prefTotalGames) ?? 0) + 1;
    await prefs.setInt(_prefTotalGames, totalGames);
    await setUserProperty('total_games_played', totalGames.toString());
  }

  /// Track game complete (finished all questions)
  Future<void> logGameComplete({
    required String category,
    required int score,
    required int streak,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    await logEvent('game_complete', {
      'category': category,
      'score': score,
      'streak': streak,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'accuracy': (correctAnswers / totalQuestions * 100).round(),
    });

    // Update skill level based on accuracy
    final accuracy = correctAnswers / totalQuestions;
    String skillLevel = 'beginner';
    if (accuracy >= 0.9) {
      skillLevel = 'expert';
    } else if (accuracy >= 0.7) {
      skillLevel = 'intermediate';
    }
    await setUserProperty('skill_level', skillLevel);

    // Update favorite category
    await _updateFavoriteCategory(category);
  }

  /// Track game over (ran out of lives)
  Future<void> logGameOver({
    required String category,
    required int score,
    int? livesRemaining,
  }) async {
    await logEvent('game_over', {
      'category': category,
      'score': score,
      'lives_remaining': livesRemaining ?? 0,
    });
  }

  /// Track answer selection
  Future<void> logAnswerSelected({
    required bool correct,
    required int timeRemaining,
    bool usedLifeline = false,
  }) async {
    await logEvent('answer_selected', {
      'correct': correct,
      'time_remaining': timeRemaining,
      'used_lifeline': usedLifeline,
    });
  }

  // ============================================
  // Daily Challenge Events
  // ============================================

  /// Track daily challenge start
  Future<void> logDailyChallengeStart({
    required int streakDays,
  }) async {
    await logEvent('daily_challenge_start', {
      'streak_days': streakDays,
    });
  }

  /// Track daily challenge complete
  Future<void> logDailyChallengeComplete({
    required int score,
    required int streakDays,
    required int correctAnswers,
  }) async {
    await logEvent('daily_challenge_complete', {
      'score': score,
      'streak_days': streakDays,
      'correct_answers': correctAnswers,
    });
  }

  // ============================================
  // Ad Events
  // ============================================

  /// Track ad watched
  Future<void> logAdWatched({
    required String adType,
    required String placement,
    required bool completed,
  }) async {
    await logEvent('ad_watched', {
      'ad_type': adType,
      'placement': placement,
      'completed': completed,
    });
  }

  // ============================================
  // Social Events
  // ============================================

  /// Track score shared
  Future<void> logScoreShared({
    required String platform,
    required int score,
  }) async {
    await logEvent('score_shared', {
      'platform': platform,
      'score': score,
    });
  }

  // ============================================
  // App Events
  // ============================================

  /// Track app opened
  Future<void> logAppOpened({String? source, bool? fromNotification}) async {
    await logEvent('app_opened', {
      if (source != null) 'source': source,
      if (fromNotification != null) 'notification': fromNotification,
    });
  }

  // ============================================
  // User Properties
  // ============================================

  /// Update favorite category based on play count
  Future<void> _updateFavoriteCategory(String category) async {
    // For now, just set the last played category as favorite
    // In a real app, you'd track play counts per category
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefFavoriteCategory, category);
    await setUserProperty('favorite_category', category);
  }

  /// Calculate and set engagement tier
  Future<void> updateEngagementTier() async {
    final prefs = await SharedPreferences.getInstance();
    final totalGames = prefs.getInt(_prefTotalGames) ?? 0;
    final firstOpenStr = prefs.getString(_prefFirstOpenDate);

    String tier = 'casual';
    if (totalGames >= 50) {
      tier = 'power_user';
    } else if (totalGames >= 10) {
      tier = 'regular';
    }

    await setUserProperty('engagement_tier', tier);

    // Calculate days since install
    if (firstOpenStr != null) {
      final firstOpen = DateTime.parse(firstOpenStr);
      final daysSince = DateTime.now().difference(firstOpen).inDays;
      await setUserProperty('days_since_install', daysSince.toString());
    }
  }

  /// Get total games played
  Future<int> getTotalGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefTotalGames) ?? 0;
  }

  // ============================================
  // Crashlytics
  // ============================================

  /// Log non-fatal exception
  void recordError(dynamic exception, StackTrace? stack) {
    if (_firebaseAvailable) {
      FirebaseCrashlytics.instance.recordError(exception, stack);
    }

    if (kDebugMode) {
      debugPrint('[Analytics] Error recorded: $exception');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
  }

  /// Set custom key for debugging
  void setCustomKey(String key, dynamic value) {
    if (_firebaseAvailable) {
      FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
    }

    if (kDebugMode) {
      debugPrint('[Analytics] CustomKey: $key = $value');
    }
  }

  /// Log user identifier for debugging
  Future<void> setUserId(String? id) async {
    if (_firebaseAvailable) {
      _analytics?.setUserId(id: id);
      FirebaseCrashlytics.instance.setUserIdentifier(id ?? '');
    }

    if (kDebugMode) {
      debugPrint('[Analytics] UserId: $id');
    }
  }
}

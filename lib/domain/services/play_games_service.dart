import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/play_games_ids.dart';

/// Wrapper around the games_services plugin.
///
/// Features:
/// - Pending-sync queue: achievements & scores are queued when offline or
///   before sign-in completes, then flushed automatically on sign-in.
/// - Score deduplication: only submits when the score beats the last
///   submitted value (tracked in SharedPreferences).
/// - HMS guard: PlatformException from missing Play Services is caught and
///   logged clearly instead of as a generic error.
/// - All methods are no-ops on non-Android platforms.
class PlayGamesService {
  static const _keyPendingAchievements = 'gpgs_pending_achievements';
  static const _keyPendingScore        = 'gpgs_pending_score';
  static const _keyLastSubmittedScore  = 'gpgs_last_submitted_score';

  bool _signedIn = false;
  SharedPreferences? _prefs;
  Set<String> _pendingAchievements = {};
  int _pendingScore = 0;
  int _lastSubmittedScore = 0;

  bool get isSignedIn => _signedIn;

  // ── Initialize ────────────────────────────────────────────────────────────

  /// Must be called once from main.dart before sign-in.
  /// Loads the pending queue and runs the pre-release ID validator.
  Future<void> initialize() async {
    PlayGamesIds.validate();

    _prefs = await SharedPreferences.getInstance();
    final pending = _prefs!.getStringList(_keyPendingAchievements) ?? [];
    _pendingAchievements = Set<String>.from(pending);
    _pendingScore = _prefs!.getInt(_keyPendingScore) ?? 0;
    _lastSubmittedScore = _prefs!.getInt(_keyLastSubmittedScore) ?? 0;

    debugPrint('[PlayGames] Initialized — '
        'pending achievements: ${_pendingAchievements.length}, '
        'pending score: $_pendingScore, '
        'last submitted: $_lastSubmittedScore');
  }

  // ── Sign-in ──────────────────────────────────────────────────────────────

  /// Attempt silent sign-in. Call once at app startup.
  Future<void> signInSilently() async {
    if (!_isAndroid) return;
    await _attemptSignIn(silent: true);
  }

  /// Explicit sign-in (e.g. triggered from the Achievements screen button).
  Future<bool> signIn() async {
    if (!_isAndroid) return false;
    return _attemptSignIn(silent: false);
  }

  Future<bool> _attemptSignIn({required bool silent}) async {
    try {
      await GamesServices.signIn();
      _signedIn = true;
      debugPrint('[PlayGames] ${silent ? "Silent sign-in" : "Sign-in"} succeeded');
      await _flushPendingQueue();
      return true;
    } on PlatformException catch (e) {
      _signedIn = false;
      // Detect Huawei HMS / missing Google Play Services
      final msg = e.message ?? '';
      if (msg.contains('MISSING') ||
          msg.contains('DISABLED') ||
          msg.contains('HMS') ||
          msg.contains('SERVICE_INVALID') ||
          e.code == 'sign_in_failed') {
        debugPrint('[PlayGames] Google Play Services unavailable '
            '(HMS or non-GMS device): ${e.message}');
      } else {
        debugPrint('[PlayGames] Sign-in failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _signedIn = false;
      debugPrint('[PlayGames] Sign-in error: $e');
      return false;
    }
  }

  // ── Pending-sync queue ────────────────────────────────────────────────────

  Future<void> _flushPendingQueue() async {
    if (!_signedIn) return;

    // Flush queued achievement unlocks
    final toFlush = Set<String>.from(_pendingAchievements);
    for (final id in toFlush) {
      await _doUnlockAchievement(id);
    }
    // _doUnlockAchievement removes from set on success; persist final state
    await _prefs?.setStringList(
        _keyPendingAchievements, _pendingAchievements.toList());

    // Flush queued high score
    if (_pendingScore > 0) {
      await _doSubmitScore(_pendingScore);
      if (_pendingScore <= _lastSubmittedScore) {
        // Successfully submitted — clear pending
        _pendingScore = 0;
        await _prefs?.setInt(_keyPendingScore, 0);
      }
    }
  }

  // ── Achievements ─────────────────────────────────────────────────────────

  /// Unlock an achievement by its local ID (e.g. 'first_game').
  /// Queues the unlock if not yet signed in.
  Future<void> unlockAchievement(String localId) async {
    if (!_isAndroid) return;
    final gpgsId = PlayGamesIds.achievementIds[localId];
    if (gpgsId == null || gpgsId.startsWith('YOUR_')) return;

    if (!_signedIn) {
      _pendingAchievements.add(localId);
      await _prefs?.setStringList(
          _keyPendingAchievements, _pendingAchievements.toList());
      debugPrint('[PlayGames] Queued achievement for later: $localId');
      return;
    }

    await _doUnlockAchievement(localId);
    await _prefs?.setStringList(
        _keyPendingAchievements, _pendingAchievements.toList());
  }

  Future<void> _doUnlockAchievement(String localId) async {
    final gpgsId = PlayGamesIds.achievementIds[localId];
    if (gpgsId == null || gpgsId.startsWith('YOUR_')) return;
    try {
      await GamesServices.unlock(achievement: Achievement(androidID: gpgsId));
      _pendingAchievements.remove(localId); // success — remove from queue
      debugPrint('[PlayGames] Achievement unlocked: $localId');
    } catch (e) {
      debugPrint('[PlayGames] Unlock failed for $localId (will retry): $e');
      _pendingAchievements.add(localId); // ensure it stays queued for retry
    }
  }

  /// Increment a stepped achievement (e.g. games_10, games_50).
  Future<void> incrementAchievement(String localId, {int steps = 1}) async {
    if (!_isAndroid || !_signedIn) return;
    final gpgsId = PlayGamesIds.achievementIds[localId];
    if (gpgsId == null || gpgsId.startsWith('YOUR_')) return;
    try {
      await GamesServices.increment(
        achievement: Achievement(androidID: gpgsId, steps: steps),
      );
    } catch (e) {
      debugPrint('[PlayGames] Increment failed for $localId: $e');
    }
  }

  /// Show the native Google Play Games achievements overlay.
  Future<void> showAchievements() async {
    if (!_isAndroid || !_signedIn) return;
    try {
      await GamesServices.showAchievements();
    } catch (e) {
      debugPrint('[PlayGames] showAchievements failed: $e');
    }
  }

  // ── Leaderboard ──────────────────────────────────────────────────────────

  /// Submit score only if it beats the last submitted value (deduplication).
  /// Queues the score if not yet signed in.
  Future<void> submitScore(int score) async {
    if (!_isAndroid) return;
    if (PlayGamesIds.leaderboardAllTime.startsWith('YOUR_')) return;

    // Only process genuine new highs
    if (score <= _lastSubmittedScore) return;

    if (!_signedIn) {
      if (score > _pendingScore) {
        _pendingScore = score;
        await _prefs?.setInt(_keyPendingScore, score);
        debugPrint('[PlayGames] Queued high score for later: $score');
      }
      return;
    }

    await _doSubmitScore(score);
  }

  Future<void> _doSubmitScore(int score) async {
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: PlayGamesIds.leaderboardAllTime,
          value: score,
        ),
      );
      _lastSubmittedScore = score;
      await _prefs?.setInt(_keyLastSubmittedScore, score);
      debugPrint('[PlayGames] Score submitted: $score');
    } catch (e) {
      debugPrint('[PlayGames] submitScore failed (will retry on next session): $e');
      // Re-queue on failure
      if (score > _pendingScore) {
        _pendingScore = score;
        await _prefs?.setInt(_keyPendingScore, score);
      }
    }
  }

  /// Show the native Google Play Games leaderboard overlay.
  Future<void> showLeaderboard() async {
    if (!_isAndroid || !_signedIn) return;
    if (PlayGamesIds.leaderboardAllTime.startsWith('YOUR_')) return;
    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: PlayGamesIds.leaderboardAllTime,
      );
    } catch (e) {
      debugPrint('[PlayGames] showLeaderboard failed: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

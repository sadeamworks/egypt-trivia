import 'package:hive_flutter/hive_flutter.dart';
import '../models/score_entry.dart';

/// Repository for managing high scores with Hive
class ScoreRepository {
  static const String _boxName = 'high_scores';
  Box<ScoreEntry>? _box;

  /// Initialize the repository
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ScoreEntry>(_boxName);
    } else {
      _box = Hive.box<ScoreEntry>(_boxName);
    }
  }

  /// Save a score entry
  Future<void> saveScore(ScoreEntry entry) async {
    await _ensureBoxOpen();
    await _box!.add(entry);
  }

  /// Get all scores
  Future<List<ScoreEntry>> getAllScores() async {
    await _ensureBoxOpen();
    return _box!.values.toList();
  }

  /// Get high score for a specific category
  Future<ScoreEntry?> getHighScoreForCategory(String category) async {
    await _ensureBoxOpen();
    final scores = _box!.values.where((s) => s.category == category).toList();
    if (scores.isEmpty) return null;

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.first;
  }

  /// Get the overall highest score
  Future<int> getOverallHighScore() async {
    await _ensureBoxOpen();
    final scores = _box!.values.toList();
    if (scores.isEmpty) return 0;

    return scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
  }

  /// Get top scores (sorted by score)
  Future<List<ScoreEntry>> getTopScores({int limit = 10}) async {
    await _ensureBoxOpen();
    final scores = _box!.values.toList();
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(limit).toList();
  }

  /// Clear all scores
  Future<void> clearAll() async {
    await _ensureBoxOpen();
    await _box!.clear();
  }

  Future<void> _ensureBoxOpen() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
}

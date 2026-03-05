import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/achievement.dart';
import '../../domain/services/play_games_service.dart';
import 'play_games_provider.dart';

/// Achievement state
class AchievementState {
  final AchievementProgress progress;
  final bool isLoading;

  const AchievementState({
    this.progress = const AchievementProgress(),
    this.isLoading = true,
  });

  int get totalUnlocked => progress.unlockedIds.length;
  int get totalAchievements => Achievements.all.length;

  List<UnlockedAchievement> get unlockedAchievements {
    // This would need to be stored separately with timestamps
    // For now, return empty list
    return [];
  }

  AchievementState copyWith({
    AchievementProgress? progress,
    bool? isLoading,
  }) {
    return AchievementState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  static const String _key = 'achievement_progress';
  SharedPreferences? _prefs;
  final PlayGamesService? _playGames;

  AchievementNotifier({PlayGamesService? playGames})
      : _playGames = playGames,
        super(const AchievementState()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString(_key);

    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final progress = AchievementProgress.fromJson(json);
        state = AchievementState(progress: progress, isLoading: false);
        return;
      } catch (_) {}
    }

    state = state.copyWith(isLoading: false);
  }

  Future<void> _saveProgress() async {
    final jsonStr = jsonEncode(state.progress.toJson());
    await _prefs?.setString(_key, jsonStr);
  }

  /// Update progress for an achievement
  Future<void> updateProgress(AchievementType type, int value) async {
    final definition = Achievements.all.firstWhere(
      (a) => a.type == type,
      orElse: () => Achievements.all.first,
    );

    final currentProgress = state.progress.getProgress(definition.id);
    final maxProgress = definition.targetValue;

    // Don't update if already unlocked or progress didn't change
    if (state.progress.isUnlocked(definition.id) || value <= currentProgress) {
      return;
    }

    final newProgress = value.clamp(0, maxProgress);
    final newProgressMap = Map<String, int>.from(state.progress.progress);
    newProgressMap[definition.id] = newProgress;

    final newUnlockedIds = Set<String>.from(state.progress.unlockedIds);
    if (newProgress >= maxProgress) {
      newUnlockedIds.add(definition.id);
      // Sync to Google Play Games Services
      _playGames?.unlockAchievement(definition.id);
    }

    final newAchievementProgress = state.progress.copyWith(
      progress: newProgressMap,
      unlockedIds: newUnlockedIds,
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(progress: newAchievementProgress);
    await _saveProgress();
  }

  /// Increment progress for an achievement by 1
  Future<void> incrementProgress(AchievementType type) async {
    final definition = Achievements.all.firstWhere(
      (a) => a.type == type,
      orElse: () => Achievements.all.first,
    );
    final current = state.progress.getProgress(definition.id);
    await updateProgress(type, current + 1);
  }

  /// Check if achievement is unlocked
  bool isUnlocked(String achievementId) {
    return state.progress.isUnlocked(achievementId);
  }

  /// Get progress percentage for an achievement
  double getProgressPercent(String achievementId) {
    final definition = Achievements.getById(achievementId);
    if (definition == null) return 0;

    final progress = state.progress.getProgress(achievementId);
    return progress / definition.targetValue;
  }

  /// Get all achievements with their unlock status
  List<Map<String, dynamic>> getAllAchievements() {
    return Achievements.all.map((def) {
      return {
        'definition': def,
        'isUnlocked': state.progress.isUnlocked(def.id),
        'progress': state.progress.getProgress(def.id),
        'progressPercent': getProgressPercent(def.id),
      };
    }).toList();
  }
}

/// Provider for achievement state
final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  final playGames = ref.watch(playGamesServiceProvider);
  return AchievementNotifier(playGames: playGames);
});

/// Provider for unlocked achievement count
final unlockedAchievementsCountProvider = Provider<int>((ref) {
  final state = ref.watch(achievementProvider);
  return state.totalUnlocked;
});

/// Provider for achievement completion percentage
final achievementCompletionProvider = Provider<double>((ref) {
  final state = ref.watch(achievementProvider);
  if (state.totalAchievements == 0) return 0;
  return state.totalUnlocked / state.totalAchievements;
});

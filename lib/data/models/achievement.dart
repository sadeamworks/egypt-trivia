/// Achievement types
enum AchievementType {
  firstGame,
  perfectScore,
  streak7,
  streak30,
  points1000,
  points5000,
  categoryMaster,
  dailyChallenge7,
  dailyChallenge30,
  gamesPlayed10,
  gamesPlayed50,
}

/// Achievement definition
class AchievementDefinition {
  final AchievementType type;
  final String id;
  final String nameAr;
  final String descriptionAr;
  final String icon;
  final int targetValue;

  const AchievementDefinition({
    required this.type,
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.icon,
    this.targetValue = 1,
  });
}

/// All achievement definitions
class Achievements {
  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      type: AchievementType.firstGame,
      id: 'first_game',
      nameAr: 'البداية',
      descriptionAr: 'أكمل أول لعبة',
      icon: '🎮',
    ),
    AchievementDefinition(
      type: AchievementType.perfectScore,
      id: 'perfect_score',
      nameAr: 'علامة كاملة',
      descriptionAr: 'أجب على 10 أسئلة صحيحة متتالية',
      icon: '💯',
    ),
    AchievementDefinition(
      type: AchievementType.streak7,
      id: 'streak_7',
      nameAr: 'أسبوع متتالي',
      descriptionAr: 'حقق سلسلة 7 إجابات صحيحة',
      icon: '🔥',
      targetValue: 7,
    ),
    AchievementDefinition(
      type: AchievementType.streak30,
      id: 'streak_30',
      nameAr: 'شهر متتالي',
      descriptionAr: 'حقق سلسلة 30 إجابات صحيحة',
      icon: '⚡',
      targetValue: 30,
    ),
    AchievementDefinition(
      type: AchievementType.points1000,
      id: 'points_1000',
      nameAr: 'ألف نقطة',
      descriptionAr: 'اجمع 1000 نقطة',
      icon: '🎯',
      targetValue: 1000,
    ),
    AchievementDefinition(
      type: AchievementType.points5000,
      id: 'points_5000',
      nameAr: 'خمسة آلاف',
      descriptionAr: 'اجمع 5000 نقطة',
      icon: '🏆',
      targetValue: 5000,
    ),
    AchievementDefinition(
      type: AchievementType.dailyChallenge7,
      id: 'daily_7',
      nameAr: 'تحدي أسبوعي',
      descriptionAr: 'أكمل التحدي اليومي 7 أيام متتالية',
      icon: '📅',
      targetValue: 7,
    ),
    AchievementDefinition(
      type: AchievementType.dailyChallenge30,
      id: 'daily_30',
      nameAr: 'تحدي شهري',
      descriptionAr: 'أكمل التحدي اليومي 30 يوم متتالية',
      icon: '🗓️',
      targetValue: 30,
    ),
    AchievementDefinition(
      type: AchievementType.gamesPlayed10,
      id: 'games_10',
      nameAr: 'لاعب نشيط',
      descriptionAr: 'العب 10 جولات',
      icon: '⭐',
      targetValue: 10,
    ),
    AchievementDefinition(
      type: AchievementType.gamesPlayed50,
      id: 'games_50',
      nameAr: 'محترف',
      descriptionAr: 'العب 50 جولة',
      icon: '👑',
      targetValue: 50,
    ),
  ];

  static AchievementDefinition? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// User's unlocked achievement
class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;

  UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
    this.progress = 100,
  });

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'unlockedAt': unlockedAt.toIso8601String(),
        'progress': progress,
      };

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) {
    return UnlockedAchievement(
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      progress: json['progress'] as int? ?? 100,
    );
  }
}

/// Achievement progress tracking
class AchievementProgress {
  final Map<String, int> progress;
  final Set<String> unlockedIds;
  final DateTime? lastUpdated;

  const AchievementProgress({
    this.progress = const {},
    this.unlockedIds = const {},
    this.lastUpdated,
  });

  AchievementProgress copyWith({
    Map<String, int>? progress,
    Set<String>? unlockedIds,
    DateTime? lastUpdated,
  }) {
    return AchievementProgress(
      progress: progress ?? this.progress,
      unlockedIds: unlockedIds ?? this.unlockedIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  int getProgress(String achievementId) => progress[achievementId] ?? 0;

  bool isUnlocked(String achievementId) => unlockedIds.contains(achievementId);

  Map<String, dynamic> toJson() => {
        'progress': progress,
        'unlockedIds': unlockedIds.toList(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      progress: Map<String, int>.from(json['progress'] as Map? ?? {}),
      unlockedIds: Set<String>.from(json['unlockedIds'] as List? ?? []),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }
}

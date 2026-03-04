import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/achievement.dart';
import '../../providers/game_provider.dart';
import '../../providers/score_provider.dart';
import '../../providers/share_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/ad_provider.dart';
import '../../../routing/routes.dart';
import '../../widgets/common/egyptian_background.dart';

/// Score summary screen shown after completing a round
class ScoreScreen extends ConsumerStatefulWidget {
  final GameResult? result;

  const ScoreScreen({
    super.key,
    this.result,
  });

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  bool _scoreSaved = false;
  bool _achievementsUpdated = false;
  bool _adShown = false;
  List<String> _newAchievements = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateAchievements() async {
    if (_achievementsUpdated || widget.result == null) return;
    _achievementsUpdated = true;

    final achievementNotifier = ref.read(achievementProvider.notifier);
    final previousState = ref.read(achievementProvider);

    // First game completed
    await achievementNotifier.incrementProgress(AchievementType.firstGame);

    // Games played
    await achievementNotifier.incrementProgress(AchievementType.gamesPlayed10);
    await achievementNotifier.incrementProgress(AchievementType.gamesPlayed50);

    // Perfect score (10/10)
    if (widget.result!.correctAnswers == widget.result!.totalQuestions) {
      await achievementNotifier.updateProgress(AchievementType.perfectScore, 1);
    }

    // Streak achievements
    await achievementNotifier.updateProgress(
        AchievementType.streak7, widget.result!.bestStreak);
    await achievementNotifier.updateProgress(
        AchievementType.streak30, widget.result!.bestStreak);

    // Points achievements
    await achievementNotifier.updateProgress(
        AchievementType.points1000, widget.result!.score);
    await achievementNotifier.updateProgress(
        AchievementType.points5000, widget.result!.score);

    // Check for new achievements
    final newState = ref.read(achievementProvider);
    final newUnlocked = newState.progress.unlockedIds
        .difference(previousState.progress.unlockedIds);

    if (newUnlocked.isNotEmpty && mounted) {
      setState(() {
        _newAchievements = newUnlocked.toList();
      });
    }
  }

  /// Show interstitial ad if applicable (every 2 rounds)
  Future<void> _maybeShowInterstitialAd() async {
    if (_adShown) return;

    final adService = ref.read(adServiceProvider);
    // Ensure ad service is initialized before checking
    await adService.initialize();
    debugPrint('[Ads] Interstitial check: rounds=${adService.roundsCompleted}, shouldShow=${adService.shouldShowInterstitial}, adReady=${adService.isInterstitialAdReady}');
    if (adService.shouldShowInterstitial) {
      if (adService.isInterstitialAdReady) {
        _adShown = true;
        debugPrint('[Ads] Showing interstitial ad now');
        await adService.showInterstitialAd();
      } else {
        // Ad not ready yet, try to load and show it
        debugPrint('[Ads] Interstitial should show but ad not ready, loading now...');
        adService.loadInterstitialAd();
        // Wait a bit for ad to load
        await Future.delayed(const Duration(seconds: 2));
        debugPrint('[Ads] After load attempt, isReady: ${adService.isInterstitialAdReady}');
        if (adService.isInterstitialAdReady && !_adShown) {
          _adShown = true;
          debugPrint('[Ads] Showing interstitial ad after loading');
          await adService.showInterstitialAd();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Save score when screen loads
    if (!_scoreSaved && widget.result != null) {
      _scoreSaved = true;
      Future.microtask(() async {
        ref.read(scoreNotifierProvider.notifier).saveGameResult(widget.result!);
        // Increment rounds FIRST (before achievements) so interstitial check sees updated value
        final adService = ref.read(adServiceProvider);
        await adService.incrementRoundsCompleted();
        debugPrint('[Ads] Rounds completed: ${adService.roundsCompleted}, shouldShow: ${adService.shouldShowInterstitial}, adReady: ${adService.isInterstitialAdReady}');
        await _updateAchievements();
        await _maybeShowInterstitialAd();
      });
    }

    // If no result, show error
    if (widget.result == null) {
      return _buildErrorScreen(context);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildCelebrationHeader(context),
                  const SizedBox(height: 24),
                  _buildScoreDisplay(context),
                  const SizedBox(height: 24),
                  if (_newAchievements.isNotEmpty) ...[
                    _buildNewAchievements(context),
                    const SizedBox(height: 24),
                  ],
                  _buildStatsGrid(context),
                  const SizedBox(height: 24),
                  _buildShareButton(context),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, ref),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader(BuildContext context) {
    return ScaleTransition(
      scale: _scoreAnimation,
      child: Column(
        children: [
          Text(
            '🎉 أحسنت! 🎉',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'لقد أكملت الجولة!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context) {
    return ScaleTransition(
      scale: _scoreAnimation,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldDark.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '${widget.result!.score}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 56,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'نقطة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAchievements(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'إنجاز جديد!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _newAchievements.map((id) {
              final achievement = Achievements.getById(id);
              if (achievement == null) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.papyrus,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(achievement.icon,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      achievement.nameAr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.papyrus,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildStatRow(
            context,
            icon: '🔥',
            label: 'أعلى streak',
            value: '${widget.result!.bestStreak}',
          ),
          const Divider(height: 24, color: AppColors.gold),
          _buildStatRow(
            context,
            icon: '✅',
            label: 'إجابات صحيحة',
            value:
                '${widget.result!.correctAnswers}/${widget.result!.totalQuestions}',
          ),
          const Divider(height: 24, color: AppColors.gold),
          _buildStatRow(
            context,
            icon: '📊',
            label: 'النسبة المئوية',
            value: '${widget.result!.accuracyPercentage.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () async {
          final shareService = ref.read(shareServiceProvider);
          await shareService.shareScore(
            score: widget.result!.score,
            category: widget.result!.category,
            correctAnswers: widget.result!.correctAnswers,
            totalQuestions: widget.result!.totalQuestions,
            streak: widget.result!.bestStreak,
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.share),
        label: const Text('شارك نتيجتك'),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Play Again button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).resetGame();
              ref.read(gameProvider.notifier).startGame();
              context.pushReplacement(Routes.game);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'العب مجدداً',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Home button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).resetGame();
              // Refresh high score when returning home
              ref.invalidate(highScoreProvider);
              context.go(Routes.home);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الرئيسية',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.home, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

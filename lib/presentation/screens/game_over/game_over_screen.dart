import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/game_provider.dart';
import '../../providers/score_provider.dart';
import '../../providers/ad_provider.dart';
import '../../../routing/routes.dart';
import '../../widgets/common/egyptian_background.dart';

/// Game Over screen shown when player runs out of lives
class GameOverScreen extends ConsumerStatefulWidget {
  const GameOverScreen({super.key});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _adWatched = false;
  bool _adLoading = false;
  bool _roundTracked = false;
  bool _interstitialShown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final result = ref.read(gameProvider.notifier).getGameResult();
    final isAdReady = ref.watch(rewardedAdReadyProvider);

    // Save score even on game over
    ref.read(scoreNotifierProvider.notifier).saveGameResult(result);

    // Track round for interstitial ads (game over counts as a round too)
    if (!_roundTracked) {
      _roundTracked = true;
      Future.microtask(() async {
        final adService = ref.read(adServiceProvider);
        await adService.incrementRoundsCompleted();
        debugPrint('[Ads] Game Over: rounds=${adService.roundsCompleted}, shouldShow=${adService.shouldShowInterstitial}, adReady=${adService.isInterstitialAdReady}');
        await _maybeShowInterstitialAd();
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: EgyptianBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildGameOverHeader(context),
                    const SizedBox(height: 32),
                    _buildScoreDisplay(context, gameState.score),
                    const SizedBox(height: 32),
                    _buildStatsCard(context, result),
                    const SizedBox(height: 32),
                    if (!_adWatched) _buildAdCard(context, isAdReady),
                    if (!_adWatched) const SizedBox(height: 16),
                    if (_adWatched) _buildContinueButton(context),
                    if (_adWatched) const SizedBox(height: 16),
                    _buildHomeButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverHeader(BuildContext context) {
    return Column(
      children: [
        const Text(
          '😢',
          style: TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 16),
        Text(
          'انتهت اللعبة',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'حاول مرة أخرى!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(BuildContext context, int score) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.9),
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
            '$score',
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
    );
  }

  Widget _buildStatsCard(BuildContext context, result) {
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
            value: '${result.bestStreak}',
          ),
          const Divider(height: 24, color: AppColors.gold),
          _buildStatRow(
            context,
            icon: '✅',
            label: 'إجابات صحيحة',
            value: '${result.correctAnswers}',
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

  Widget _buildAdCard(BuildContext context, bool isAdReady) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.8),
            AppColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎬',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'شاهد إعلان للحصول',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'على حياة إضافية',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _adLoading
                ? null
                : () => _showRewardedAd(context),
            icon: _adLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  )
                : const Icon(Icons.play_arrow, color: AppColors.accent),
            label: Text(
              _adLoading
                  ? 'جاري التحميل...'
                  : (isAdReady ? 'شاهد الآن' : 'تحميل الإعلان...'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRewardedAd(BuildContext context) async {
    setState(() => _adLoading = true);

    final adService = ref.read(adServiceProvider);

    final rewarded = await adService.showRewardedAd(
      onRewarded: () {
        setState(() {
          _adWatched = true;
          _adLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🎉 حصلت على حياة إضافية!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      onFailed: () {
        setState(() => _adLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'لم يتم تحميل الإعلان. حاول مرة أخرى.',
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );

    if (!rewarded) {
      setState(() => _adLoading = false);
    }
  }

  /// Show interstitial ad if applicable (every 2 rounds)
  Future<void> _maybeShowInterstitialAd() async {
    if (_interstitialShown) return;

    final adService = ref.read(adServiceProvider);
    // Ensure ad service is initialized before checking
    await adService.initialize();

    debugPrint('[Ads] Game Over - Interstitial check: rounds=${adService.roundsCompleted}, shouldShow=${adService.shouldShowInterstitial}, adReady=${adService.isInterstitialAdReady}');

    if (adService.shouldShowInterstitial) {
      if (adService.isInterstitialAdReady) {
        _interstitialShown = true;
        debugPrint('[Ads] Showing interstitial ad on game over');
        await adService.showInterstitialAd(placement: 'game_over');
      } else {
        // Ad not ready yet, try to load and show it
        debugPrint('[Ads] Interstitial should show but ad not ready, loading now...');
        adService.loadInterstitialAd();
        // Wait a bit for ad to load
        await Future.delayed(const Duration(seconds: 2));
        debugPrint('[Ads] After load attempt, isReady: ${adService.isInterstitialAdReady}');
        if (adService.isInterstitialAdReady && !_interstitialShown) {
          _interstitialShown = true;
          debugPrint('[Ads] Showing interstitial ad after loading on game over');
          await adService.showInterstitialAd(placement: 'game_over');
        }
      }
    }
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Resume game with extra life
          ref.read(gameProvider.notifier).resetGame();
          ref.read(gameProvider.notifier).startGame();
          context.pushReplacement(Routes.game);
        },
        icon: const Icon(Icons.play_arrow, size: 24),
        label: Text(
          'متابعة اللعب',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(gameProvider.notifier).resetGame();
          ref.invalidate(highScoreProvider);
          context.go(Routes.home);
        },
        icon: const Icon(Icons.home, size: 24),
        label: Text(
          'الرئيسية',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

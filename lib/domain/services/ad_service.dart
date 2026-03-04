import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// Ad unit IDs for different platforms and environments
class AdUnitIds {
  // Test ad unit IDs provided by Google for development
  static const String testRewardedAdId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';

  // Production ad unit IDs
  static const String prodRewardedAdIdAndroid = 'ca-app-pub-6800264470045423/2463828720';
  static const String prodRewardedAdIdIOS = 'ca-app-pub-6800264470045423/9959175362';
  static const String prodInterstitialAdIdAndroid = 'ca-app-pub-6800264470045423/7604950123';
  static const String prodInterstitialAdIdIOS = 'ca-app-pub-6800264470045423/3270953444';

  /// Get rewarded ad unit ID based on platform and build mode
  static String get rewardedAdId {
    if (kDebugMode) return testRewardedAdId;

    if (Platform.isAndroid) return prodRewardedAdIdAndroid;
    if (Platform.isIOS) return prodRewardedAdIdIOS;
    return testRewardedAdId;
  }

  /// Get interstitial ad unit ID based on platform and build mode
  static String get interstitialAdId {
    if (kDebugMode) return testInterstitialAdId;

    if (Platform.isAndroid) return prodInterstitialAdIdAndroid;
    if (Platform.isIOS) return prodInterstitialAdIdIOS;
    return testInterstitialAdId;
  }
}

/// Service for managing AdMob ads
class AdService {
  static const String _consentKey = 'ad_consent_given';
  static const String _roundsKey = 'rounds_completed';

  final AnalyticsService? _analyticsService;
  SharedPreferences? _prefs;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isInitialized = false;

  AdService({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService;

  /// Ensure SharedPreferences is available (lazy init)
  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Always init prefs first (fast)
    await _ensurePrefs();

    // AdMob only works on Android and iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[AdService] AdMob not supported on this platform, skipping initialization');
      _isInitialized = true;
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] MobileAds initialized');

      // Preload ads in the background
      loadRewardedAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] Failed to initialize AdMob: $e');
      _isInitialized = true;
    }
  }

  /// Check if user has given ad consent
  bool get hasConsent => _prefs?.getBool(_consentKey) ?? false;

  /// Set ad consent
  Future<void> setConsent(bool consent) async {
    await _prefs?.setBool(_consentKey, consent);
  }

  /// Get rounds completed count
  int get roundsCompleted => _prefs?.getInt(_roundsKey) ?? 0;

  /// Increment rounds completed count (lazily ensures prefs are available)
  Future<void> incrementRoundsCompleted() async {
    final prefs = await _ensurePrefs();
    final current = prefs.getInt(_roundsKey) ?? 0;
    await prefs.setInt(_roundsKey, current + 1);
    debugPrint('[AdService] Rounds incremented to ${current + 1}');
  }

  /// Reset rounds completed count
  Future<void> resetRoundsCompleted() async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_roundsKey, 0);
  }

  /// Check if interstitial ad should be shown (every 2 rounds)
  bool get shouldShowInterstitial => roundsCompleted > 0 && roundsCompleted % 2 == 0;

  /// Load rewarded ad
  void loadRewardedAd() {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // Dispose existing ad before loading new one
    _rewardedAd?.dispose();
    _rewardedAd = null;

    debugPrint('[AdService] Loading rewarded ad...');

    RewardedAd.load(
      adUnitId: AdUnitIds.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('[AdService] Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          debugPrint('[AdService] Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  /// Load interstitial ad
  void loadInterstitialAd() {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // Dispose existing ad before loading new one
    _interstitialAd?.dispose();
    _interstitialAd = null;

    debugPrint('[AdService] Loading interstitial ad...');

    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('[AdService] Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint('[AdService] Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Check if interstitial ad is ready
  bool get isInterstitialAdReady => _interstitialAd != null;

  /// Show rewarded ad and handle reward
  Future<bool> showRewardedAd({
    required Function() onRewarded,
    Function()? onFailed,
    String placement = 'game_over',
  }) async {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      onFailed?.call();
      return false;
    }

    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded ad not ready, loading...');
      loadRewardedAd();
      onFailed?.call();
      return false;
    }

    bool rewarded = false;

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(); // Preload next ad
          // Track ad completion (even if not fully watched)
          _analyticsService?.logAdWatched(
            adType: 'rewarded',
            placement: placement,
            completed: rewarded,
          );
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onFailed?.call();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
          onRewarded();
        },
      );

      return rewarded;
    } catch (e) {
      debugPrint('[AdService] Failed to show rewarded ad: $e');
      _rewardedAd = null;
      onFailed?.call();
      return false;
    }
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd({
    Function()? onDismissed,
    Function()? onFailed,
    String placement = 'between_rounds',
  }) async {
    // Skip on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[AdService] Interstitial ad not ready, loading...');
      loadInterstitialAd();
      onFailed?.call();
      return;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // Preload next ad
          // Track ad completion
          _analyticsService?.logAdWatched(
            adType: 'interstitial',
            placement: placement,
            completed: true,
          );
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onFailed?.call();
        },
      );

      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('[AdService] Failed to show interstitial ad: $e');
      _interstitialAd = null;
      onFailed?.call();
    }
  }

  /// Dispose ads
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}

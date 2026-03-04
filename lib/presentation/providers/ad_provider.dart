import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/ad_service.dart';
import 'analytics_provider.dart';

/// Provider for AdService
final adServiceProvider = Provider<AdService>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return AdService(analyticsService: analyticsService);
});

/// Provider for ad initialization
final adInitializedProvider = FutureProvider<bool>((ref) async {
  final adService = ref.watch(adServiceProvider);
  await adService.initialize();
  return true;
});

/// Provider for checking if rewarded ad is ready
final rewardedAdReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isRewardedAdReady;
});

/// Provider for checking if interstitial ad is ready
final interstitialAdReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.isInterstitialAdReady;
});

/// Provider for ad consent status
final adConsentProvider = StateProvider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.hasConsent;
});

/// Provider for rounds completed count
final roundsCompletedProvider = StateProvider<int>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.roundsCompleted;
});

/// Notifier for managing ad consent
class AdConsentNotifier extends StateNotifier<bool> {
  final AdService _adService;

  AdConsentNotifier(this._adService) : super(_adService.hasConsent);

  Future<void> setConsent(bool consent) async {
    await _adService.setConsent(consent);
    state = consent;
  }
}

final adConsentNotifierProvider =
    StateNotifierProvider<AdConsentNotifier, bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  return AdConsentNotifier(adService);
});

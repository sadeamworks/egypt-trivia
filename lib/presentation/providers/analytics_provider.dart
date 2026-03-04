import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/analytics_service.dart';

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provider for analytics initialization
final analyticsInitializedProvider = FutureProvider<bool>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  await analyticsService.initialize();
  return true;
});

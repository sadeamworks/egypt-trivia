import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/share_service.dart';
import 'analytics_provider.dart';

/// Provider for share service
final shareServiceProvider = Provider<ShareService>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return ShareService(analyticsService: analyticsService);
});

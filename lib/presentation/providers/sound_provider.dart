import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/sound_service.dart';

/// Provider for SoundService
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => service.dispose());
  return service;
});

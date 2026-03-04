import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'data/models/score_entry.g.dart';
import 'data/models/daily_state.g.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/ad_provider.dart';
import 'domain/services/notification_service.dart';
import 'presentation/providers/sound_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only await the essentials (Hive is needed for data access)
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('[Firebase] Initialized successfully');
  } catch (e) {
    debugPrint('[Firebase] Not configured, running without Firebase: $e');
  }

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScoreEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyStateAdapter());
    }
    debugPrint('[Hive] Initialized successfully');
  } catch (e) {
    debugPrint('[Hive] Failed to initialize: $e');
  }

  final container = ProviderContainer();

  // Launch the app IMMEDIATELY — don't block on service init
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EgyptTriviaApp(),
    ),
  );

  // Initialize services in the background AFTER first frame
  _initializeServices(container, firebaseReady);
}

/// Initialize non-essential services after app has launched
Future<void> _initializeServices(ProviderContainer container, bool firebaseReady) async {
  try {
    final analyticsService = container.read(analyticsServiceProvider);
    await analyticsService.initialize();
    debugPrint('[Analytics] Initialized');
  } catch (e) {
    debugPrint('[Analytics] Failed: $e');
  }

  try {
    final adService = container.read(adServiceProvider);
    await adService.initialize();
    debugPrint('[AdMob] Initialized');
  } catch (e) {
    debugPrint('[AdMob] Failed: $e');
  }

  try {
    final soundService = container.read(soundServiceProvider);
    await soundService.initialize();
    debugPrint('[Sound] Initialized');
  } catch (e) {
    debugPrint('[Sound] Failed: $e');
  }

  if (firebaseReady) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('[Notifications] Initialized');
    } catch (e) {
      debugPrint('[Notifications] Failed: $e');
    }
  }

  debugPrint('[App] All services ready');
}

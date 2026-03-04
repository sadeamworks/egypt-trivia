import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[Notifications] Background message: ${message.messageId}');
}

/// Service for managing push notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notification service
  Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
        '[Notifications] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('[Notifications] FCM Token: $token');

      // Subscribe to topic for broadcast notifications
      await _messaging.subscribeToTopic('all_users');
      await _messaging.subscribeToTopic('daily_reminder');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[Notifications] Foreground: ${message.notification?.title}');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint(
        '[Notifications] Opened from notification: ${message.data}');
  }
}

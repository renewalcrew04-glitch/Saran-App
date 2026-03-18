import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'local_notification_service.dart';

/// Firebase Cloud Messaging (FCM) push notification integration.
///
/// Your backend stores an AWS SNS endpoint ARN using the provided FCM token:
/// `POST /api/notifications/register-device` { fcmToken }
class PushNotificationService {
  static const _prefsKeyLastFcmToken = 'saran_last_fcm_token';

  static bool _firebaseInitialized = false;
  static bool _foregroundListening = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    await Firebase.initializeApp();
    _firebaseInitialized = true;
  }

  static Future<void> _registerFcmToken({bool force = false}) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastToken = prefs.getString(_prefsKeyLastFcmToken);
    if (!force && lastToken == fcmToken) return;

    try {
      await ApiClient.post(
        '/notifications/register-device',
        body: {'fcmToken': fcmToken},
      );
      await prefs.setString(_prefsKeyLastFcmToken, fcmToken);
      debugPrint('[PushNotificationService] registered fcmToken');
    } catch (e) {
      // Usually means "not logged in" or backend not reachable.
      debugPrint('[PushNotificationService] register failed: $e');
    }
  }

  static Future<void> _startForegroundHandlers() async {
    if (_foregroundListening) return;
    _foregroundListening = true;

    // Receive foreground notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = (message.notification?.title?.toString().isNotEmpty == true)
          ? message.notification!.title!
          : (message.data['title']?.toString().isNotEmpty == true
              ? message.data['title'].toString()
              : 'SARAN');

      final body = (message.notification?.body?.toString().isNotEmpty == true)
          ? message.notification!.body!
          : (message.data['body']?.toString().isNotEmpty == true
              ? message.data['body'].toString()
              : '');

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      try {
        await LocalNotificationService.showMessage(
          id: id,
          senderName: title,
          body: body,
        );
      } catch (e) {
        debugPrint('[PushNotificationService] local show failed: $e');
      }
    });

    // Token refresh: re-register with backend.
    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isEmpty) return;
      await _registerFcmToken(force: true);
    });
  }

  /// Initializes Firebase, asks for notification permissions, registers the
  /// device token with the backend, and starts foreground handlers.
  static Future<void> registerIfPossible() async {
    await _ensureFirebaseInitialized();

    // Local notification permission is the same user prompt for iOS notifications.
    await LocalNotificationService.requestPermission();

    await _startForegroundHandlers();
    await _registerFcmToken();
  }
}


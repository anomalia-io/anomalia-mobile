
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _fcmAvailable = false;
  bool _registered = false;
  String? _lastToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // FCM solo si la plataforma esta configurada (google-services.json en
    // Android, GoogleService-Info.plist en iOS). Sin esa config la app sigue
    // funcionando sin push; FCM se activa automaticamente al agregarla.
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _fcmAvailable = true;
    } catch (e) {
      debugPrint('Firebase no disponible (push inactivo): $e');
      _fcmAvailable = false;
    }

    if (_fcmAvailable) {
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCM permission: ${settings.authorizationStatus}');

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });
      } catch (e) {
        debugPrint('FCM setup error (push inactivo): $e');
        _fcmAvailable = false;
      }
    }

    // Notificaciones locales (independientes de FCM)
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _local.initialize(initSettings);
    } catch (e) {
      debugPrint('Local notifications init error: $e');
    }
  }

  Future<void> registerDeviceIfPossible() async {
    if (_registered) return;
    if (!_fcmAvailable) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (_lastToken == token) return;
      await ApiService.registerDevice(fcmToken: token);
      _lastToken = token;
      _registered = true;
      debugPrint('FCM token registered');
    } catch (e) {
      debugPrint('FCM register error: $e');
      // ignore - puede faltar config o red
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'anomalia_alerts',
        'Anomalía Alertas',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      final title = message.notification?.title ?? message.data['title'] ?? 'Alerta';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    } catch (e) {
      debugPrint('Local notification show error: $e');
    }
  }
}

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class MobileNotificationService implements NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageOpenedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _messageOpenedController.stream;

  @override
  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(initSettings);

    NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _messageController.add(message.data);
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'rizz_channel',
              'Rizz Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _messageOpenedController.add(message.data);
    });

    // Обработка нажатия на уведомление, когда приложение в фоне, но не убито
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _messageOpenedController.add(initialMessage.data);
    }
  }

  @override
  Future<String?> getToken() => _fcm.getToken();

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rizz_channel',
          'Rizz Notifications',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
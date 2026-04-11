import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class WebNotificationService implements NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageOpenedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialize() async {
    // Убедись, что VAPID ключ правильный
    final token = await _fcm.getToken(vapidKey: 'YOUR_VAPID_KEY');
    print('Web FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _messageController.add(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _messageOpenedController.add(message.data);
    });
  }

  @override
  Future<String?> getToken() => _fcm.getToken(vapidKey: 'YOUR_VAPID_KEY');

  @override
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _messageOpenedController.stream;

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // На вебе уведомления приходят через Service Worker
  }
}
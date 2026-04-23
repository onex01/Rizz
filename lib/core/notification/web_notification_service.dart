import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class WebNotificationService implements NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageOpenedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialize() async {
    // Настраиваем слушатели сообщений (без запроса разрешения)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _messageController.add(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _messageOpenedController.add(message.data);
    });

    // Токен не получаем здесь — будем запрашивать явно
    print('Web FCM listeners initialized');
  }

  /// Метод для вызова строго по клику пользователя (кнопка «Включить уведомления»)
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken(
        vapidKey: 'BHfflPk3dkc5jRoLpgjVgZv6j1_hGsMjR3sJkBoaF0P32kNE0k5dLFhWqpMGkiXMCKb7v_gZuFHy1s_U9kg4ps8',
      );
      print('Web FCM Token: $token');
      return true;
    }
    return false;
  }

  @override
  Future<String?> getToken() async {
    // При необходимости можно получить токен, но только после разрешения
    return _fcm.getToken(
      vapidKey: 'BHfflPk3dkc5jRoLpgjVgZv6j1_hGsMjR3sJkBoaF0P32kNE0k5dLFhWqpMGkiXMCKb7v_gZuFHy1s_U9kg4ps8',
    );
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _messageOpenedController.stream;

  @override
  Future<void> showLocalNotification({required String title, required String body, String? payload}) async {}

  @override
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String content,
    required String messageType,
    String? senderPhotoUrl,
  }) async {}

  @override
  Future<bool> isPermissionGranted() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
import 'dart:async';

abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Stream<Map<String, dynamic>> get onMessage;
  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  });

  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String content,
    required String messageType,
    String? senderPhotoUrl,
  });
}
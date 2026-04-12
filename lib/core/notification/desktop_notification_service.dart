import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class DesktopNotificationService implements NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription? _chatSubscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageOpenedController = StreamController<Map<String, dynamic>>.broadcast();

  DesktopNotificationService(this._firestore, this._auth);

  @override
  Future<void> initialize() async {
    await localNotifier.setup(
      appName: 'Rizz',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  @override
  Future<String?> getToken() async => null;

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
    final notification = LocalNotification(
      title: title,
      body: body,
    );
    await localNotifier.notify(notification);
  }

  @override
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String content,
    required String messageType,
    String? senderPhotoUrl,
  }) async {
    String body;
    switch (messageType) {
      case 'image_hex':
      case 'image':
        body = '📷 Фотография';
        break;
      case 'file_hex':
      case 'file':
        body = '📎 Файл';
        break;
      case 'voice':
        body = '🎤 Голосовое сообщение';
        break;
      case 'video_circle':
      case 'video':
        body = '🎥 Видео';
        break;
      default:
        body = content.length > 100 ? '${content.substring(0, 100)}…' : content;
    }
    final notification = LocalNotification(
      title: senderName,
      body: body,
    );
    await localNotifier.notify(notification);
  }

  void startListeningForMessages() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          final lastMessageTime = data?['lastMessageTime'] as Timestamp?;
          final lastMessage = data?['lastMessage'] as String?;
          final lastMessageType = data?['lastMessageType'] as String? ?? 'text';
          if (lastMessage != null && lastMessageTime != null) {
            final lastSeen = await _getLastSeenTime(change.doc.id);
            if (lastMessageTime.toDate().isAfter(lastSeen)) {
              await showMessageNotification(
                chatId: change.doc.id,
                senderName: 'Новое сообщение',
                content: lastMessage,
                messageType: lastMessageType,
              );
              _messageController.add({
                'chatId': change.doc.id,
                'message': lastMessage,
              });
            }
          }
        }
      }
    });
  }

  Future<DateTime> _getLastSeenTime(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenStr = prefs.getString('last_seen_$chatId');
    if (lastSeenStr != null) return DateTime.parse(lastSeenStr);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void dispose() {
    _chatSubscription?.cancel();
    _messageController.close();
    _messageOpenedController.close();
  }
}
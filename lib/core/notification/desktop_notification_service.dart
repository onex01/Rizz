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
          if (lastMessage != null && lastMessageTime != null) {
            final lastSeen = await _getLastSeenTime(change.doc.id);
            if (lastMessageTime.toDate().isAfter(lastSeen)) {
              await showLocalNotification(
                title: 'Новое сообщение',
                body: lastMessage,
                payload: change.doc.id,
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
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/notification/notification_service.dart';

class MessageListenerService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;
  StreamSubscription<QuerySnapshot>? _subscription;
  DateTime _lastResumed = DateTime.now();
  static bool _isAppInBackground = false;

  MessageListenerService(this._firestore, this._auth, this._notificationService);

  void startListening() {
    final user = _auth.currentUser;
    if (user == null) return;

    _subscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!_isAppInBackground) return;

      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        final lastMessageSenderId = data?['lastMessageSenderId'];
        final isMuted = data?['mutedBy']?.contains(user.uid) ?? false;

      if (lastMessageSenderId == user.uid || isMuted) continue;
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          final lastMessageTime = data?['lastMessageTime'] as Timestamp?;
          final lastMessage = data?['lastMessage'] as String?;
          final lastMessageType = data?['lastMessageType'] as String? ?? 'text';
          final participants = List<String>.from(data?['participants'] ?? []);
          final otherUserId = participants.firstWhere((id) => id != user.uid);

          if (lastMessageTime != null && lastMessageTime.toDate().isAfter(_lastResumed)) {
            final senderDoc = await _firestore.collection('users').doc(otherUserId).get();
            final senderName = senderDoc.data()?['nickname'] ?? 'Пользователь';

            await _notificationService.showMessageNotification(
              chatId: change.doc.id,
              senderName: senderName,
              content: lastMessage ?? '',
              messageType: lastMessageType,
            );
          }

          // if (lastMessageTime.toDate().isAfter(_lastResumed) && otherUserId != user.uid) {
          // // отправляем уведомление только если сообщение не от текущего пользователя 
          // }
        }
      }
    });
  }
  
  void setAppInBackground(bool inBackground) {
    _isAppInBackground = inBackground;
    if (!inBackground) _lastResumed = DateTime.now();
    if (kDebugMode) {
      print('App in background: $_isAppInBackground');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
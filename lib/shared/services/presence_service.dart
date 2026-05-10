import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../core/logger/app_logger.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppLogger _logger = GetIt.I<AppLogger>();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<DocumentSnapshot> getUserStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  void initPresence() {
    final uid = currentUserId;
    if (uid == null) return;
    _setOnline(true);
  }

  void goOffline() {
    _setOnline(false);
  }

  void goOnline() {
    _setOnline(true);
  }

  void _setOnline(bool isOnline) {
    final uid = currentUserId;
    if (uid == null) return;

    final data = <String, dynamic>{
      'isOnline': isOnline,
      if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
    };
    _firestore.collection('users').doc(uid).update(data).catchError((e) {
      _logger.error('Failed to update presence: $e');
    });
  }

  // === Методы для работы с чатом ===
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers': isTyping ? FieldValue.arrayUnion([user.uid]) : FieldValue.arrayRemove([user.uid])
    });
  }

  Future<void> joinChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chats').doc(chatId).update({
      'onlineUsers': FieldValue.arrayUnion([user.uid]),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chats').doc(chatId).update({
      'onlineUsers': FieldValue.arrayRemove([user.uid]),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
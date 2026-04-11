import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger/app_logger.dart';

abstract class FirestoreService {
  Future<DocumentSnapshot> getUser(String uid);
  Future<void> updateUser(String uid, Map<String, dynamic> data);
  Stream<QuerySnapshot> getChats(String userId);
  Future<DocumentReference> createChat(Map<String, dynamic> data);
  Future<void> updateChat(String chatId, Map<String, dynamic> data);
  Future<void> addMessage(String chatId, Map<String, dynamic> messageData);
}

class FirestoreServiceImpl implements FirestoreService {
  final FirebaseFirestore _firestore;
  final AppLogger _logger;

  FirestoreServiceImpl(this._firestore, this._logger);

  @override
  Future<DocumentSnapshot> getUser(String uid) => _firestore.collection('users').doc(uid).get();

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _firestore.collection('users').doc(uid).update(data);

  @override
  Stream<QuerySnapshot> getChats(String userId) => _firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .orderBy('lastMessageTime', descending: true)
      .snapshots();

  @override
  Future<DocumentReference> createChat(Map<String, dynamic> data) =>
      _firestore.collection('chats').add(data);

  @override
  Future<void> updateChat(String chatId, Map<String, dynamic> data) =>
      _firestore.collection('chats').doc(chatId).update(data);

  @override
  Future<void> addMessage(String chatId, Map<String, dynamic> messageData) =>
      _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);
}
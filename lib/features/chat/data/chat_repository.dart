import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logger/app_logger.dart';
import '../domain/message.dart';

abstract class ChatRepository {
  Future<void> sendMessage(String chatId, Message message);
  Stream<QuerySnapshot> getMessages(String chatId);
  Stream<QuerySnapshot> getChats(String userId);
  Future<void> updateLastMessage(String chatId, String preview, String type, {String? senderId});
  Future<void> insertLocalMessage(String chatId, Map<String, dynamic> data, String docId);
  Future<void> updateMessage(String chatId, String messageId, Map<String, dynamic> data);
  Future<void> deleteAllMessages(String chatId);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  final AppLogger _logger;

  ChatRepositoryImpl(this._firestore, this._logger);

  @override
  Future<void> sendMessage(String chatId, Message message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());
      await updateLastMessage(
        chatId,
        message.text.isNotEmpty ? message.text : 'Медиа',
        message.type,
      );
    } catch (e, stack) {
      _logger.error('Failed to send message', error: e, stack: stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteAllMessages(String chatId) async {
    final messagesRef = _firestore.collection('chats').doc(chatId).collection('messages');
    final messagesSnapshot = await messagesRef.get();
    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  @override
  Future<void> updateLastMessage(String chatId, String message, String type, {String? senderId}) async {
    final updateData = <String, dynamic>{
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': type,
      if (senderId != null) 'lastMessageSenderId': senderId,
    };
    await _firestore.collection('chats').doc(chatId).update(updateData);
  }

  Future<void> insertLocalMessage(String chatId, Map<String, dynamic> data, String docId) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(docId).set(data);
  }

  Future<void> updateMessage(String chatId, String messageId, Map<String, dynamic> data) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update(data);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logger/app_logger.dart';
import '../domain/message.dart';

abstract class ChatRepository {
  Future<void> sendMessage(String chatId, Message message);
  Stream<QuerySnapshot> getMessages(String chatId);
  Stream<QuerySnapshot> getChats(String userId);
  Future<void> updateLastMessage(String chatId, String preview, String type);
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
  Future<void> updateLastMessage(String chatId, String preview, String type) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': preview,
      'lastMessageType': type,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
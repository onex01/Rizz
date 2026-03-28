import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class MessageService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;

  /// Отправка текстового сообщения (оставил для совместимости со старым кодом)
  static Future<void> sendTextMessage({
    required String chatId,
    required String text,
    String? replyToMessageId,
    String? repliedMessageText,
  }) async {
    final currentUser = _auth.currentUser!;
    final messageData = {
      'senderId': currentUser.uid,
      'type': 'text',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToMessageId,
      'repliedMessageText': repliedMessageText,
      'read': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await _updateLastMessage(chatId, text);
  }

  /// Отправка изображения
  static Future<void> sendImageMessage({
    required String chatId,
    required XFile imageFile,
    String? replyToMessageId,
    String? repliedMessageText,
  }) async {
    try {
      final currentUser = _auth.currentUser!;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';

      // Путь в Firebase Storage (бесплатно в пределах лимитов)
      final storageRef = _storage.ref().child('chats/$chatId/images/$fileName');

      // Загрузка файла
      final uploadTask = await storageRef.putFile(File(imageFile.path));
      final String imageUrl = await uploadTask.ref.getDownloadURL();

      final messageData = {
        'senderId': currentUser.uid,
        'type': 'image',
        'imageUrl': imageUrl,
        'text': '', // можно добавить подпись позже
        'timestamp': FieldValue.serverTimestamp(),
        'replyToMessageId': replyToMessageId,
        'repliedMessageText': repliedMessageText,
        'read': false,
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      await _updateLastMessage(chatId, '📷 Фото');
    } catch (e) {
      print('Ошибка отправки изображения: $e');
      rethrow;
    }
  }

  /// Удобный метод: выбор фото из галереи + отправка
  static Future<void> pickAndSendImage({
    required String chatId,
    String? replyToMessageId,
    String? repliedMessageText,
  }) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    await sendImageMessage(
      chatId: chatId,
      imageFile: pickedFile,
      replyToMessageId: replyToMessageId,
      repliedMessageText: repliedMessageText,
    );
  }

  static Future<void> _updateLastMessage(String chatId, String lastMessageText) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
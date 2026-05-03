import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../../../core/logger/app_logger.dart';
import '../../../shared/services/media_api_service.dart';
import '../data/chat_repository.dart';

class ChatUploadHelper {
  final String chatId;
  final String currentUserId;
  final ChatRepository chatRepository;
  final AppLogger logger;
  final void Function(String) onToast;
  final VoidCallback onClearReply;
  final VoidCallback onScrollToBottom;

  ChatUploadHelper({
    required this.chatId,
    required this.currentUserId,
    required this.chatRepository,
    required this.logger,
    required this.onToast,
    required this.onClearReply,
    required this.onScrollToBottom,
  });

  /// Универсальный метод отправки медиа
  Future<void> uploadAndSendMessage(File file, String caption, String typeKey) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;

    // Определяем категорию для сервера
    String category;
    switch (typeKey) {
      case 'image':
        category = 'image';
        break;
      case 'video':
        category = 'video';
        break;
      case 'audio':
        category = 'audio';
        break;
      case 'voice':
        category = 'voice';
        break;
      case 'file':
      default:
        category = 'file';
    }

    // Вставляем сообщение-заглушку
    await chatRepository.insertLocalMessage(chatId, {
      'senderId': currentUserId,
      'text': caption.isNotEmpty ? caption : '',
      'timestamp': Timestamp.now(),
      'type': '${typeKey}_uploading',
      'mediaData': {
        'localPath': file.path,
        'fileName': fileName,
        'fileSize': fileSize,
        'previewText': caption.isNotEmpty ? caption : _defaultPreview(typeKey),
      },
    }, tempId);

    onClearReply();

    try {
      final mediaUrl = await GetIt.I<MediaApiService>().uploadFile(
        file,
        maxWidth: typeKey == 'image' ? 1280 : null,
        quality: typeKey == 'image' ? 85 : null,
        category: category,
      );
      if (mediaUrl == null) {
        await chatRepository.updateMessage(chatId, tempId, {'isUploadFailed': true});
        onToast('Не удалось загрузить файл');
        return;
      }
      await chatRepository.updateMessage(chatId, tempId, {
        'type': typeKey,
        'mediaData': {
          'mediaUrl': mediaUrl,
          'fileName': fileName,
          'fileSize': fileSize,
        },
        'text': caption.isNotEmpty ? caption : '',
      });
      await chatRepository.updateLastMessage(chatId, caption.isNotEmpty ? caption : fileName, typeKey, senderId: currentUserId);
      onScrollToBottom();
    } catch (e) {
      logger.error('Upload failed', error: e);
      await chatRepository.updateMessage(chatId, tempId, {'isUploadFailed': true});
      onToast('Ошибка отправки');
    }
  }

  /// Отдельный метод для аудио с метаданными
  Future<void> uploadAudio(File file, String title, String artist) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final previewText = '🎵 $title - $artist';

    await chatRepository.insertLocalMessage(chatId, {
      'senderId': currentUserId,
      'text': previewText,
      'timestamp': Timestamp.now(),
      'type': 'audio_uploading',
      'mediaData': {
        'localPath': file.path,
        'fileName': fileName,
        'fileSize': fileSize,
        'title': title,
        'artist': artist,
        'previewText': previewText,
      },
    }, tempId);

    onClearReply();

    try {
      final mediaUrl = await GetIt.I<MediaApiService>().uploadFile(file, category: 'audio');
      if (mediaUrl == null) {
        await chatRepository.updateMessage(chatId, tempId, {'isUploadFailed': true});
        onToast('Не удалось загрузить аудио');
        return;
      }
      await chatRepository.updateMessage(chatId, tempId, {
        'type': 'audio',
        'mediaData': {
          'mediaUrl': mediaUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          'title': title,
          'artist': artist,
        },
        'text': previewText,
      });
      await chatRepository.updateLastMessage(chatId, previewText, 'audio', senderId: currentUserId);
      onScrollToBottom();
    } catch (e) {
      logger.error('Upload audio failed', error: e);
      await chatRepository.updateMessage(chatId, tempId, {'isUploadFailed': true});
      onToast('Ошибка отправки аудио');
    }
  }

  String _defaultPreview(String typeKey) {
    switch (typeKey) {
      case 'image': return '📷 Фото';
      case 'video': return '🎥 Видео';
      case 'audio': return '🎵 Аудио';
      case 'file': return '📎 Файл';
      default: return 'Медиа';
    }
  }
}
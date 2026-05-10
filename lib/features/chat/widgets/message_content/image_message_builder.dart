import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../light_widgets/lightweight_image.dart';
import '../chat_common_widgets.dart';

class ImageMessageBuilder {
  static Widget build({
    required BuildContext context,
    required Map<String, dynamic> msgData,
    required bool isMe,
    required String time,
    required double fontSize,
    required Function(BuildContext, File, {String? url}) onShowFullScreenImage,
    required String messageId,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final localPath = mediaData?['localPath'] as String?;
    final caption = msgData['text'] as String? ?? '';
    final isRead = msgData['isRead'] == true;

    // Для своих сообщений с локальным файлом (только не Web)
    if (!kIsWeb && isMe && localPath != null && File(localPath).existsSync()) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => onShowFullScreenImage(context, File(localPath)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: ResizeImage(FileImage(File(localPath)), width: 200),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize - 5,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (isRead)
                            const Icon(Icons.done_all, size: 14, color: Colors.white)
                          else
                            const Icon(Icons.done, size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Обычный URL
    if (mediaUrl != null) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: LightweightImageWidget(
          url: mediaUrl,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
          isRead: isRead,
          onTap: (ctx, url) {
            onShowFullScreenImage(ctx, File(''), url: url);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
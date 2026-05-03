import 'dart:io';
import 'package:flutter/material.dart';
import '../light_widgets/lightweight_video.dart';
import '../chat_common_widgets.dart';

class VideoMessageBuilder {
  static Widget build({
    required BuildContext context,
    required Map<String, dynamic> msgData,
    required bool isMe,
    required String time,
    required double fontSize,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final localPath = mediaData?['localPath'] as String?;
    final caption = msgData['text'] as String? ?? '';

    // Локальный файл для своих сообщений
    if (isMe && localPath != null && File(localPath).existsSync()) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () async {
              // ... открыть локальный плеер
            },
            child: Container(
              width: 200,
              height: 150,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize - 5,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Новый URL
    if (mediaUrl != null) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: LightweightVideoWidget(
          url: mediaUrl,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
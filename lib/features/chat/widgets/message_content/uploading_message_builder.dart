import 'dart:io';
import 'package:flutter/material.dart';

class UploadingMessageBuilder {
  static Widget build({
    required Map<String, dynamic> msgData,
    required bool isMe,
    required Color accentColor,
    required double screenWidth,
    required String messageType,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final localPath = mediaData?['localPath'] as String?;
    final fileName = mediaData?['fileName'] ?? '...';
    final previewText = msgData['text'] ?? mediaData?['previewText'] ?? 'Отправка...';
    final isFailed = msgData['isUploadFailed'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? (isFailed ? Colors.red.withValues(alpha: 0.3) : accentColor.withValues(alpha: 0.5))
              : (isFailed ? Colors.red.shade100 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (localPath != null && File(localPath).existsSync()) ...[
              if (messageType.startsWith('image'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(localPath), width: 100, height: 100, fit: BoxFit.cover),
                )
              else if (messageType.startsWith('video'))
                const Icon(Icons.videocam, size: 40)
              else if (messageType.startsWith('audio'))
                const Icon(Icons.music_note, size: 40)
              else
                const Icon(Icons.insert_drive_file, size: 40),
              const SizedBox(height: 8),
            ],
            Text(
              previewText,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: isFailed ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 4),
            if (!isFailed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(fileName, style: const TextStyle(fontSize: 12)),
                ],
              )
            else
              Text(
                'Ошибка отправки',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../chat_common_widgets.dart';

class FileMessageBuilder {
  static Widget build({
    required Map<String, dynamic> msgData,
    required bool isMe,
    required bool isLight,
    required Color accentColor,
    required double fontSize,
    required String time,
    required double screenWidth,
    required Function(Map<String, dynamic>) onDownloadFile,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final fileName = mediaData?['fileName'] as String? ?? 'Файл';
    final fileSize = mediaData?['fileSize'] as int?;
    final caption = msgData['text'] as String? ?? '';
    final isRead = msgData['isRead'] == true;
    final bubbleColor = isMe ? accentColor : (isLight ? Colors.grey[200]! : Colors.grey[800]!);

    Widget fileWidget;
    if (mediaUrl != null) {
      fileWidget = Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(getFileIcon(fileName.split('.').last), color: isMe ? Colors.white : accentColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fileName, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: fontSize)),
                      if (fileSize != null) Text(formatFileSize(fileSize), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade600, fontSize: fontSize - 4)),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.download, color: isMe ? Colors.white : accentColor),
                    onPressed: () => onDownloadFile({'mediaUrl': mediaUrl, 'fileName': fileName}),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: fontSize - 5)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isRead) const Icon(Icons.done_all, size: 14, color: Colors.white70) else const Icon(Icons.done, size: 14, color: Colors.white70),
                ],
              ]),
            ],
          ),
        ),
      );
    } else {
      // Старый HEX
      fileWidget = Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(getFileIcon(msgData['fileExtension']), color: isMe ? Colors.white : accentColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(msgData['fileName'] ?? 'Файл', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: fontSize)),
                      Text(formatFileSize(msgData['fileSize'] ?? 0), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade600, fontSize: fontSize - 4)),
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.download, color: isMe ? Colors.white : accentColor),
                    onPressed: () => onDownloadFile(msgData),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: fontSize - 5)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isRead) const Icon(Icons.done_all, size: 14, color: Colors.white70) else const Icon(Icons.done, size: 14, color: Colors.white70),
                ],
              ]),
            ],
          ),
        ),
      );
    }

    return MediaWithCaption(
      isMe: isMe,
      caption: caption,
      child: fileWidget,
    );
  }
}
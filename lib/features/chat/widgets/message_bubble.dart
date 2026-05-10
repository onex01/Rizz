import 'dart:io';
import 'package:flutter/material.dart';
import 'message_content/uploading_message_builder.dart';
import 'message_content/text_message_builder.dart';
import 'message_content/image_message_builder.dart';
import 'message_content/video_message_builder.dart';
import 'message_content/audio_message_builder.dart';
import 'message_content/file_message_builder.dart';
import 'message_content/voice_message_builder.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msgData;
  final bool isMe;
  final String time;
  final bool isLight;
  final double screenWidth;
  final String messageType;
  final Color accentColor;
  final double fontSize;
  final Function(Map<String, dynamic>) onDownloadFile;
  final Function(BuildContext, File, {String? url}) onShowFullScreenImage;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDeleteMe;
  final VoidCallback onDeleteAll;
  final VoidCallback onForward;
  final String messageId;

  const MessageBubble({
    super.key,
    required this.msgData,
    required this.isMe,
    required this.time,
    required this.isLight,
    required this.screenWidth,
    required this.messageType,
    required this.accentColor,
    required this.fontSize,
    required this.onDownloadFile,
    required this.onShowFullScreenImage,
    required this.onReply,
    required this.onCopy,
    required this.onEdit,
    required this.onDeleteMe,
    required this.onDeleteAll,
    required this.onForward,
    required this.messageId,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            if (messageType == 'text') ...[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCopy();
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Изменить'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(ctx);
                onForward();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить для себя'),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteMe();
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Удалить для всех'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteAll();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildContent(context);
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: child,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (messageType.endsWith('_uploading')) {
      return UploadingMessageBuilder.build(
        msgData: msgData,
        isMe: isMe,
        accentColor: accentColor,
        screenWidth: screenWidth,
        messageType: messageType,
      );
    }

    switch (messageType) {
      case 'text':
        return TextMessageBuilder.build(
          context: context,
          msgData: msgData,
          isMe: isMe,
          isLight: isLight,
          accentColor: accentColor,
          fontSize: fontSize,
          time: time,
          screenWidth: screenWidth,
          onCopy: onCopy,
        );
      case 'image':
      case 'image_hex':
        return ImageMessageBuilder.build(
          context: context,
          msgData: msgData,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
          onShowFullScreenImage: onShowFullScreenImage,
          messageId: messageId,
        );
      case 'video':
        return VideoMessageBuilder.build(
          context: context,
          msgData: msgData,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
        );
      case 'audio':
        return AudioMessageBuilder.build(
          msgData: msgData,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
        );
      case 'file':
      case 'file_hex':
      case 'large_file':
        return FileMessageBuilder.build(
          msgData: msgData,
          isMe: isMe,
          isLight: isLight,
          accentColor: accentColor,
          fontSize: fontSize,
          time: time,
          screenWidth: screenWidth,
          onDownloadFile: onDownloadFile,
        );
      case 'voice':
        return VoiceMessageBuilder.build(
          msgData: msgData,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
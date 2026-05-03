import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  @override
  Widget build(BuildContext context) {
    final child = _buildContent(context);
    return CupertinoContextMenu(
      actions: _buildActions(),
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

  List<Widget> _buildActions() {
    return [
      CupertinoContextMenuAction(
        trailingIcon: Icons.reply,
        onPressed: onReply,
        child: const Text('Ответить'),
      ),
      if (messageType == 'text') ...[
        CupertinoContextMenuAction(
          trailingIcon: Icons.copy,
          onPressed: onCopy,
          child: const Text('Копировать'),
        ),
        if (isMe)
          CupertinoContextMenuAction(
            trailingIcon: Icons.edit,
            onPressed: onEdit,
            child: const Text('Изменить'),
          ),
      ],
      CupertinoContextMenuAction(
        trailingIcon: Icons.forward,
        onPressed: onForward,
        child: const Text('Переслать'),
      ),
      CupertinoContextMenuAction(
        trailingIcon: Icons.delete_outline,
        onPressed: onDeleteMe,
        child: const Text('Удалить у меня'),
      ),
      if (isMe)
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: Icons.delete_forever,
          onPressed: onDeleteAll,
          child: const Text('Удалить у всех'),
        ),
    ];
  }
}
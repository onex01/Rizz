import 'dart:io';
import 'package:flutter/material.dart';
import '../light_widgets/lightweight_voice.dart';
import '../voice_player_widget.dart';
import '../chat_common_widgets.dart';

class VoiceMessageBuilder {
  static Widget build({
    required Map<String, dynamic> msgData,
    required bool isMe,
    required String time,
    required double fontSize,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final localPath = mediaData?['localPath'] as String?;
    final caption = msgData['text'] as String? ?? '';

    final File? localFile = (isMe && localPath != null && File(localPath).existsSync()) ? File(localPath) : null;
    if (localFile != null) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: VoicePlayerWidget(file: localFile, isMe: isMe, time: time, fontSize: fontSize),
      );
    }

    if (mediaUrl != null) {
      return MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: LightweightVoiceWidget(url: mediaUrl, isMe: isMe, time: time, fontSize: fontSize),
      );
    }

    // Старый HEX
    return const SizedBox.shrink();
  }
}
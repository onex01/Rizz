import 'dart:io';
import 'package:flutter/material.dart';
import '../light_widgets/lightweight_audio.dart';
import '../chat_common_widgets.dart';

class AudioMessageBuilder {
  static Widget build({
    required Map<String, dynamic> msgData,
    required bool isMe,
    required String time,
    required double fontSize,
  }) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final localPath = mediaData?['localPath'] as String?;
    final title = mediaData?['title'] as String? ?? 'Без названия';
    final artist = mediaData?['artist'] as String? ?? 'Неизвестен';
    final caption = msgData['text'] as String? ?? '$title - $artist';

    final File? localFile = (isMe && localPath != null && File(localPath).existsSync()) ? File(localPath) : null;

    return MediaWithCaption(
      isMe: isMe,
      caption: caption,
      child: LightweightAudioWidget(
        localFile: localFile,
        mediaUrl: mediaUrl,
        title: title,
        artist: artist,
        isMe: isMe,
        time: time,
        fontSize: fontSize,
      ),
    );
  }
}
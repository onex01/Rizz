import 'dart:async';
import 'dart:io';
import 'package:Rizz/shared/services/audio_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/cache_service.dart';

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
  final Function(BuildContext, File) onShowFullScreenImage;
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
    final child = _buildMessageContent();
    return CupertinoContextMenu(
      actions: _buildContextMenuActions(),
      child: child,
    );
  }

  Widget _buildMessageContent() {
    if (messageType == 'image_hex') return _buildImageMessage();
    if (messageType == 'file_hex') return _buildFileMessage();
    // if (messageType == 'video_circle') return _buildCircleVideoMessage();
    if (messageType == 'voice') return _buildVoiceMessage();
    return _buildTextMessage();
  }

  List<Widget> _buildContextMenuActions() {
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

  // ====================== ТЕКСТОВОЕ СООБЩЕНИЕ ======================
  Widget _buildTextMessage() {
    final text = msgData['text'] ?? '';
    final replyToId = msgData['replyToMessageId'] as String?;
    final repliedText = msgData['repliedMessageText'] as String?;
    final isRead = msgData['isRead'] == true;
    final isEdited = msgData['isEdited'] == true;

    final bubbleColor = isMe
        ? accentColor
        : (isLight ? Colors.grey[200]! : Colors.grey[800]!);

    final textColor = isMe ? Colors.white : (isLight ? Colors.black87 : Colors.white);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToId != null && repliedText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        repliedText,
                        style: TextStyle(color: Colors.white70, fontSize: fontSize - 3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Linkify(
              text: text,
              style: TextStyle(color: textColor, fontSize: fontSize),
              linkStyle: TextStyle(
                color: isMe ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
              ),
              onOpen: (link) async {
                final uri = Uri.tryParse(link.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            if (isEdited)
              Text(
                'изменено',
                style: TextStyle(
                  color: isMe ? Colors.white60 : Colors.grey.shade500,
                  fontSize: fontSize - 6,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                    fontSize: fontSize - 5,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isRead)
                    const Icon(Icons.done_all, size: 14, color: Colors.white70)
                  else
                    const Icon(Icons.done, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================== ИЗОБРАЖЕНИЕ (с кэшем) ======================
  Widget _buildImageMessage() {
    return FutureBuilder<File?>(
      future: GetIt.I<MessageFileCache>().getOrConvert(messageId, msgData),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final file = snapshot.data!;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => onShowFullScreenImage(context, file),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
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
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 2),
                            ],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (msgData['isRead'] == true)
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
        );
      },
    );
  }

  // ====================== ФАЙЛ (с кэшем) ======================
  Widget _buildFileMessage() {
    final fileName = msgData['fileName'] ?? 'Файл';
    final fileSize = msgData['fileSize'] ?? 0;
    final isRead = msgData['isRead'] == true;

    final bubbleColor = isMe
        ? accentColor
        : (isLight ? Colors.grey[200]! : Colors.grey[800]!);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFileIcon(msgData['fileExtension']),
                  color: isMe ? Colors.white : accentColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                          fontSize: fontSize - 4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.download, color: isMe ? Colors.white : accentColor),
                  onPressed: () => onDownloadFile(msgData),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                    fontSize: fontSize - 5,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isRead)
                    const Icon(Icons.done_all, size: 14, color: Colors.white70)
                  else
                    const Icon(Icons.done, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================== ВИДЕОКРУЖОК (КРУГЛЫЙ + АВТОПРОИГРЫВАНИЕ) ======================
  // Widget _buildCircleVideoMessage() {
  //   return FutureBuilder<File?>(
  //     future: GetIt.I<MessageFileCache>().getOrConvert(messageId, msgData),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData) {
  //         return const Center(
  //           child: Padding(
  //             padding: EdgeInsets.all(20),
  //             child: CircularProgressIndicator(strokeWidth: 2),
  //           ),
  //         );
  //       }

  //       final file = snapshot.data!;

  //       return _CircleVideoPlayerWidget(
  //         file: file,
  //         isMe: isMe,
  //         time: time,
  //         fontSize: fontSize,
  //       );
  //     },
  //   );
  // }

  // ====================== Голосовые сообщения ======================
  Widget _buildVoiceMessage() {
    return FutureBuilder<File?>(
      future: GetIt.I<MessageFileCache>().getOrConvert(messageId, msgData),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final file = snapshot.data!;
        return _VoicePlayerWidget(file: file, isMe: isMe, time: time, fontSize: fontSize);
      },
    );
  }
}


// ====================== ОТДЕЛЬНЫЙ STATEFUL WIDGET ДЛЯ КРУЖКА (главный фикс OOM) ======================
class _CircleVideoPlayerWidget extends StatefulWidget {
  final File file;
  final bool isMe;
  final String time;
  final double fontSize;

  const _CircleVideoPlayerWidget({
    required this.file,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<_CircleVideoPlayerWidget> createState() => _CircleVideoPlayerWidgetState();
}

class _CircleVideoPlayerWidgetState extends State<_CircleVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.setLooping(true);
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _FullScreenCircleVideo(file: widget.file)),
          );
        },
        child: ClipOval(
          child: SizedBox(
            width: 180,
            height: 180,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                // width: _controller.value.size.width ?? 180,
                // height: _controller.value.size.height ?? 180,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Полноэкранный просмотр
class _FullScreenCircleVideo extends StatefulWidget {
  final File file;
  const _FullScreenCircleVideo({required this.file});

  @override
  State<_FullScreenCircleVideo> createState() => _FullScreenCircleVideoState();
}

class _FullScreenCircleVideoState extends State<_FullScreenCircleVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
  

  // ====================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ======================
  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;
    final ext = extension.toLowerCase();
    if (ext.contains('pdf')) return Icons.picture_as_pdf;
    if (ext.contains('doc')) return Icons.description;
    if (ext.contains('xls')) return Icons.table_chart;
    if (ext.contains('ppt')) return Icons.slideshow;
    if (ext.contains('zip') || ext.contains('rar')) return Icons.folder_zip;
    if (ext.contains('mp3') || ext.contains('wav')) return Icons.audiotrack;
    if (ext.contains('mp4') || ext.contains('mov')) return Icons.video_library;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }// Полноэкранный просмотр кружка

class _VoicePlayerWidget extends StatefulWidget {
  final File file;
  final bool isMe;
  final String time;
  final double fontSize;

  const _VoicePlayerWidget({
    required this.file,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<_VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
} 

class _VoicePlayerWidgetState extends State<_VoicePlayerWidget> {
  final _service = GetIt.I<AudioPlayerService>();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<Duration?> _durationSub;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  void _loadStreams() {
    _playingSub = _service.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _positionSub = _service.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _service.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _service.pause();
    } else {
      await _service.playVoice(
        widget.file.path,
        title: 'Голосовое сообщение',
      );
    }
  }

  @override
  void dispose() {
    _playingSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionText = '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}';
    final durationText = _duration != Duration.zero
        ? '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '0:00';

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlay,
            ),
            const SizedBox(width: 8),
            Text(
              '$positionText / $durationText',
              style: TextStyle(fontSize: widget.fontSize - 2),
            ),
            const SizedBox(width: 8),
            Text(
              widget.time,
              style: TextStyle(fontSize: widget.fontSize - 4, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

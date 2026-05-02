import 'dart:async';
import 'dart:io';
import 'package:Rizz/shared/services/audio_player_service.dart';
import 'package:Rizz/shared/services/media_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/logger/app_logger.dart';
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
    final child = _buildMessageContent(context);
    return CupertinoContextMenu(
      actions: _buildContextMenuActions(),
      child: child,
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Если сообщение находится в процессе загрузки
    if (messageType.endsWith('_uploading')) {
      return _buildUploadingMessage();
    }

    switch (messageType) {
      case 'image':
      case 'image_hex':
        return _buildImageMessage(context);
      case 'video':
        return _buildVideoMessage(context);
      case 'file':
      case 'file_hex':
      case 'large_file':
        return _buildFileMessage(context);
      case 'voice':
        return _buildVoiceMessage(context);
      default:
        return _buildTextMessage();
    }
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

  // ------------------ Загрузка (uploading) ------------------
  Widget _buildUploadingMessage() {
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

  // ------------------ ТЕКСТ (без изменений) ------------------
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
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.15),
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

  // ------------------ ИЗОБРАЖЕНИЕ ------------------
  Widget _buildImageMessage(BuildContext context) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final caption = (msgData['text'] as String?) ?? '';
    final isRead = msgData['isRead'] == true;

    if (mediaUrl != null) {
      return _MediaWithCaption(
        isMe: isMe,
        caption: caption,
        child: LightweightImageWidget(
          url: mediaUrl,
          isMe: isMe,
          time: time,
          fontSize: fontSize,
          isRead: isRead,
          onTap: (ctx, file) => onShowFullScreenImage(ctx, file),
        ),
      );
    }

    // Старый HEX
    return FutureBuilder<File?>(
      future: GetIt.I<MessageFileCache>().getOrConvert(messageId, msgData),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final file = snapshot.data!;
        return _MediaWithCaption(
          isMe: isMe,
          caption: caption,
          child: Align(
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
                      bottom: 4, right: 4,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(time, style: TextStyle(color: Colors.white, fontSize: fontSize - 5, shadows: const [Shadow(color: Colors.black54, blurRadius: 2)])),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (isRead) const Icon(Icons.done_all, size: 14, color: Colors.white) else const Icon(Icons.done, size: 14, color: Colors.white),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------ ВИДЕО ------------------
  Widget _buildVideoMessage(BuildContext context) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final caption = (msgData['text'] as String?) ?? '';

    if (mediaUrl != null) {
      return _MediaWithCaption(
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

  // ------------------ ФАЙЛ ------------------
  Widget _buildFileMessage(BuildContext context) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final fileName = mediaData?['fileName'] as String? ?? 'Файл';
    final fileSize = mediaData?['fileSize'] as int?;
    final caption = (msgData['text'] as String?) ?? '';
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
                  Icon(_getFileIcon(fileName.split('.').last), color: isMe ? Colors.white : accentColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fileName, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: fontSize)),
                      if (fileSize != null) Text(_formatFileSize(fileSize), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade600, fontSize: fontSize - 4)),
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
                  Icon(_getFileIcon(msgData['fileExtension']), color: isMe ? Colors.white : accentColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(msgData['fileName'] ?? 'Файл', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: fontSize)),
                      Text(_formatFileSize(msgData['fileSize'] ?? 0), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade600, fontSize: fontSize - 4)),
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

    return _MediaWithCaption(
      isMe: isMe,
      caption: caption,
      child: fileWidget,
    );
  }

  // ------------------ ГОЛОСОВОЕ ------------------
  Widget _buildVoiceMessage(BuildContext context) {
    final mediaData = msgData['mediaData'] as Map<String, dynamic>?;
    final mediaUrl = mediaData?['mediaUrl'] as String?;
    final caption = (msgData['text'] as String?) ?? '';

    Widget voiceWidget;
    if (mediaUrl != null) {
      voiceWidget = LightweightVoiceWidget(
        url: mediaUrl,
        isMe: isMe,
        time: time,
        fontSize: fontSize,
      );
    } else {
      voiceWidget = FutureBuilder<File?>(
        future: GetIt.I<MessageFileCache>().getOrConvert(messageId, msgData),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return _VoicePlayerWidget(
            file: snapshot.data!,
            isMe: isMe,
            time: time,
            fontSize: fontSize,
          );
        },
      );
    }

    return _MediaWithCaption(
      isMe: isMe,
      caption: caption,
      child: voiceWidget,
    );
  }

  // ------------------ Вспомогательные ------------------
  IconData _getFileIcon(dynamic extension) {
    if (extension == null) return Icons.insert_drive_file;
    final ext = extension.toString().toLowerCase();
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
  }
}

// ========== Виджет для оборачивания медиа с подписью ==========
class _MediaWithCaption extends StatelessWidget {
  final bool isMe;
  final String caption;
  final Widget child;

  const _MediaWithCaption({
    required this.isMe,
    required this.caption,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        child,
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ========== ЛЕГКОВЕСНЫЙ ВИДЖЕТ ИЗОБРАЖЕНИЯ ==========
class LightweightImageWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final String time;
  final double fontSize;
  final bool isRead;
  final Function(BuildContext, File) onTap;

  const LightweightImageWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.time,
    required this.fontSize,
    required this.isRead,
    required this.onTap,
  });

  @override
  State<LightweightImageWidget> createState() => _LightweightImageWidgetState();
}

class _LightweightImageWidgetState extends State<LightweightImageWidget> {
  File? _file;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cache = GetIt.I<MessageFileCache>();
    File? file = await cache.getCachedFile(widget.url);
    if (file == null) {
      try {
        final downloaded = await GetIt.I<MediaApiService>().downloadFile(widget.url);
        if (downloaded != null) {
          await cache.cacheFile(widget.url, downloaded);
          file = downloaded;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _file = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_file == null) {
      return const SizedBox(width: 200, height: 200, child: Center(child: Icon(Icons.broken_image)));
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => widget.onTap(context, _file!),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: ResizeImage(FileImage(_file!), width: 200),
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
                      widget.time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.fontSize - 5,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      if (widget.isRead)
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
  }
}

// ========== ЛЕГКОВЕСНЫЙ ВИДЖЕТ ВИДЕО (открывает сетевой плеер) ==========
class LightweightVideoWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final String time;
  final double fontSize;

  const LightweightVideoWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<LightweightVideoWidget> createState() => _LightweightVideoWidgetState();
}

class _LightweightVideoWidgetState extends State<LightweightVideoWidget> {
  bool _loading = false;

  Future<void> _play() async {
    setState(() => _loading = true);
    try {
      final token = await GetIt.I<MediaApiService>().getToken();
      if (token != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _NetworkVideoPlayer(url: widget.url, token: token),
          ),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: _play,
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
              Icon(
                _loading ? Icons.hourglass_empty : Icons.play_circle_fill,
                color: Colors.white,
                size: 44,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  widget.time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.fontSize - 5,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== СЕТЕВОЙ ВИДЕО ПЛЕЕР (стриминг) ==========
class _NetworkVideoPlayer extends StatefulWidget {
  final String url;
  final String token;

  const _NetworkVideoPlayer({required this.url, required this.token});

  @override
  _NetworkVideoPlayerState createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = true;
  double _speed = 1.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: {'Authorization': 'Bearer ${widget.token}'},
    );
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.addListener(() {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _toggleSpeed() {
    final speeds = [1.0, 1.5, 2.0, 0.5];
    final currentIndex = speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    _speed = speeds[nextIndex];
    _controller.setPlaybackSpeed(_speed);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            _playing ? _controller.pause() : _controller.play();
                            setState(() => _playing = !_playing);
                          },
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _toggleSpeed,
                          child: Text('${_speed}x', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }
}

// ========== ПОЛНОЭКРАННЫЙ ЛОКАЛЬНЫЙ ПЛЕЕР (для старых видео / fallback) ==========
class _FullScreenVideo extends StatefulWidget {
  final File file;
  const _FullScreenVideo({required this.file});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = true;
  double _speed = 1.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.addListener(() {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _toggleSpeed() {
    final speeds = [1.0, 1.5, 2.0, 0.5];
    final currentIndex = speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    _speed = speeds[nextIndex];
    _controller.setPlaybackSpeed(_speed);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator());
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            _playing ? _controller.pause() : _controller.play();
                            setState(() => _playing = !_playing);
                          },
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _toggleSpeed,
                          child: Text('${_speed}x', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }
}

// ========== ЛЕГКОВЕСНЫЙ ВИДЖЕТ ГОЛОСОВОГО ==========
class LightweightVoiceWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final String time;
  final double fontSize;

  const LightweightVoiceWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<LightweightVoiceWidget> createState() => _LightweightVoiceWidgetState();
}

class _LightweightVoiceWidgetState extends State<LightweightVoiceWidget> {
  File? _file;
  bool _loading = true;

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
    _playingSub = _service.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _positionSub = _service.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _service.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    _loadFile();
  }

  Future<void> _loadFile() async {
    final cache = GetIt.I<MessageFileCache>();
    File? file = await cache.getCachedFile(widget.url);
    if (file == null) {
      try {
        final downloaded = await GetIt.I<MediaApiService>().downloadFile(widget.url);
        if (downloaded != null) {
          await cache.cacheFile(widget.url, downloaded);
          file = downloaded;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _file = file;
        _loading = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_file == null) return;
    try {
      if (_isPlaying) {
        await _service.pause();
      } else {
        await _service.playVoice(_file!.path, title: 'Голосовое сообщение');
      }
    } catch (e) {
      GetIt.I<AppLogger>().error('Voice playback error', error: e);
      if (mounted) setState(() => _isPlaying = false);
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
    if (_loading) {
      return const SizedBox(
        width: 200,
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_file == null) {
      return const SizedBox(width: 200, height: 44, child: Center(child: Icon(Icons.error_outline)));
    }

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
            Text('$positionText / $durationText', style: TextStyle(fontSize: widget.fontSize - 2)),
            const SizedBox(width: 8),
            Text(widget.time, style: TextStyle(fontSize: widget.fontSize - 4, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ========== СТАРЫЙ ВИДЖЕТ ГОЛОСОВОГО (HEX) ==========
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
    try {
      if (_isPlaying) {
        await _service.pause();
      } else {
        await _service.playVoice(widget.file.path, title: 'Голосовое сообщение');
      }
    } catch (e) {
      GetIt.I<AppLogger>().error('Voice playback error', error: e);
      if (mounted) setState(() => _isPlaying = false);
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
            Text('$positionText / $durationText', style: TextStyle(fontSize: widget.fontSize - 2)),
            const SizedBox(width: 8),
            Text(widget.time, style: TextStyle(fontSize: widget.fontSize - 4, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
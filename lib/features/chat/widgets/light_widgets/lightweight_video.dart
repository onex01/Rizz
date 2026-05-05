import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rizz/shared/services/cache_service.dart';
import '../../../../shared/services/media_api_service.dart';
import '../network_video_player.dart';

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

      final cache = GetIt.I<MessageFileCache>();
      File? file = await cache.getCachedFile(widget.url);
      if (file == null) {
        final downloaded = await GetIt.I<MediaApiService>().downloadFile(widget.url);
        if (downloaded != null) {
          await cache.cacheFile(widget.url, downloaded);
        }
      }

      if (token != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NetworkVideoPlayer(url: widget.url, token: token),
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
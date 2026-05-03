import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../shared/services/cache_service.dart';
import '../../../../shared/services/media_api_service.dart';

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
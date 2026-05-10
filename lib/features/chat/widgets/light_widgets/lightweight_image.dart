import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LightweightImageWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final String time;
  final double fontSize;
  final bool isRead;
  final Function(BuildContext, String) onTap;

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
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => widget.onTap(context, widget.url),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
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
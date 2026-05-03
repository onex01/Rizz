import 'package:flutter/material.dart';

class MediaWithCaption extends StatelessWidget {
  final bool isMe;
  final String caption;
  final Widget child;

  const MediaWithCaption({
    super.key,
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
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

IconData getFileIcon(dynamic extension) {
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

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
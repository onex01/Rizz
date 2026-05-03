import 'dart:ui';
import 'package:flutter/material.dart';

class ChatAttachmentMenu extends StatelessWidget {
  final bool isLight;
  final VoidCallback onPickMedia;
  final VoidCallback onOpenCamera;
  final VoidCallback onPickFile;
  final VoidCallback onPickAudio;
  final VoidCallback onVoiceRecord;

  const ChatAttachmentMenu({
    super.key,
    required this.isLight,
    required this.onPickMedia,
    required this.onOpenCamera,
    required this.onPickFile,
    required this.onPickAudio,
    required this.onVoiceRecord,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: isLight ? Colors.white.withValues(alpha: 0.95) : Colors.black.withValues(alpha: 0.95),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.grey.shade300 : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildItem(Icons.photo_library, Colors.blue, 'Галерея (фото/видео)', onPickMedia),
                _buildItem(Icons.camera_alt, Colors.green, 'Камера', onOpenCamera),
                _buildItem(Icons.insert_drive_file, Colors.orange, 'Файл', onPickFile),
                _buildItem(Icons.music_note, Colors.purple, 'Музыка', onPickAudio),
                _buildItem(Icons.mic, Colors.red, 'Голосовое сообщение', onVoiceRecord),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, Color color, String title, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
      title: Text(title),
      onTap: onTap,
    );
  }
}
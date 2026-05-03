import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_upload_helper.dart';

class ChatMediaPicker {
  static Future<void> pickMediaFromGallery({
    required BuildContext context,
    required ChatUploadHelper uploadHelper,
  }) async {
    final result = await FilePicker.pickFiles(type: FileType.media, allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    bool firstImage = true;
    for (final file in result.files) {
      if (file.path == null) continue;
      final ext = file.name.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
      
      File? finalFile = File(file.path!);
      if (!isVideo && firstImage) {
        firstImage = false;
      }
      
      final typeKey = isVideo ? 'video' : 'image';
      final caption = (await _askCaption(context, file.name)) ?? '';
      await uploadHelper.uploadAndSendMessage(finalFile, caption, typeKey);
    }
  }

  static Future<void> takePictureOrVideo({
    required BuildContext context,
    required ChatUploadHelper uploadHelper,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Снять фото'),
            onTap: () => Navigator.pop(context, 'photo'),
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Снять видео'),
            onTap: () => Navigator.pop(context, 'video'),
          ),
        ],
      ),
    );
    if (result == null) return;

    final picker = ImagePicker();
    if (result == 'photo') {
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 800);
      if (picked != null) {
        final caption = (await _askCaption(context, 'photo.jpg')) ?? '';
        await uploadHelper.uploadAndSendMessage(File(picked.path), caption, 'image');
      }
    } else {
      final picked = await picker.pickVideo(source: ImageSource.camera);
      if (picked != null) {
        final caption = (await _askCaption(context, 'video.mp4')) ?? '';
        await uploadHelper.uploadAndSendMessage(File(picked.path), caption, 'video');
      }
    }
  }

  static Future<void> pickFile({
    required BuildContext context,
    required ChatUploadHelper uploadHelper,
  }) async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final caption = (await _askCaption(context, result.files.single.name)) ?? '';
      await uploadHelper.uploadAndSendMessage(file, caption, 'file');
    }
  }

  static Future<void> pickAudio({
    required BuildContext context,
    required ChatUploadHelper uploadHelper,
  }) async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final metadata = await _askAudioMetadata(context, result.files.single.name);
    await uploadHelper.uploadAudio(file, metadata?.title ?? result.files.single.name, metadata?.artist ?? '');
  }

  static Future<String?> _askCaption(BuildContext context, String fileName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Подпись к "$fileName"'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Добавить подпись...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Пропустить')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Готово')),
        ],
      ),
    );
  }

  static Future<({String title, String artist})?> _askAudioMetadata(BuildContext context, String fileName) async {
    final titleCtrl = TextEditingController(text: fileName);
    final artistCtrl = TextEditingController();
    return showDialog<({String title, String artist})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Метаданные аудио'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Исполнитель')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, (title: titleCtrl.text, artist: artistCtrl.text)),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
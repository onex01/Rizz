import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'file_converter_service.dart';
 
class VoiceService {
  static final AudioRecorder _recorder = AudioRecorder();
  static String? _recordingPath;

  static Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _recordingPath = path;
    } else {
      Fluttertoast.showToast(msg: 'Нет разрешения на запись');
    }
  }

  static Future<File?> stopRecording() async {
    if (_recordingPath == null) return null;
    final path = await _recorder.stop();
    _recordingPath = null;
    if (path != null) return File(path);
    return null;
  }

  static Future<void> sendVoiceMessage(String chatId, File file, {String? replyToMessageId}) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 500 * 1024) {
      Fluttertoast.showToast(msg: 'Голосовое слишком большое, будет отправлено позже');
      return;
    }
    final hexData = await FileConverterService.fileToHex(file);
    final messageData = {
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'type': 'voice',
      'duration': await _getDuration(file),
      'hexData': hexData,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToMessageId,
      'isRead': false,
    };
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
          'lastMessage': '🎤 Голосовое',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
  }

  /// Надёжное получение длительности голосового (исправлено)
  static Future<int> _getDuration(File file) async {
    final player = AudioPlayer();
    try {
      await player.setAudioSource(AudioSource.file(file.path));

      // Правильный способ в just_audio: ждём первый ненулевой duration из стрима
      final duration = await player.durationStream
          .firstWhere((d) => d != null)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );

      if (duration != null && duration.inSeconds > 0) {
        return duration.inSeconds;
      }
    } catch (e) {
      debugPrint('Error getting voice duration: $e');
    } finally {
      await player.dispose();
    }
    return 0; // fallback
  }
}

// Диалог записи голосового
class VoiceRecorderDialog extends StatefulWidget {
  final Function(File) onSend;
  const VoiceRecorderDialog({super.key, required this.onSend});

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Запись голосового...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '$_seconds сек',
            style: const TextStyle(fontSize: 32, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  _timer?.cancel();
                  final file = await VoiceService.stopRecording();
                  if (file != null && mounted) {
                    widget.onSend(file);
                    if (mounted) Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Ошибка записи');
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Отправить'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _timer?.cancel();
                  VoiceService.stopRecording();
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('Отмена'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
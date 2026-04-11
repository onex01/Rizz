import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'file_converter_service.dart';
// import 'message_service.dart';

class CircleVideoService {
  static const String messageType = 'video_circle';

  static Future<void> sendRecordedCircle(String chatId, File videoFile, {String? replyToId}) async {
    final bytes = await videoFile.readAsBytes();
    if (bytes.length > 800 * 1024) {
      Fluttertoast.showToast(msg: 'Видео слишком большое, даже после сжатия');
      return;
    }
    final hexData = await FileConverterService.fileToHex(videoFile);
    final fileName = 'circle_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final messageData = {
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'type': messageType,
      'fileName': fileName,
      'fileExtension': '.mp4',
      'fileSize': bytes.length,
      'hexData': hexData,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToId,
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
        'lastMessage': '🎥 Кружок',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    Fluttertoast.showToast(msg: 'Видеокружок отправлен!', backgroundColor: Colors.green);
  }
}

// Экран записи видеокружка с удержанием
class CircleRecorderOverlay extends StatefulWidget {
  const CircleRecorderOverlay({super.key});

  @override
  State<CircleRecorderOverlay> createState() => _CircleRecorderOverlayState();
}

class _CircleRecorderOverlayState extends State<CircleRecorderOverlay> {
  CameraController? _controller;
  bool _isRecording = false;
  Timer? _timer;
  int _remainingSeconds = 20;
  final int maxDuration = 20;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(front, ResolutionPreset.medium, enableAudio: true);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;
    _timer?.cancel();
    final video = await _controller!.stopVideoRecording();
    if (mounted) Navigator.pop(context, File(video.path));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 5),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(fontSize: 64, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.white,
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: _isRecording ? Colors.white : Colors.red,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 36),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
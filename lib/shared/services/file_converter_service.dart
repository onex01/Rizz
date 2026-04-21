import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileConverterService {
  static const int maxFileSize = 500 * 1024;

  static Future<String> fileToHex(File file) async {
    final bytes = await file.readAsBytes();
    return _bytesToHex(bytes);
  }

  /// Главный метод — максимально устойчивый
  static Future<File> hexToFile(String inputData, String fileName) async {
    if (inputData.isEmpty) {
      throw Exception('Данные для аватарки пустые');
    }

    List<int> bytes;

    // 1. Пытаемся декодировать как HEX
    try {
      bytes = _hexToBytesSafe(inputData);
      if (bytes.isNotEmpty) {
        return await _writeFile(bytes, fileName);
      }
    } catch (_) {}

    // 2. Если не HEX — возможно base64 (очень частая проблема)
    try {
      bytes = _base64ToBytes(inputData);
      if (bytes.isNotEmpty) {
        return await _writeFile(bytes, fileName);
      }
    } catch (_) {}

    throw Exception('Не удалось распознать формат данных аватарки (ни HEX, ни base64)');
  }

  static Future<File> _writeFile(List<int> bytes, String fileName) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');

    // Удаляем старый пустой файл, если он есть
    if (await file.exists()) {
      if (await file.length() == 0) {
        await file.delete();
      }
    }

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Безопасное декодирование HEX
  static List<int> _hexToBytesSafe(String hex) {
    final List<int> bytes = [];
    final clean = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

    for (int i = 0; i < clean.length - 1; i += 2) {
      try {
        bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
      } catch (_) {
        continue;
      }
    }
    return bytes;
  }

  /// Декодирование base64 (часто приходит в avatarHex)
  static List<int> _base64ToBytes(String data) {
    // Убираем префикс data:image/jpeg;base64, если есть
    final clean = data.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '');
    return Uri.parse('data:application/octet-stream;base64,$clean').data!.contentAsBytes();
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Остальные методы без изменений
  static Future<bool> canConvert(File file) async {
    final size = await file.length();
    return size <= maxFileSize;
  }

  static Future<String> getFileSizeString(File file) async {
    final size = await file.length();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<File> assembleFromChunks(List<String> chunkIds, String fileName) async {
    List<int> allBytes = [];
    for (String id in chunkIds) {
      final doc = await FirebaseFirestore.instance.collection('chunks').doc(id).get();
      final hex = doc['hex'] as String;
      allBytes.addAll(_hexToBytesSafe(hex));
    }
    return await _writeFile(allBytes, fileName);
  }
}
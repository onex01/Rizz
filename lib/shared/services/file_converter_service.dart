import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class FileConverterService {
  static const int maxFileSize = 500 * 1024; // 500 KB

  static Future<String> fileToHex(File file) async {
    final bytes = await file.readAsBytes();
    return _bytesToHex(bytes);
  }

  static Future<File> hexToFile(String hexData, String fileName) async {
    final bytes = _hexToBytes(hexData);
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static List<int> _hexToBytes(String hex) {
    final List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      final byte = int.parse(hex.substring(i, i + 2), radix: 16);
      bytes.add(byte);
    }
    return bytes;
  }

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
      allBytes.addAll(_hexToBytes(hex));
    }
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(allBytes);
    return file;
  }
}
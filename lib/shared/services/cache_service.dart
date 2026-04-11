import 'dart:io';
import 'file_converter_service.dart';

class MessageFileCache {
  static final MessageFileCache _instance = MessageFileCache._internal();
  factory MessageFileCache() => _instance;
  MessageFileCache._internal();

  final Map<String, File> _cache = {};

  Future<File?> getOrConvert(String messageId, Map<String, dynamic> msgData) async {
    if (_cache.containsKey(messageId)) {
      return _cache[messageId];
    }

    final hexData = msgData['hexData'];
    final fileName = msgData['fileName'];
    if (hexData == null || fileName == null) return null;

    try {
      final file = await FileConverterService.hexToFile(hexData, fileName);
      _cache[messageId] = file;
      return file;
    } catch (e) {
      print('Cache conversion error: $e');
      return null;
    }
  }

  void remove(String messageId) => _cache.remove(messageId);
  void clear() => _cache.clear();
  int get size => _cache.length;
}
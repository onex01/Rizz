// ================================================
// ОБНОВЛЁННЫЙ СЕРВИС КЭША (MessageFileCache) (илюха пидорас, не меняй)
// ================================================
// lib/shared/services/cache_service.dart 

import 'dart:io';
import 'package:get_it/get_it.dart';

import '../../../core/logger/app_logger.dart';
import 'file_converter_service.dart';

class MessageFileCache {
  static final MessageFileCache _instance = MessageFileCache._internal();
  factory MessageFileCache() => _instance;
  MessageFileCache._internal();

  final Map<String, File> _memoryCache = {};
  final Map<String, Future<File?>> _pendingConversions = {}; // ← ЗАЩИТА ОТ RACE CONDITION

  Future<File?> getOrConvert(String messageId, Map<String, dynamic> msgData) async {
  if (_memoryCache.containsKey(messageId)) {
    return _memoryCache[messageId];
  }

  if (_pendingConversions.containsKey(messageId)) {
    return _pendingConversions[messageId]!;
  }

  final String? hexData = msgData['hexData'];
  if (hexData == null || hexData.isEmpty) return null;

  final String originalFileName = msgData['fileName'] ?? 'media';
  final String cacheFileName = 'msg_${messageId}_$originalFileName';

  final tempDir = Directory.systemTemp;
  final cachedFile = File('${tempDir.path}/$cacheFileName');

  final conversionFuture = _performConversion(messageId, hexData, cachedFile, cacheFileName);
  _pendingConversions[messageId] = conversionFuture;

  try {
    final file = await conversionFuture;
    if (file != null) {
      // Дополнительная проверка — файл не пустой
      if (await file.length() == 0) {
        await file.delete(); // удаляем пустой файл
        return null;
      }
      _memoryCache[messageId] = file;
    }
    return file;
  } finally {
    _pendingConversions.remove(messageId);
  }
}

  Future<File?> _performConversion(
    String messageId,
    String hexData,
    File cachedFile,
    String cacheFileName,
  ) async {
    // Проверяем диск (если уже есть после перезапуска приложения)
    if (await cachedFile.exists()) {
      return cachedFile;
    }

    try {
      final convertedFile = await FileConverterService.hexToFile(hexData, cacheFileName);
      return convertedFile;
    } catch (e, stack) {
      GetIt.I<AppLogger>().error('MessageFileCache: ошибка конвертации messageId=$messageId', error: e, stack: stack);
      return null;
    }
  }

  /// Полная очистка кэша (диск + память) — уже использовался в настройках
  Future<void> clearCache() async {
    final tempDir = Directory.systemTemp;
    try {
      final entities = tempDir.listSync(recursive: false);
      for (var entity in entities) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_')) {
            await entity.delete();
          }
        }
      }
      _memoryCache.clear();
      _pendingConversions.clear();
      GetIt.I<AppLogger>().info('MessageFileCache: кэш полностью очищен');
    } catch (e) {
      GetIt.I<AppLogger>().error('MessageFileCache.clearCache error', error: e);
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    _pendingConversions.clear();
  }

  /// Для настроек (уже работал)
  Future<Map<String, dynamic>> getCacheInfo() async {
    final tempDir = Directory.systemTemp;
    final List<String> files = [];
    int totalSizeBytes = 0;

    try {
      for (var entity in tempDir.listSync(recursive: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_')) {
            files.add(name);
            totalSizeBytes += await entity.length();
          }
        }
      }
    } catch (e) {
      GetIt.I<AppLogger>().error('MessageFileCache.getCacheInfo error', error: e);
    }

    return {
      'fileCount': files.length,
      'totalSizeBytes': totalSizeBytes,
      'totalSizeFormatted': _formatBytes(totalSizeBytes),
      'files': files,
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
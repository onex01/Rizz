import 'dart:io';
import 'package:get_it/get_it.dart';
import '../../../core/logger/app_logger.dart';
import 'file_converter_service.dart';

class MessageFileCache {
  static final MessageFileCache _instance = MessageFileCache._internal();
  factory MessageFileCache() => _instance;
  MessageFileCache._internal();

  final Map<String, File> _memoryCache = {}; // для старых hex
  final Map<String, Future<File?>> _pendingConversions = {};

  // Новый кэш в памяти для файлов, скачанных по URL
  final Map<String, File> _urlMemoryCache = {};

  static const int maxCacheBytes = 50 * 1024 * 1024; // 50 MB

  Future<void> _enforceCacheLimit() async {
    final dir = Directory('${Directory.systemTemp.path}/media_cache');
    if (!await dir.exists()) return;
    final files = <FileSystemEntity>[];
    int totalSize = 0;
    await for (var entity in dir.list()) {
      if (entity is File) {
        final length = await entity.length();
        files.add(entity);
        totalSize += length;
      }
    }
    if (totalSize > maxCacheBytes) {
      // сортируем по дате создания (старые в начале)
      files.sort((a, b) => a.statSync().changed.compareTo(b.statSync().changed));
      for (var file in files) {
        if (totalSize <= maxCacheBytes) break;
        final size = await (file as File).length();
        await (file as File).delete();
        totalSize -= size;
      }
    }
  }

  /// Получить файл из кэша по URL (сначала память, потом диск)
  Future<File?> getCachedFile(String url) async {
    if (_urlMemoryCache.containsKey(url)) return _urlMemoryCache[url];
    final hash = _hash(url);
    final file = File('${Directory.systemTemp.path}/media_cache/$hash');
    if (await file.exists()) {
      _urlMemoryCache[url] = file;
      return file;
    }
    return null;
  }

  /// Сохранить файл в кэш для указанного URL
  Future<void> cacheFile(String url, File source) async {
    final hash = _hash(url);
    final dir = Directory('${Directory.systemTemp.path}/media_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = File('${dir.path}/$hash');
    await source.copy(target.path);
    _urlMemoryCache[url] = target;
  }

  String _hash(String input) {
    return input.hashCode.toRadixString(16);
  }

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

  Future<void> clearCache() async {
    final tempDir = Directory.systemTemp;
    try {
      // Удаляем старые файлы msg_*, avatar_*
      for (var entity in tempDir.listSync(recursive: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_')) {
            await entity.delete();
          }
        }
      }
      // Удаляем папку media_cache
      final mediaCacheDir = Directory('${tempDir.path}/media_cache');
      if (await mediaCacheDir.exists()) {
        await mediaCacheDir.delete(recursive: true);
      }
      _memoryCache.clear();
      _pendingConversions.clear();
      _urlMemoryCache.clear();
      GetIt.I<AppLogger>().info('MessageFileCache: кэш полностью очищен');
    } catch (e) {
      GetIt.I<AppLogger>().error('MessageFileCache.clearCache error', error: e);
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    _pendingConversions.clear();
    _urlMemoryCache.clear();
  }

  /// Обновлённый метод для настроек: видит и старые, и новые файлы
  Future<Map<String, dynamic>> getCacheInfo() async {
    final tempDir = Directory.systemTemp;
    final List<String> files = [];
    int totalSizeBytes = 0;

    try {
      // Старые файлы
      for (var entity in tempDir.listSync(recursive: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_')) {
            files.add(name);
            totalSizeBytes += await entity.length();
          }
        }
      }
      // Файлы из media_cache
      final mediaCacheDir = Directory('${tempDir.path}/media_cache');
      if (await mediaCacheDir.exists()) {
        await for (var entity in mediaCacheDir.list(recursive: false)) {
          if (entity is File) {
            files.add('media_cache/${entity.path.split('/').last}');
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
import 'dart:io';

class MessageFileCache {
  static final MessageFileCache _instance = MessageFileCache._internal();
  factory MessageFileCache() => _instance;
  MessageFileCache._internal();

  final Map<String, File> _urlMemoryCache = {};

  /// Получить файл из кэша по URL
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

  /// Сохранить файл в кэш
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

  /// Полная очистка кэша
  Future<void> clearCache() async {
    final tempDir = Directory.systemTemp;
    try {
      for (var entity in tempDir.listSync(recursive: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_') || name.startsWith('url_')) {
            await entity.delete();
          }
        }
      }
      final mediaCacheDir = Directory('${tempDir.path}/media_cache');
      if (await mediaCacheDir.exists()) {
        await mediaCacheDir.delete(recursive: true);
      }
      _urlMemoryCache.clear();
    } catch (e) {
      print('MessageFileCache.clearCache error: $e');
    }
  }

  /// Информация о кэше для настроек
  Future<Map<String, dynamic>> getCacheInfo() async {
    final tempDir = Directory.systemTemp;
    final List<String> files = [];
    int totalSizeBytes = 0;

    try {
      for (var entity in tempDir.listSync(recursive: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          if (name.startsWith('msg_') || name.startsWith('avatar_') || name.startsWith('url_')) {
            files.add(name);
            totalSizeBytes += await entity.length();
          }
        }
      }
      final mediaCacheDir = Directory('${tempDir.path}/media_cache');
      if (await mediaCacheDir.exists()) {
        await for (var entity in mediaCacheDir.list()) {
          if (entity is File) {
            files.add('media_cache/${entity.path.split('/').last}');
            totalSizeBytes += await entity.length();
          }
        }
      }
    } catch (e) {
      print('MessageFileCache.getCacheInfo error: $e');
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
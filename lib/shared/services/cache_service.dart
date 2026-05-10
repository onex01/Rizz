import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MessageFileCache {
  static final MessageFileCache _instance = MessageFileCache._internal();
  factory MessageFileCache() => _instance;
  MessageFileCache._internal();

  final Map<String, File> _urlMemoryCache = {};
  late final CacheManager _cacheManager;

  Future<void> init() async {
    if (kIsWeb) {
      _cacheManager = CacheManager(
        Config(
          'rizz_web_cache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
        ),
      );
    } else {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/media_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      _cacheManager = CacheManager(
        Config(
          'rizz_media_cache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
        ),
      );
    }
  }

  Future<File?> getCachedFile(String url) async {
    if (_urlMemoryCache.containsKey(url)) return _urlMemoryCache[url];
    try {
      final cacheEntry = await _cacheManager.getFileFromCache(url);
      if (cacheEntry != null) {
        _urlMemoryCache[url] = cacheEntry.file;
        return cacheEntry.file;
      }
    } catch (e) {}
    return null;
  }

  // ИСПРАВЛЕННЫЙ МЕТОД cacheFile
  Future<void> cacheFile(String url, File source) async {
    try {
      final cachedFile = await _cacheManager.putFile(url, await source.readAsBytes());
      // putFile возвращает File, а не объект с полем file
      _urlMemoryCache[url] = cachedFile;
    } catch (e) {}
  }

  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    _urlMemoryCache.clear();
    if (!kIsWeb) {
      try {
        final tempDir = await getTemporaryDirectory();
        final mediaCacheDir = Directory('${tempDir.path}/media_cache');
        if (await mediaCacheDir.exists()) {
          await mediaCacheDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    if (kIsWeb) {
      return {
        'fileCount': 0,
        'totalSizeBytes': 0,
        'totalSizeFormatted': '0 B',
        'files': [],
      };
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final List<String> files = [];
      int totalSizeBytes = 0;

      final mediaCacheDir = Directory('${tempDir.path}/media_cache');
      if (await mediaCacheDir.exists()) {
        await for (var entity in mediaCacheDir.list()) {
          if (entity is File) {
            files.add(entity.path.split('/').last);
            totalSizeBytes += await entity.length();
          }
        }
      }

      return {
        'fileCount': files.length,
        'totalSizeBytes': totalSizeBytes,
        'totalSizeFormatted': _formatBytes(totalSizeBytes),
        'files': files,
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSizeBytes': 0,
        'totalSizeFormatted': '0 B',
        'files': [],
      };
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
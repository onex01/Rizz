import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:open_file/open_file.dart';
import '../../core/logger/app_logger.dart';
import '../../core/platform/platform_info.dart';
import '../../version.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final int fileSize;
  final String? windowsUrl;
  final String? linuxUrl;
  final String? macUrl;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.fileSize,
    this.windowsUrl,
    this.linuxUrl,
    this.macUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'],
      downloadUrl: json['androidUrl'] ?? json['downloadUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      windowsUrl: json['windowsUrl'],
      linuxUrl: json['linuxUrl'],
      macUrl: json['macUrl'],
    );
  }

  String? get urlForCurrentPlatform {
    final platform = GetIt.I<PlatformInfo>();
    if (platform.isMobile && Platform.isAndroid) return downloadUrl;
    if (platform.isDesktop) {
      if (Platform.isWindows) return windowsUrl;
      if (Platform.isLinux) return linuxUrl;
      if (Platform.isMacOS) return macUrl;
    }
    return null;
  }
}

class UpdateService {
  static const String baseUrl = 'https://rizz.onex01.ru/';
  final _logger = GetIt.I<AppLogger>();
  final _platform = GetIt.I<PlatformInfo>();

  Future<UpdateInfo?> checkForUpdates() async {
    await _logger.info('Checking for updates...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/version.json'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'];
        final currentVersion = AppVersion.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          await _logger.info('Update available: $latestVersion');
          return UpdateInfo.fromJson(data);
        }
      }
      return null;
    } catch (e, stack) {
      await _logger.error('Update check failed', e, stack);
      return null;
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Доступна новая версия ${info.version}'),
        content: Text('Размер: ${(info.fileSize / 1024 / 1024).toStringAsFixed(1)} МБ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Обновить')),
        ],
      ),
    );

    if (shouldUpdate == true) {
      final url = info.urlForCurrentPlatform;
      if (url == null || url.isEmpty) {
        _showError(context, 'Обновление для вашей платформы недоступно');
        return;
      }
      await _downloadAndInstall(context, url);
    }
  }

  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final downloadsDir = await _platform.getDownloadsDirectory();
      if (downloadsDir == null) throw Exception('Не удалось получить папку загрузок');

      final fileName = _getFileNameForPlatform(url);
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      Navigator.pop(context); // убираем прогресс

      await _platform.openFile(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл сохранён: ${file.path}')),
        );
      }
    } catch (e, stack) {
      await _logger.error('Update download failed', e, stack);
      Navigator.pop(context);
      if (context.mounted) _showError(context, 'Ошибка загрузки обновления');
    }
  }

  String _getFileNameForPlatform(String url) {
    if (_platform.isMobile) return 'Rizz_update.apk';
    if (Platform.isWindows) return 'Rizz_Setup.exe';
    if (Platform.isLinux) return 'rizz.deb';
    if (Platform.isMacOS) return 'Rizz.dmg';
    return 'Rizz_update';
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
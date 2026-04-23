import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/logger/app_logger.dart';
import '../../core/platform/platform_info.dart';
import '../../version.dart';

class UpdateInfo {
  final String version;
  final String? androidUrl;
  final int? androidSize;
  final String? windowsExeUrl;
  final int? windowsExeSize;
  final String? windowsOtaUrl;
  final int? windowsOtaSize;
  final String? linuxDebUrl;
  final int? linuxDebSize;
  final String? linuxRpmUrl;
  final int? linuxRpmSize;
  final String? linuxBinUrl;
  final int? linuxBinSize;
  final String? linuxOtaUrl;
  final int? linuxOtaSize;
  final String? macPkgUrl;
  final int? macPkgSize;
  final String? macOtaUrl;
  final int? macOtaSize;

  UpdateInfo({
    required this.version,
    this.androidUrl,
    this.androidSize,
    this.windowsExeUrl,
    this.windowsExeSize,
    this.windowsOtaUrl,
    this.windowsOtaSize,
    this.linuxDebUrl,
    this.linuxDebSize,
    this.linuxRpmUrl,
    this.linuxRpmSize,
    this.linuxBinUrl,
    this.linuxBinSize,
    this.linuxOtaUrl,
    this.linuxOtaSize,
    this.macPkgUrl,
    this.macPkgSize,
    this.macOtaUrl,
    this.macOtaSize,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? android = json['android'];
    final Map<String, dynamic>? windows = json['windows'];
    final Map<String, dynamic>? linux = json['linux'];
    final Map<String, dynamic>? mac = json['macos'];

    return UpdateInfo(
      version: json['version'],
      androidUrl: android?['url'],
      androidSize: android?['size'],
      windowsExeUrl: windows?['exe']?['url'],
      windowsExeSize: windows?['exe']?['size'],
      windowsOtaUrl: windows?['ota']?['url'],
      windowsOtaSize: windows?['ota']?['size'],
      linuxDebUrl: linux?['deb']?['url'],
      linuxDebSize: linux?['deb']?['size'],
      linuxRpmUrl: linux?['rpm']?['url'],
      linuxRpmSize: linux?['rpm']?['size'],
      linuxBinUrl: linux?['bin']?['url'],
      linuxBinSize: linux?['bin']?['size'],
      linuxOtaUrl: linux?['ota']?['url'],
      linuxOtaSize: linux?['ota']?['size'],
      macPkgUrl: mac?['pkg']?['url'],
      macPkgSize: mac?['pkg']?['size'],
      macOtaUrl: mac?['ota']?['url'],
      macOtaSize: mac?['ota']?['size'],
    );
  }

  Map<String, _UpdateVariant> get availableVariants {
    final map = <String, _UpdateVariant>{};
    if (Platform.isAndroid && androidUrl != null) {
      map['APK'] = _UpdateVariant(androidUrl!, androidSize ?? 0);
    } else if (Platform.isWindows) {
      if (windowsExeUrl != null) map['Установщик (EXE)'] = _UpdateVariant(windowsExeUrl!, windowsExeSize ?? 0);
      if (windowsOtaUrl != null) map['Лёгкое обновление (OTA)'] = _UpdateVariant(windowsOtaUrl!, windowsOtaSize ?? 0);
    } else if (Platform.isLinux) {
      if (linuxOtaUrl != null) map['Лёгкое обновление (OTA)'] = _UpdateVariant(linuxOtaUrl!, linuxOtaSize ?? 0);
      if (linuxDebUrl != null) map['Пакет DEB'] = _UpdateVariant(linuxDebUrl!, linuxDebSize ?? 0);
      if (linuxRpmUrl != null) map['Пакет RPM'] = _UpdateVariant(linuxRpmUrl!, linuxRpmSize ?? 0);
      if (linuxBinUrl != null) map['Бинарный архив'] = _UpdateVariant(linuxBinUrl!, linuxBinSize ?? 0);
    } else if (Platform.isMacOS) {
      if (macPkgUrl != null) map['Установщик (PKG)'] = _UpdateVariant(macPkgUrl!, macPkgSize ?? 0);
      if (macOtaUrl != null) map['Лёгкое обновление (OTA)'] = _UpdateVariant(macOtaUrl!, macOtaSize ?? 0);
    }
    return map;
  }
}

class _UpdateVariant {
  final String url;
  final int size;
  _UpdateVariant(this.url, this.size);
}

class UpdateService {
  static const String baseUrl = 'https://update.rizzdp.ru/';
  final _logger = GetIt.I<AppLogger>();
  final _platform = GetIt.I<PlatformInfo>();

  Future<UpdateInfo?> checkForUpdates() async {
    if (Platform.isIOS || kIsWeb) {
      await _logger.info('Updates are disabled on this platform');
      return null;
    }

    await _logger.info('Checking for updates...');
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}version.json'),
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
      await _logger.error('Update check failed', error: e, stack: stack);
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
    final variants = info.availableVariants;
    if (variants.isEmpty) {
      _showError(context, 'Для вашей платформы нет доступных обновлений.');
      return;
    }

    if (variants.length == 1) {
      final entry = variants.entries.first;
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Доступна версия ${info.version}'),
          content: Text('Тип: ${entry.key}\nРазмер: ${_formatSize(entry.value.size)}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Скачать')),
          ],
        ),
      );
      if (shouldDownload == true) {
        await _downloadAndInstall(context, entry.key, entry.value.url);
      }
      return;
    }

    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Обновление ${info.version}'),
        children: variants.entries.map((e) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, e.key),
          child: Text('${e.key} (${_formatSize(e.value.size)})'),
        )).toList(),
      ),
    );
    if (chosen != null) {
      await _downloadAndInstall(context, chosen, variants[chosen]!.url);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'неизвестно';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} МБ';
  }

  Future<void> _downloadAndInstall(BuildContext context, String variantName, String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getApplicationDocumentsDirectory();
        }
      } else {
        final downloads = await _platform.getDownloadsDirectory();
        if (variantName.contains('OTA')) {
          saveDir = await getTemporaryDirectory();
        } else {
          saveDir = downloads ?? await getApplicationDocumentsDirectory();
        }
      }

      final fileName = _getFileNameForPlatform(url, variantName);
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      Navigator.pop(context); // hide progress

      if (variantName.contains('OTA') && !Platform.isAndroid) {
        await _handleOtaUpdate(context, file.path);
      } else {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            _showError(context, 'Не удалось открыть файл. Он сохранён в ${file.path}');
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Файл сохранён: ${file.path}')),
            );
          }
        }
      }
    } catch (e, stack) {
      await _logger.error('Update download failed', error: e, stack: stack);
      Navigator.pop(context);
      if (context.mounted) _showError(context, 'Ошибка при загрузке обновления');
    }
  }

  Future<void> _handleOtaUpdate(BuildContext context, String archivePath) async {
    // TODO: Реализовать реальный механизм OTA с внешним updater'ом.
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('OTA-обновление почти готово'),
          content: const Text(
            'Архив сохранён.\nПри следующем перезапуске обновление будет применено (требуется отдельный апдейтер).',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  String _getFileNameForPlatform(String url, String variantName) {
    if (Platform.isAndroid) return 'Rizz_update.apk';
    if (Platform.isWindows) return variantName.contains('OTA') ? 'Rizz_OTA_patch.zip' : 'Rizz_Setup.exe';
    if (Platform.isLinux) {
      if (variantName.contains('DEB')) return 'rizz.deb';
      if (variantName.contains('RPM')) return 'rizz.rpm';
      if (variantName.contains('OTA')) return 'rizz-ota.tar.gz';
      return 'rizz-bin.tar.gz';
    }
    if (Platform.isMacOS) return variantName.contains('OTA') ? 'Rizz_OTA.zip' : 'Rizz.pkg';
    return 'Rizz_update';
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
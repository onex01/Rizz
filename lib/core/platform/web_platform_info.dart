import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'platform_info.dart';

class WebPlatformInfo implements PlatformInfo {
  @override
  Future<dynamic> getApplicationDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }

  @override
  Future<dynamic> getDownloadsDirectory() async => null;

  @override
  Future<dynamic> getTemporaryDirectory() async {
    return await path_provider.getTemporaryDirectory();
  }

  @override
  Future<bool> requestInstallPermission() async => true;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<void> openFile(String path) async {
    // На вебе открываем в новой вкладке, если это HTTP-ссылка
    // Для локальных файлов не поддерживается
    throw UnsupportedError('openFile not implemented on web');
  }

  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => false;
  @override
  bool get isWeb => true;
  @override
  String get operatingSystem => 'web';
}
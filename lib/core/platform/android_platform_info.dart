import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'platform_info.dart';

class AndroidPlatformInfo implements PlatformInfo {
  static const _installChannel = MethodChannel('com.dualproj.rizz/install_permission');

  @override
  Future<Directory> getApplicationDocumentsDirectory() => getApplicationDocumentsDirectory();

  @override
  Future<Directory?> getDownloadsDirectory() async {
    final dir = Directory('/storage/emulated/0/Download');
    if (await dir.exists()) return dir;
    return null;
  }

  @override
  Future<Directory> getTemporaryDirectory() => getTemporaryDirectory();

  @override
  Future<bool> requestInstallPermission() async {
    if (await Permission.requestInstallPackages.isGranted) return true;
    return await Permission.requestInstallPackages.request().isGranted;
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await _installChannel.invokeMethod('openAppSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openFile(String path) => OpenFile.open(path);

  @override
  bool get isMobile => true;
  @override
  bool get isDesktop => false;
  @override
  bool get isWeb => false;
  @override
  String get operatingSystem => 'android';
}
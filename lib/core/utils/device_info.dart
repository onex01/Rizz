import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfo {
  static Future<Map<String, dynamic>> gather() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    
    final Map<String, dynamic> info = {
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'platform': Platform.operatingSystem,
      'is_physical_device': !kIsWeb && (Platform.isAndroid || Platform.isIOS) ? await _isPhysicalDevice(deviceInfo) : null,
    };

    if (kIsWeb) {
      info['web_browser'] = _getWebBrowser();
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      info['device_model'] = android.model;
      info['manufacturer'] = android.manufacturer;
      info['os_version'] = android.version.release;
      info['sdk_int'] = android.version.sdkInt;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      info['device_model'] = ios.model;
      info['system_name'] = ios.systemName;
      info['os_version'] = ios.systemVersion;
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      info['computer_name'] = windows.computerName;
      info['os_version'] = windows.releaseId;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      info['os_version'] = linux.versionId;
    } else if (Platform.isMacOS) {
      final mac = await deviceInfo.macOsInfo;
      info['os_version'] = mac.osRelease;
    }

    return info;
  }

  static Future<bool> _isPhysicalDevice(DeviceInfoPlugin deviceInfo) async {
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return android.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.isPhysicalDevice;
      }
    } catch (_) {}
    return true; // предполагаем, что физическое
  }

  static String _getWebBrowser() {
    // В вебе сложно определить браузер точно, можно через userAgent
    return 'Web';
  }
}
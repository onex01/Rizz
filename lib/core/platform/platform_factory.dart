import 'dart:io';
import 'package:flutter/foundation.dart';
import 'platform_info.dart';
import 'android_platform_info.dart';
import 'windows_platform_info.dart';
import 'web_platform_info.dart';

PlatformInfo getPlatformInfo() {
  if (kIsWeb) return WebPlatformInfo();
  if (Platform.isAndroid) return AndroidPlatformInfo();
  if (Platform.isIOS) return IOSPlatformInfo();
  if (Platform.isWindows) return WindowsPlatformInfo();
  if (Platform.isLinux) return LinuxPlatformInfo();
  if (Platform.isMacOS) return MacOSPlatformInfo();
  throw UnsupportedError('Unsupported platform');
}

class IOSPlatformInfo extends AndroidPlatformInfo {
  @override String get operatingSystem => 'ios';
}

class LinuxPlatformInfo extends WindowsPlatformInfo {
  @override String get operatingSystem => 'linux';
}

class MacOSPlatformInfo extends WindowsPlatformInfo {
  @override String get operatingSystem => 'macos';
}
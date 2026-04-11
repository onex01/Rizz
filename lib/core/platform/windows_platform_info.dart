import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'platform_info.dart';

class WindowsPlatformInfo implements PlatformInfo {
  @override
  Future<Directory> getApplicationDocumentsDirectory() => getApplicationDocumentsDirectory();

  @override
  Future<Directory?> getDownloadsDirectory() async {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null) return null;
    final downloads = Directory('$userProfile\\Downloads');
    if (await downloads.exists()) return downloads;
    return null;
  }

  @override
  Future<Directory> getTemporaryDirectory() => getTemporaryDirectory();

  @override
  Future<bool> requestInstallPermission() async => true;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<void> openFile(String path) => OpenFile.open(path);

  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => true;
  @override
  bool get isWeb => false;
  @override
  String get operatingSystem => 'windows';
}
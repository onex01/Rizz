
abstract class PlatformInfo {
  Future<dynamic> getApplicationDocumentsDirectory();
  Future<dynamic> getDownloadsDirectory();
  Future<dynamic> getTemporaryDirectory();
  Future<bool> requestInstallPermission();
  Future<bool> openAppSettings();
  Future<void> openFile(String path);
  bool get isMobile;
  bool get isDesktop;
  bool get isWeb;
  String get operatingSystem;
}
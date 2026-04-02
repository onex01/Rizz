import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_converter_service.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  static const String _nicknamePrefix = 'user_nickname_';
  static const String _photoPrefix = 'user_photo_';
  static const String _avatarHexPrefix = 'avatar_hex_';
  static const String _avatarTimestampPrefix = 'avatar_ts_';

  Future<void> cacheUser(String uid, String? nickname, String? photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (nickname != null) {
      await prefs.setString('$_nicknamePrefix$uid', nickname);
    }
    if (photoUrl != null) {
      await prefs.setString('$_photoPrefix$uid', photoUrl);
    }
  }

  Future<void> cacheAvatarHex(String uid, String hexData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarHexPrefix$uid', hexData);
    await prefs.setInt('$_avatarTimestampPrefix$uid', DateTime.now().millisecondsSinceEpoch);
    // Сохраняем также как файл
    final file = await FileConverterService.hexToFile(hexData, 'avatar_$uid.jpg');
    final tempDir = Directory.systemTemp;
    final savedFile = File('${tempDir.path}/avatar_$uid.jpg');
    await file.copy(savedFile.path);
  }

  Future<File?> getAvatarFile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final hex = prefs.getString('$_avatarHexPrefix$uid');
    if (hex != null) {
      return await FileConverterService.hexToFile(hex, 'avatar_$uid.jpg');
    }
    return null;
  }

  Future<bool> isAvatarOutdated(String uid, int serverTimestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTs = prefs.getInt('$_avatarTimestampPrefix$uid') ?? 0;
    return serverTimestamp > cachedTs;
  }

  String? getNickname(String uid) {
    try {
      final prefs = SharedPreferences.getInstance() as SharedPreferences;
      return prefs.getString('$_nicknamePrefix$uid');
    } catch (_) {
      return null;
    }
  }

  String? getPhotoUrl(String uid) {
    try {
      final prefs = SharedPreferences.getInstance() as SharedPreferences;
      return prefs.getString('$_photoPrefix$uid');
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_nicknamePrefix) || key.startsWith(_photoPrefix) ||
          key.startsWith(_avatarHexPrefix) || key.startsWith(_avatarTimestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
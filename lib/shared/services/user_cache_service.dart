import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_converter_service.dart';

class UserCacheService {
  static const String _nicknamePrefix = 'user_nickname_';
  static const String _usernamePrefix = 'user_username_';
  static const String _photoPrefix = 'user_photo_';
  static const String _avatarHexPrefix = 'avatar_hex_';

  Future<void> cacheUser(String uid, String? nickname, String? photoUrl, [String? username]) async {
    final prefs = await SharedPreferences.getInstance();
    if (nickname != null) await prefs.setString('$_nicknamePrefix$uid', nickname);
    if (username != null) await prefs.setString('$_usernamePrefix$uid', username);
    if (photoUrl != null) await prefs.setString('$_photoPrefix$uid', photoUrl);
  }

  Future<void> cacheAvatarHex(String uid, String hexData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarHexPrefix$uid', hexData);
  }

  String? getNickname(String uid) {
    final prefs = SharedPreferences.getInstance() as SharedPreferences;
    return prefs.getString('$_nicknamePrefix$uid');
  }

  String? getUsername(String uid) {
    final prefs = SharedPreferences.getInstance() as SharedPreferences;
    return prefs.getString('$_usernamePrefix$uid');
  }

  String? getPhotoUrl(String uid) {
    final prefs = SharedPreferences.getInstance() as SharedPreferences;
    return prefs.getString('$_photoPrefix$uid');
  }

  String? getAvatarHex(String uid) {
    final prefs = SharedPreferences.getInstance() as SharedPreferences;
    return prefs.getString('$_avatarHexPrefix$uid');
  }

  Future<File?> getAvatarFile(String uid) async {
    final hex = getAvatarHex(uid);
    if (hex == null) return null;
    return await FileConverterService.hexToFile(hex, 'avatar_$uid.jpg');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_nicknamePrefix) || key.startsWith(_avatarHexPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> invalidateUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_nicknamePrefix$uid');
    await prefs.remove('$_avatarHexPrefix$uid');
  }
}
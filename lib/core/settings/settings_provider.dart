import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatBackgroundType { color, gradient, image, procedural }

class SettingsProvider extends ChangeNotifier {
  String? _wallpaperUrl;
  double _fontSize = 16.0;
  Color _accentColor = Colors.blue;
  int _cacheSize = 100;
  Color? _chatBackgroundColor;
  bool _showAvatars = true;
  bool _sendByEnter = false;

  bool _useProceduralBackground = false;
  bool get useProceduralBackground => _useProceduralBackground;

  String? get wallpaperUrl => _wallpaperUrl;
  double get fontSize => _fontSize;
  Color get accentColor => _accentColor;
  int get cacheSize => _cacheSize;
  Color? get chatBackgroundColor => _chatBackgroundColor;
  bool get showAvatars => _showAvatars;
  bool get sendByEnter => _sendByEnter;

  ChatBackgroundType _chatBgType = ChatBackgroundType.procedural;
  Color? _chatSolidColor;
  Color? _chatGradientColor1;
  Color? _chatGradientColor2;
  String? _chatImagePath;

  ChatBackgroundType get chatBgType => _chatBgType;
  Color? get chatSolidColor => _chatSolidColor;
  Color? get chatGradientColor1 => _chatGradientColor1;
  Color? get chatGradientColor2 => _chatGradientColor2;
  String? get chatImagePath => _chatImagePath;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.toARGB32());
    _cacheSize = prefs.getInt('cacheSize') ?? 100;
    _wallpaperUrl = prefs.getString('wallpaperUrl');
    _useProceduralBackground = prefs.getBool('useProceduralBackground') ?? false;
    final bgColorValue = prefs.getInt('chatBackgroundColor');
    if (bgColorValue != null) _chatBackgroundColor = Color(bgColorValue);
    _showAvatars = prefs.getBool('showAvatars') ?? true;
    _sendByEnter = prefs.getBool('sendByEnter') ?? (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS));
    final bgTypeIndex = prefs.getInt('chatBgType') ?? 3; // procedural по умолчанию
    _chatBgType = ChatBackgroundType.values[bgTypeIndex];
    final solidColor = prefs.getInt('chatSolidColor');
    if (solidColor != null) _chatSolidColor = Color(solidColor);
    final gradColor1 = prefs.getInt('chatGradientColor1');
    if (gradColor1 != null) _chatGradientColor1 = Color(gradColor1);
    final gradColor2 = prefs.getInt('chatGradientColor2');
    if (gradColor2 != null) _chatGradientColor2 = Color(gradColor2);
    _chatImagePath = prefs.getString('chatImagePath');
    notifyListeners();
  }

  Future<void> setChatBackgroundType(ChatBackgroundType type) async {
    _chatBgType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatBgType', type.index);
    notifyListeners();
  }

  Future<void> setChatSolidColor(Color color) async {
    _chatSolidColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatSolidColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setChatGradientColors(Color color1, Color color2) async {
    _chatGradientColor1 = color1;
    _chatGradientColor2 = color2;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatGradientColor1', color1.toARGB32());
    await prefs.setInt('chatGradientColor2', color2.toARGB32());
    notifyListeners();
  }

  Future<void> setChatImagePath(String? path) async {
    _chatImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('chatImagePath', path);
    } else {
      await prefs.remove('chatImagePath');
    }
    notifyListeners();
  }

  Future<void> setWallpaper(String? url) async {
    _wallpaperUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('wallpaperUrl', url);
    } else {
      await prefs.remove('wallpaperUrl');
    }
    notifyListeners();
  }

  Future<void> setChatBackgroundColor(Color? color) async {
    _chatBackgroundColor = color;
    final prefs = await SharedPreferences.getInstance();
    if (color != null) {
      await prefs.setInt('chatBackgroundColor', color.toARGB32());
    } else {
      await prefs.remove('chatBackgroundColor');
    }
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setCacheSize(int size) async {
    _cacheSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cacheSize', size);
    notifyListeners();
  }

  Future<void> setShowAvatars(bool value) async {
    _showAvatars = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showAvatars', value);
    notifyListeners();
  }

  Future<void> setSendByEnter(bool value) async {
    _sendByEnter = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendByEnter', value);
    notifyListeners();
  }

  Future<void> setUseProceduralBackground(bool value) async {
    _useProceduralBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useProceduralBackground', value);
    notifyListeners();
  }
}
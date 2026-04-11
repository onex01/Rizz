import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String? _wallpaperUrl;
  double _fontSize = 16.0;
  Color _accentColor = Colors.blue;
  int _cacheSize = 100; // MB
  Color? _chatBackgroundColor;

  String? get wallpaperUrl => _wallpaperUrl;
  double get fontSize => _fontSize;
  Color get accentColor => _accentColor;
  int get cacheSize => _cacheSize;
  Color? get chatBackgroundColor => _chatBackgroundColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.toARGB32());
    _cacheSize = prefs.getInt('cacheSize') ?? 100;
    _wallpaperUrl = prefs.getString('wallpaperUrl');
    int? bgColorValue = prefs.getInt('chatBackgroundColor');
    if (bgColorValue != null) {
      _chatBackgroundColor = Color(bgColorValue);
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
}
import 'package:dynamic_icon_changer/dynamic_icon_changer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconService {
  static final _iconChanger = DynamicIconChanger();

  /// Все алиасы в манифесте (должны совпадать с android:name)
  static const List<String> _allAliases = [
    'MainActivityDefault',
    'MainActivityBlack',
    'MainActivityDark',
    'MainActivityWhite',
    'MainActivityBlackWhite',
    'MainActivityBrize',
    'MainActivityIngYang',
  ];

  /// Ключ для SharedPreferences
  static const String _prefsKey = 'app_icon_alias';

  /// Установить иконку по ключу (например, 'MainActivityBlack').
  /// Если переданный alias ещё не активирован, деактивирует все остальные.
  static Future<void> setIcon(String alias) async {
    if (!_allAliases.contains(alias)) {
      throw ArgumentError('Неизвестный alias: $alias');
    }
    // Устанавливаем иконку, передавая только этот алиас как активный
    await _iconChanger.setIcon(
      null, // iOS icon name – не используется
      androidActiveAliases: [alias],
      relaunch: true,
    );
    // Сохраняем выбор
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, alias);
  }

  /// Получить текущий сохранённый alias (по умолчанию MainActivityDefault)
  static Future<String> getCurrentAlias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? 'MainActivityDefault';
  }
}
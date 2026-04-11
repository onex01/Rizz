import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/settings/settings_provider.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/cache_service.dart';
import '../../../shared/services/update_service.dart';
import '../../../version.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _firestoreService = GetIt.I<FirestoreService>();
  final _cache = GetIt.I<MessageFileCache>();
  final _logger = GetIt.I<AppLogger>();
  final _updateService = GetIt.I<UpdateService>();

  String _appVersion = AppVersion.version;
  String _buildNumber = AppVersion.buildNumber.toString();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await _updateService.checkForUpdates();
    if (updateInfo != null && mounted) {
      await _updateService.showUpdateDialog(context, updateInfo);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас последняя версия приложения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isLight ? Colors.grey.shade50 : const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Настройки'),
            centerTitle: false,
            elevation: 0,
            backgroundColor: isLight ? Colors.white : null,
            foregroundColor: isLight ? Colors.black : null,
            floating: false,
            pinned: true,
            snap: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileSection(isLight),
                const Divider(height: 1),
                _buildAppearanceSection(settingsProvider, themeProvider, isLight),
                const Divider(height: 1),
                _buildChatSection(isLight),
                const Divider(height: 1),
                _buildCacheSection(isLight),
                const Divider(height: 1),
                _buildUpdateSection(isLight),
                const Divider(height: 1),
                _buildAboutSection(isLight),
                const Divider(height: 1),
                _buildLogoutSection(isLight),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isLight) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getUser(_currentUser.uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final nickname = data?['nickname'] ?? _currentUser.email?.split('@')[0];
        final photoUrl = data?['photoUrl'];
        return ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
          ),
          title: Text(
            nickname ?? 'Пользователь',
            style: TextStyle(fontWeight: FontWeight.w500, color: isLight ? Colors.black87 : Colors.white),
          ),
          subtitle: Text(
            _currentUser.email ?? '',
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          },
        );
      },
    );
  }

  Widget _buildAppearanceSection(SettingsProvider settings, ThemeProvider theme, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Внешний вид',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        ListTile(
          leading: Icon(Icons.brightness_6, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Тема', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            _getThemeModeName(theme.themeMode),
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemePicker(theme),
        ),
        ListTile(
          leading: Icon(Icons.color_lens, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Акцентный цвет', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            _getColorName(settings.accentColor),
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          trailing: Container(width: 24, height: 24, decoration: BoxDecoration(color: settings.accentColor, shape: BoxShape.circle)),
          onTap: () => _showColorPicker(settings),
        ),
        ListTile(
          leading: Icon(Icons.text_fields, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Размер шрифта', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            '${settings.fontSize.toStringAsFixed(0)} pt',
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFontSizePicker(settings),
        ),
        ListTile(
          leading: Icon(Icons.wallpaper, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Обои чата', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showWallpaperPicker(settings),
        ),
        ListTile(
          leading: Icon(Icons.format_color_fill, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Цвет фона чата', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: settings.chatBackgroundColor ?? (isLight ? Colors.white : Colors.black),
              shape: BoxShape.circle,
              border: Border.all(color: isLight ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
          onTap: () => _showChatBackgroundColorPicker(settings, isLight),
        ),
      ],
    );
  }

  Widget _buildChatSection(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Чаты',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        SwitchListTile(
          title: Text('Показывать аватарки', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          value: true,
          onChanged: (value) {},
        ),
        SwitchListTile(
          title: Text('Отправка по Enter', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          value: true,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildCacheSection(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Кэш',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        ListTile(
          leading: Icon(Icons.storage, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Кэш сообщений', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            '${_cache.size} файлов в памяти',
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showCacheOptions(),
        ),
      ],
    );
  }

  Widget _buildUpdateSection(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Обновления',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        ListTile(
          leading: Icon(Icons.update, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Проверить обновления', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            'Текущая версия: $_appVersion ($_buildNumber)',
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _checkForUpdates,
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'О приложении',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        ListTile(
          leading: Icon(Icons.info, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Версия', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          subtitle: Text(
            '$_appVersion ($_buildNumber)',
            style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
          ),
          onTap: () => _showAboutDialog(),
        ),
        ListTile(
          leading: Icon(Icons.bug_report, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          title: Text('Логи приложения', style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LogViewerScreen()));
          },
        ),
        AboutSection(isLight: isLight),
      ],
    );
  }

  Widget _buildLogoutSection(bool isLight) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: () => _showLogoutDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Выйти из аккаунта'),
        ),
      ),
    );
  }

  // ... (методы диалогов: _showThemePicker, _showColorPicker, _showFontSizePicker, _showWallpaperPicker, _showChatBackgroundColorPicker, _showCacheOptions, _showAboutDialog, _showLogoutDialog)
  // Они полностью копируются из исходного settings_screen.dart, с заменой вызовов на Provider и GetIt.
  // Приведу только сигнатуры, реализацию можно скопировать из старого файла.

  void _showThemePicker(ThemeProvider theme) { /* как в исходнике */ }
  void _showColorPicker(SettingsProvider settings) { /* ... */ }
  void _showFontSizePicker(SettingsProvider settings) { /* ... */ }
  void _showWallpaperPicker(SettingsProvider settings) { /* ... */ }
  void _showChatBackgroundColorPicker(SettingsProvider settings, bool isLight) { /* ... */ }
  void _showCacheOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Кэш сообщений'),
        content: Text('В кэше сейчас: ${_cache.size} файлов\n\nОчистить кэш сообщений?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              _cache.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кэш сообщений очищен')));
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() { /* ... */ }
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Светлая';
      case ThemeMode.dark: return 'Тёмная';
      case ThemeMode.system: return 'Системная';
    }
  }

  String _getColorName(Color color) {
    if (color == Colors.blue) return 'Синий';
    if (color == Colors.green) return 'Зелёный';
    if (color == Colors.red) return 'Красный';
    if (color == Colors.purple) return 'Фиолетовый';
    if (color == Colors.orange) return 'Оранжевый';
    if (color == Colors.teal) return 'Бирюзовый';
    if (color == Colors.pink) return 'Розовый';
    if (color == Colors.indigo) return 'Индиго';
    if (color == Colors.white) return 'Белый';
    if (color == Colors.black) return 'Чёрный';
    return 'Кастомный';
  }
}

// Виджет AboutSection (можно оставить как был)
class AboutSection extends StatelessWidget {
  final bool isLight;
  const AboutSection({super.key, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.grey.shade50 : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? Colors.grey.shade200 : Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.blue),
          const SizedBox(height: 12),
          Text('Rizz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isLight ? Colors.black87 : Colors.white)),
          const SizedBox(height: 8),
          Text('Мессенджер с открытым исходным кодом', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isLight ? Colors.grey.shade600 : Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Сделано командой © 2026 Duality Project', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isLight ? Colors.grey.shade500 : Colors.grey.shade500)),
        ],
      ),
    );
  }
}
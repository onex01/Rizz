import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String? nickname;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          nickname = doc['nickname'] ?? currentUser.email?.split('@')[0] ?? 'User';
          photoUrl = doc['photoUrl'];
        });
      }
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
    }
  }

  void _showAppearanceSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Внешний вид'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              themeProvider.setTheme(ThemeMode.light);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тема изменена на Светлую')),
              );
            },
            child: const Text('Светлая'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              themeProvider.setTheme(ThemeMode.dark);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тема изменена на Тёмную')),
              );
            },
            child: const Text('Тёмная'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              themeProvider.setTheme(ThemeMode.system);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тема изменена на системную')),
              );
            },
            child: const Text('Как в системе'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('ChatiX'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text(
              'Современный мессенджер в стиле iOS\n'
              'Быстрые сообщения, отправка фото, заметки,\n'
              'реакции и красивые анимации.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel),
            ),
            SizedBox(height: 16),
            Text(
              'Версия 1.0.0',
              style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Исправленный Top Bar — теперь всегда в цвет фона (тёмный в тёмной теме)
          CupertinoSliverNavigationBar(
            backgroundColor: isLight
                ? CupertinoColors.systemGrey6
                : const Color(0xFF1C1C1E), // точно как в Telegram
            largeTitle: Text(
              'Настройки',
              style: TextStyle(
                color: isLight ? CupertinoColors.black : CupertinoColors.white,
              ),
            ),
            trailing: Text(
              'Edit',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ==================== ПРОФИЛЬ ====================
                GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(CupertinoIcons.person_fill, size: 60)
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Убраны жёлтые подчёркивания
                      SelectionContainer.disabled(
                        child: Text(
                          nickname ?? 'Пользователь',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Убраны жёлтые подчёркивания
                      SelectionContainer.disabled(
                        child: Text(
                          currentUser.email ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Смена фото — в разработке')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Change Profile Photo',
                            style: TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // ==================== СПИСОК НАСТРОЕК ====================
                CupertinoListSection.insetGrouped(
                  backgroundColor: isLight ? CupertinoColors.systemGrey6 : const Color(0xFF1C1C1E),
                  children: [
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.heart_fill, color: CupertinoColors.systemRed),
                      title: const Text('My Stories'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.bookmark_fill, color: CupertinoColors.systemBlue),
                      title: const Text('Saved Messages'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.phone_fill, color: CupertinoColors.systemGreen),
                      title: const Text('Recent Calls'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.device_phone_portrait, color: CupertinoColors.systemOrange),
                      title: const Text('Devices'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.folder_fill, color: CupertinoColors.systemPurple),
                      title: const Text('Chat Folders'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  backgroundColor: isLight ? CupertinoColors.systemGrey6 : const Color(0xFF1C1C1E),
                  children: [
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.bell_fill, color: CupertinoColors.systemRed),
                      title: const Text('Notifications and Sounds'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemBlue),
                      title: const Text('Privacy and Security'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.cloud_fill, color: CupertinoColors.systemGreen),
                      title: const Text('Data and Storage'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.paintbrush_fill, color: CupertinoColors.systemIndigo),
                      title: const Text('Appearance'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: _showAppearanceSheet,
                    ),
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  backgroundColor: isLight ? CupertinoColors.systemGrey6 : const Color(0xFF1C1C1E),
                  children: [
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.question_circle_fill, color: CupertinoColors.systemGrey),
                      title: const Text('Ask a Question'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      leading: const Icon(CupertinoIcons.info_circle_fill, color: CupertinoColors.systemGrey),
                      title: const Text('About ChatiX'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: _showAboutSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:ui';

import 'package:ChatiX/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/chat_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  String _searchQuery = '';

  // Контроллеры для поиска — чтобы клавиатура не выскакивала автоматически
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Гарантируем, что поиск неактивен при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
       ),

      body: Stack(
        children: [
          // Основное содержимое
          Column(
            children: [
              // iOS-стиль поиск (по умолчанию НЕ в фокусе)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  placeholder: 'Поиск пользователей',
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ),

              // Переключаем контент в зависимости от поиска
              Expanded(
                child: _searchQuery.isEmpty
                    ? ChatList(
                        currentUserId: currentUser.uid,
                        searchQuery: '',
                      )
                    : _buildUserSearchResults(),
              ),
            ],
          ),

          // ==================== ОБНОВЛЁННЫЙ LIQUID GLASS DOCK BAR ====================
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Кнопка «Чаты»
                        _buildDockButton(
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          label: 'Чаты',
                          onTap: _clearSearch, // сбрасываем поиск и возвращаемся к списку чатов
                        ),
                        const SizedBox(width: 32),

                        // Кнопка «Настройки»
                        _buildDockButton(
                          icon: CupertinoIcons.gear_solid,
                          label: 'Настройки',
                          // Внутри _buildDockButton для «Настройки»
                        onTap: () {
                           _searchFocusNode.unfocus();
                          Navigator.push(
                             context,
                            CupertinoPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        ),
                        const SizedBox(width: 32),

                        // Кнопка «Профиль»
                        _buildDockButton(
                          icon: CupertinoIcons.person_fill,
                          label: 'Профиль',
                          onTap: () {
                            _searchFocusNode.unfocus();
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Красивая кнопка для Dock Bar (iOS-стиль)
  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Результаты поиска пользователей ====================
  Widget _buildUserSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: _searchQuery)
          .where('nickname', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 70, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Пользователь «$_searchQuery» не найден',
                  style: const TextStyle(fontSize: 17, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final nickname = userData['nickname'] ?? 'Без имени';
            final photoUrl = userData['photoUrl'];

            if (userId == currentUser.uid) {
              return const SizedBox.shrink(); // себя не показываем
            }

            return CupertinoListTile(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(CupertinoIcons.person_fill, size: 32)
                    : null,
              ),
              title: Text(
                nickname,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                userId.substring(0, 8) + '...',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              onTap: () {
                _searchFocusNode.unfocus(); // убираем клавиатуру перед переходом
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => UserProfileScreen(userId: userId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
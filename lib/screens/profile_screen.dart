import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _nicknameController.text = doc['nickname'] ?? '';
        _bioController.text = doc['bio'] ?? '';
        _photoUrl = doc['photoUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return CupertinoPageScaffold(
      backgroundColor: isLight ? CupertinoColors.systemGrey6 : const Color(0xFF1C1C1E),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isLight ? CupertinoColors.systemGrey6 : const Color(0xFF1C1C1E),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.chevron_back, size: 28),
        ),
        middle: const Text('Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          child: const Text(
            'Edit',
            style: TextStyle(
              color: CupertinoColors.activeBlue,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Большой аватар с кнопкой камеры
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: isLight ? CupertinoColors.systemGrey5 : CupertinoColors.systemGrey2,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                      child: _photoUrl == null
                          ? Icon(
                              CupertinoIcons.person_fill,
                              size: 90,
                              color: isLight ? CupertinoColors.systemGrey : CupertinoColors.white,
                            )
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Смена фото — в разработке')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLight ? CupertinoColors.white : const Color(0xFF1C1C1E),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        color: CupertinoColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Имя (без жёлтых выделений)
              SelectionContainer.disabled(
                child: Text(
                  _nicknameController.text.isNotEmpty ? _nicknameController.text : 'Your Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Подзаголовок
              SelectionContainer.disabled(
                child: Text(
                  'last seen recently',
                  style: TextStyle(
                    fontSize: 16,
                    color: isLight ? CupertinoColors.secondaryLabel : const Color(0xFF8E8E93),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Панель действий (Audio / Video / Message / Info)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(CupertinoIcons.phone_fill, 'Audio'),
                    _actionButton(CupertinoIcons.videocam_fill, 'Video'),
                    _actionButton(CupertinoIcons.chat_bubble_fill, 'Message'),
                    _actionButton(CupertinoIcons.info_circle_fill, 'Info'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Bio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLight ? CupertinoColors.systemGrey6 : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SelectionContainer.disabled(
                    child: Text(
                      _bioController.text.isNotEmpty ? _bioController.text : "Hi, I'm Valdes. This is my bio.",
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLight ? CupertinoColors.systemGrey6 : CupertinoColors.systemGrey5,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 32,
            color: CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isLight ? CupertinoColors.secondaryLabel : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
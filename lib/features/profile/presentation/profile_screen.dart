import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/storage_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _firestoreService = GetIt.I<FirestoreService>();
  final _storageService = GetIt.I<StorageService>();
  final _logger = GetIt.I<AppLogger>();

  String? _nickname;
  String? _photoUrl;
  String? _phoneNumber;
  String? _bio;
  bool _isLoading = true;
  int _contactsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkContactsPermission();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestoreService.getUser(_user.uid);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nickname = data['nickname'] ?? _user.email?.split('@')[0];
          _photoUrl = data['photoUrl'];
          _phoneNumber = data['phoneNumber'];
          _bio = data['bio'] ?? 'Привет! Я использую Rizz';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      _logger.error('Error loading profile', e, stack);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkContactsPermission() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (hasPermission) await _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
      setState(() => _contactsCount = contacts.length);
      await _findUsersFromContacts(contacts);
    } catch (e) {
      _logger.error('Error loading contacts', e);
    }
  }

  Future<void> _findUsersFromContacts(List<Contact> contacts) async {
    final phones = <String>[];
    for (var c in contacts) {
      for (var phone in c.phones) {
        if (phone.number.isNotEmpty) {
          String normalized = phone.number.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll(RegExp(r'^\+?7'), '7');
          phones.add(normalized);
        }
      }
    }
    if (phones.isEmpty) return;
    final uniquePhones = phones.toSet().toList();

    try {
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', whereIn: uniquePhones.take(10).toList())
          .get();
      if (usersQuery.docs.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Найдено ${usersQuery.docs.length} друзей в Rizz!'),
            action: SnackBarAction(label: 'Показать', onPressed: () => _showFoundUsers(usersQuery.docs)),
          ),
        );
      }
    } catch (e) {
      _logger.error('Error finding users from contacts', e);
    }
  }

  void _showFoundUsers(List<QueryDocumentSnapshot> users) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final data = users[index].data() as Map<String, dynamic>;
          final userId = users[index].id;
          final nickname = data['nickname'] ?? 'Пользователь';
          final photoUrl = data['photoUrl'];
          return ListTile(
            leading: CircleAvatar(backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null, child: photoUrl == null ? const Icon(Icons.person) : null),
            title: Text(nickname),
            subtitle: Text(userId),
            onTap: () {
              Navigator.pop(context);
              // TODO: открыть чат
            },
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final url = await _storageService.uploadAvatar(_user.uid, File(picked.path));
      await _firestoreService.updateUser(_user.uid, {'photoUrl': url});
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото профиля обновлено')));
    } catch (e) {
      _logger.error('Avatar upload failed', e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка загрузки фото')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      await _loadContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Доступ к контактам необходим для поиска друзей')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Colors.grey.shade50 : const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isLight ? Colors.white : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => _loadProfile()),
            child: const Text('Редактировать', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null ? Icon(Icons.person, size: 60, color: isLight ? Colors.grey : Colors.grey.shade400) : null,
                        ),
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: isLight ? Colors.white : const Color(0xFF0F0F0F), width: 3),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_nickname ?? 'Пользователь', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isLight ? Colors.black : Colors.white)),
                  const SizedBox(height: 4),
                  Text(_user.email ?? '', style: TextStyle(fontSize: 14, color: isLight ? Colors.grey.shade600 : Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.circle, color: Colors.green, size: 8), SizedBox(width: 4), Text('В сети', style: TextStyle(color: Colors.green, fontSize: 12))],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_bio != null && _bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        elevation: 0,
                        color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_bio!, style: TextStyle(fontSize: 15, color: isLight ? Colors.black87 : Colors.white70), textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.phone, 'Телефон', _phoneNumber ?? 'Не указан', onTap: _phoneNumber == null ? _addPhoneNumber : null, isLight: isLight),
                        Divider(height: 1, color: isLight ? Colors.grey.shade200 : Colors.grey.shade800),
                        _buildInfoTile(Icons.people, 'Контакты', '$_contactsCount контактов', onTap: _contactsCount == 0 ? _requestContactsPermission : null, isLight: isLight),
                        Divider(height: 1, color: isLight ? Colors.grey.shade200 : Colors.grey.shade800),
                        _buildInfoTile(Icons.qr_code, 'QR-код', 'Мой QR-код', onTap: () {}, isLight: isLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {VoidCallback? onTap, required bool isLight}) {
    return ListTile(
      leading: Icon(icon, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
      title: Text(title, style: TextStyle(color: isLight ? Colors.black87 : Colors.white70)),
      subtitle: Text(value, style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500)),
      trailing: onTap != null ? const Icon(Icons.add, size: 20) : null,
      onTap: onTap,
    );
  }

  Future<void> _addPhoneNumber() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить номер телефона'),
        content: TextField(controller: controller, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+7 XXX XXX XX XX', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isNotEmpty) {
                await _firestoreService.updateUser(_user.uid, {'phoneNumber': phone});
                setState(() => _phoneNumber = phone);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Номер телефона добавлен')));
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
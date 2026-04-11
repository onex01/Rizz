import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _firestoreService = GetIt.I<FirestoreService>();
  final _storageService = GetIt.I<StorageService>();
  final _logger = GetIt.I<AppLogger>();

  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _photoUrl;
  bool _saving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestoreService.getUser(_user.uid);
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _photoUrl = data['photoUrl'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.error('Error loading profile', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();
    final phone = _phoneController.text.trim();

    if (nickname.isEmpty) {
      Fluttertoast.showToast(msg: "Никнейм не может быть пустым");
      return;
    }

    setState(() => _saving = true);
    try {
      final updates = {'nickname': nickname, 'bio': bio};
      if (phone.isNotEmpty) updates['phoneNumber'] = phone;
      await _firestoreService.updateUser(_user.uid, updates);
      Fluttertoast.showToast(msg: "Профиль успешно обновлён");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка сохранения профиля: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final url = await _storageService.uploadAvatar(_user.uid, File(picked.path));
      await _firestoreService.updateUser(_user.uid, {'photoUrl': url});
      setState(() => _photoUrl = url);
      Fluttertoast.showToast(msg: "Фото обновлено");
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка загрузки фото");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton(onPressed: _saving ? null : _saveProfile, child: const Text('Сохранить', style: TextStyle(fontSize: 17, color: Colors.blue))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null ? Icon(Icons.person, size: 70, color: isLight ? Colors.grey : Colors.grey.shade400) : null,
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
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Никнейм',
                      hintText: 'Введите ваш никнейм',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      hintText: '+7 XXX XXX XX XX',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'О себе',
                      hintText: 'Расскажите о себе...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_saving) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
    );
  }
}
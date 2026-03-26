import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _nicknameController = TextEditingController();

  String? _photoUrl;
  bool _saving = false;

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
        _photoUrl = doc['photoUrl'];
      });
    }
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim().toLowerCase();
    if (nickname.isEmpty) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': nickname,
      });
      Fluttertoast.showToast(msg: "Никнейм сохранён");
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка сохранения никнейма");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);

    if (pickedFile == null) return;

    setState(() => _saving = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      await ref.putFile(File(pickedFile.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': url,
      });

      if (mounted) setState(() => _photoUrl = url);
      Fluttertoast.showToast(msg: "Аватарка обновлена");
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка загрузки аватарки");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null ? const Icon(Icons.camera_alt, size: 50) : null,
              ),
            ),
            const SizedBox(height: 12),
            const Text("Нажмите на аватарку для смены", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Никнейм',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveNickname,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить никнейм'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
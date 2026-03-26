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
    if (doc.exists) {
      setState(() {
        _nicknameController.text = doc['nickname'] ?? '';
        _photoUrl = doc['photoUrl'];
      });
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim().toLowerCase();
    if (nickname.isEmpty) return;

    setState(() => _saving = true);

    try {
      // Проверка уникальности никнейма
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (existing.docs.isNotEmpty && existing.docs.first.id != user.uid) {
        Fluttertoast.showToast(msg: "Никнейм уже занят");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': nickname,
      });

      Fluttertoast.showToast(msg: "Никнейм сохранён");
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка сохранения");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _saving = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'photoUrl': url,
      });

      setState(() => _photoUrl = url);
      Fluttertoast.showToast(msg: "Аватарка обновлена");
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка загрузки аватарки");
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null ? const Icon(Icons.camera_alt, size: 50) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Никнейм',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
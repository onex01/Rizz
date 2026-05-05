import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../shared/services/firestore_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../../core/notification/universal_toast.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (_nicknameController.text.trim().isEmpty) {
      showToast(context, 'Введите имя', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await GetIt.I<FirestoreService>().updateUser(user.uid, {
        'nickname': _nicknameController.text.trim(),
      });
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (mounted) showToast(context, 'Ошибка сохранения', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка профиля')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: 'Ваше имя', hintText: 'Введите отображаемое имя'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Продолжить')),
            TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())), child: const Text('Пропустить')),
          ],
        ),
      ),
    );
  }
}
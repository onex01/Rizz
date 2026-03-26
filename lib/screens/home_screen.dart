import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';   // ← добавим дальше

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatiX'),
        actions: [
          // Поиск
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          // Профиль
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // Выход
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Пока нет чатов\nНажмите на лупу или "Заметки"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final participants = chatData['participants'] as List;
              final otherUserId = participants.firstWhere((id) => id != currentUser.uid);

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(otherUserId),
                subtitle: Text(chatData['lastMessage'] ?? ''),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chats[index].id,
                      otherUserId: otherUserId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSelfChat,
        child: const Icon(Icons.note_alt),
        tooltip: 'Заметки (чат с собой)',
      ),
    );
  }

  // Создание чата с самим собой (Заметки)
  Future<void> _createSelfChat() async {
    final chatId = '${currentUser.uid}_self';

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser.uid],
      'lastMessage': 'Заметки',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isSelfChat': true,
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, otherUserId: currentUser.uid),
        ),
      );
    }
  }

  void _showSearchDialog(BuildContext context) { /* твой предыдущий код поиска */ }
}
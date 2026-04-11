import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/firestore_service.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _firestoreService = GetIt.I<FirestoreService>();
  final _logger = GetIt.I<AppLogger>();

  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await _firestoreService.getUser(_currentUser.uid);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final friendIds = List<String>.from(data['friends'] ?? []);
        if (friendIds.isNotEmpty) {
          final friendsData = <Map<String, dynamic>>[];
          for (var id in friendIds) {
            final friendDoc = await _firestoreService.getUser(id);
            if (friendDoc.exists) {
              final friendData = friendDoc.data() as Map<String, dynamic>;
              friendsData.add({
                'uid': id,
                'nickname': friendData['nickname'] ?? 'Пользователь',
                'photoUrl': friendData['photoUrl'],
                'isOnline': friendData['isOnline'] ?? false,
                'lastSeen': friendData['lastSeen']?.toDate(),
              });
            }
          }
          setState(() {
            _friends = friendsData;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stack) {
      _logger.error('Error loading friends', e, stack);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(String userId, String nickname) async {
    final chatId = [_currentUser.uid, userId]..sort();
    final chatDocId = '${chatId[0]}_${chatId[1]}';
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatDocId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [_currentUser.uid, userId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatDocId, otherUserId: userId),
        ),
      );
    }
  }

  String _getLastSeenText(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'В сети';
    if (lastSeen == null) return 'Был(а) недавно';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return 'Был(а) только что';
    if (diff.inHours < 1) return 'Был(а) ${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return 'Был(а) ${diff.inHours} ч назад';
    if (diff.inDays < 7) return 'Был(а) ${diff.inDays} дн назад';
    return 'Был(а) ${lastSeen.day}.${lastSeen.month}.${lastSeen.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Colors.grey.shade50 : const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Контакты'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isLight ? Colors.white : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _loadFriends,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: isLight ? Colors.grey.shade400 : Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'Нет друзей',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: isLight ? Colors.grey.shade600 : Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавляйте друзей через их профиль',
                        style: TextStyle(color: isLight ? Colors.grey.shade500 : Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final isOnline = friend['isOnline'] ?? false;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 0,
                      color: isLight ? Colors.white : const Color(0xFF1C1C1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isLight ? Colors.grey.shade200 : Colors.grey.shade800),
                      ),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: friend['photoUrl'] != null
                                  ? CachedNetworkImageProvider(friend['photoUrl'])
                                  : null,
                              child: friend['photoUrl'] == null
                                  ? Icon(Icons.person, size: 32, color: isLight ? Colors.grey : Colors.grey.shade400)
                                  : null,
                            ),
                            if (isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isLight ? Colors.white : const Color(0xFF1C1C1E), width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(friend['nickname'] ?? 'Пользователь', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          _getLastSeenText(friend['lastSeen'], isOnline),
                          style: TextStyle(fontSize: 13, color: isOnline ? Colors.green : (isLight ? Colors.grey.shade600 : Colors.grey.shade500)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.person_outline, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: friend['uid']))),
                              tooltip: 'Профиль',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.blue),
                              onPressed: () => _startChat(friend['uid'], friend['nickname']),
                              tooltip: 'Написать',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
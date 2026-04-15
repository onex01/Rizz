import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/user_cache_service.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';

class ChatList extends StatefulWidget {
  final String currentUserId;
  final String searchQuery;
  final ScrollController? scrollController;

  const ChatList({
    super.key,
    required this.currentUserId,
    required this.searchQuery,
    this.scrollController,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final _firestoreService = GetIt.I<FirestoreService>();
  final _userCache = GetIt.I<UserCacheService>();
  final _logger = GetIt.I<AppLogger>();

  final Map<String, String> _userNicknames = {};
  final Map<String, String> _userUsernames = {};
  final Map<String, String> _userPhotoUrls = {};

  @override
  void initState() {
    super.initState();
    _ensureSelfNotesChatExists();
    _preloadAllChatUsers();
  }

  Future<void> _ensureSelfNotesChatExists() async {
    final selfChatId = '${widget.currentUserId}_self';
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(selfChatId).get();
      if (!chatDoc.exists) {
        await FirebaseFirestore.instance.collection('chats').doc(selfChatId).set({
          'participants': [widget.currentUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isSelfChat': true,
        });
      }
    } catch (e, stack) {
      _logger.error('Error ensuring self chat exists', error: e, stack: stack);
    }
  }

  Future<void> _preloadAllChatUsers() async {
    final snapshot = await _firestoreService.getChats(widget.currentUserId).first;
    await _loadUserInfoIfNeeded(snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getChats(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _userNicknames.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('Пока нет чатов', style: TextStyle(fontSize: 18)),
                Text('Найдите пользователя через поиск', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final chats = snapshot.data!.docs;
        List<QueryDocumentSnapshot> sortedChats = List.from(chats);
        sortedChats.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aPinned = aData['pinned'] ?? false;
          final bPinned = bData['pinned'] ?? false;
          if (aPinned != bPinned) return aPinned ? -1 : 1;
          final aTime = (aData['lastMessageTime'] as Timestamp?)?.seconds ?? 0;
          final bTime = (bData['lastMessageTime'] as Timestamp?)?.seconds ?? 0;
          return bTime.compareTo(aTime);
        });

        _loadUserInfoIfNeeded(sortedChats);

        final filteredChats = sortedChats.where((doc) {
          if (widget.searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => widget.currentUserId,
          );
          final displayName = _userNicknames[otherUserId] ?? otherUserId;
          return displayName.toLowerCase().contains(widget.searchQuery.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final doc = filteredChats[index];
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != widget.currentUserId,
              orElse: () => widget.currentUserId,
            );
            final isSelfChat = data['isSelfChat'] == true;
            final displayName = isSelfChat ? 'Заметки' :
              (_userUsernames[otherUserId] != null && _userUsernames[otherUserId]!.isNotEmpty 
                ? '@${_userUsernames[otherUserId]}' 
                : _userNicknames[otherUserId] ?? otherUserId);
            final photoUrl = _userPhotoUrls[otherUserId];
            final isPinned = data['pinned'] ?? false;
            final lastMessage = data['lastMessage'] ?? 'Нет сообщений';

            return CupertinoContextMenu.builder(
              actions: _buildContextMenuActions(doc, otherUserId, isSelfChat, isPinned),
              builder: (context, animation) {
                final scale = 1.0 + (animation.value * 0.025);
                final lift = -6.0 * animation.value;

                return Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: 12 * animation.value,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? (isSelfChat ? const Icon(Icons.note_alt, size: 28) : const Icon(Icons.person, size: 28))
                              : null,
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        trailing: isPinned ? const Icon(Icons.push_pin, size: 20, color: Colors.blueAccent) : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => ChatScreen(chatId: doc.id, otherUserId: otherUserId)),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _buildContextMenuActions(QueryDocumentSnapshot doc, String otherUserId, bool isSelfChat, bool isPinned) {
    final data = doc.data() as Map<String, dynamic>;
    final isMuted = data['isMuted'] ?? false;

    return [
      CupertinoContextMenuAction(
        trailingIcon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        onPressed: () {
          Navigator.pop(context);
          _togglePin(doc);
        },
        child: Text(isPinned ? 'Открепить' : 'Закрепить'),
      ),
      CupertinoContextMenuAction(
        trailingIcon: isMuted ? Icons.notifications : Icons.notifications_off,
        onPressed: () {
          Navigator.pop(context);
          _toggleMute(doc);
        },
        child: Text(isMuted ? 'Включить уведомления' : 'Заглушить'),
      ),
      CupertinoContextMenuAction(
        trailingIcon: Icons.mark_chat_unread_outlined,
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отмечено как непрочитанное')));
        },
        child: const Text('Пометить как непрочитанное'),
      ),
      if (!isSelfChat)
        CupertinoContextMenuAction(
          trailingIcon: Icons.person_outline,
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, CupertinoPageRoute(builder: (_) => UserProfileScreen(userId: otherUserId)));
          },
          child: const Text('Открыть профиль'),
        ),
      CupertinoContextMenuAction(
        trailingIcon: Icons.search,
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поиск в чате (скоро)')));
        },
        child: const Text('Поиск в чате'),
      ),
      CupertinoContextMenuAction(
        trailingIcon: Icons.archive_outlined,
        onPressed: () {
          Navigator.pop(context);
          _archiveChat(doc);
        },
        child: const Text('Архивировать'),
      ),
      CupertinoContextMenuAction(
        isDestructiveAction: true,
        trailingIcon: Icons.delete_forever,
        onPressed: () {
          Navigator.pop(context);
          _deleteChat(doc);
        },
        child: const Text('Удалить чат'),
      ),
    ];
  }

  Future<void> _deleteChat(QueryDocumentSnapshot doc) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить чат?'),
        content: const Text('Будут удалены все сообщения. Это действие нельзя отменить.'),
        actions: [
          CupertinoDialogAction(child: const Text('Отмена'), onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Удалить навсегда'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final chatRef = doc.reference;
      final messagesSnapshot = await chatRef.collection('messages').get();
      final batch = FirebaseFirestore.instance.batch();
      for (var msg in messagesSnapshot.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(chatRef);
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Чат и все сообщения удалены')));
      }
    } catch (e) {
      _logger.error('Error deleting chat', error: e);
    }
  }

  Future<void> _togglePin(QueryDocumentSnapshot doc) async {
    final isPinned = (doc.data() as Map<String, dynamic>)['pinned'] ?? false;
    await doc.reference.update({'pinned': !isPinned, if (!isPinned) 'pinnedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _toggleMute(QueryDocumentSnapshot doc) async {
    final isMuted = (doc.data() as Map<String, dynamic>)['isMuted'] ?? false;
    await doc.reference.update({'isMuted': !isMuted});
  }

  Future<void> _archiveChat(QueryDocumentSnapshot doc) async {
    await doc.reference.update({'isArchived': true});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Чат архивирован')));
  }

  Future<void> _loadUserInfoIfNeeded(List<QueryDocumentSnapshot> chats) async {
    final Set<String> uidsToLoad = {};
    for (var doc in chats) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      for (var uid in participants) {
        if (uid != widget.currentUserId && !_userNicknames.containsKey(uid)) {
          uidsToLoad.add(uid);
        }
      }
    }
    if (uidsToLoad.isEmpty) return;

    // Сначала пробуем кэш
    for (var uid in uidsToLoad) {
      final cachedNick = _userCache.getNickname(uid);
      final cachedUsername = _userCache.getUsername(uid);
      final cachedPhoto = _userCache.getPhotoUrl(uid);
      if (cachedNick != null) _userNicknames[uid] = cachedNick;
      if (cachedUsername != null) _userUsernames[uid] = cachedUsername;
      if (cachedPhoto != null) _userPhotoUrls[uid] = cachedPhoto;
    }

    // Загружаем недостающие из Firestore
    final uidsToFetch = uidsToLoad.where((uid) => !_userNicknames.containsKey(uid)).toList();
    if (uidsToFetch.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uidsToFetch)
          .get();
      for (var doc in snapshot.docs) {
        final nickname = doc['nickname'] ?? doc.id;
        final username = doc['username'] ?? '';
        final photoUrl = doc['photoUrl'] ?? '';
        _userNicknames[doc.id] = nickname;
        _userUsernames[doc.id] = username;
        _userPhotoUrls[doc.id] = photoUrl;
        await _userCache.cacheUser(doc.id, nickname, photoUrl, username);
      }
      if (mounted) setState(() {});
    } catch (e) {
      _logger.error('Error loading user info for chat list', error: e);
    }
  }
}
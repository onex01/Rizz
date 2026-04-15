import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/settings/settings_provider.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/circle_video_service.dart';
import '../../../shared/services/voice_service.dart';
import '../../../shared/services/chunked_file_service.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';
import '../widgets/message_list.dart';
import '../widgets/chat_background.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Инжектированные зависимости
  final _chatRepository = GetIt.I<ChatRepository>();
  final _firestoreService = GetIt.I<FirestoreService>();
  final _storageService = GetIt.I<StorageService>();
  final _platformInfo = GetIt.I<PlatformInfo>();
  final _logger = GetIt.I<AppLogger>();
  final _chunkedFileService = GetIt.I<ChunkedFileService>();

  String? _otherUserNickname;
  String? _otherUserPhotoUrl;
  bool? _isOnlineInChat;
  DateTime? _lastSeen;
  bool _isTyping = false;
  StreamSubscription? _chatStatusSubscription;

  String? _replyingToId;
  String? _replyingToText;

  @override
  void initState() {
    super.initState();
    _loadOtherUserInfo();
    _setupRealTimeChatStatus();
    _joinChat();
  }

  Future<void> _loadOtherUserInfo() async {
    if (widget.otherUserId == _currentUser.uid) {
      setState(() => _otherUserNickname = 'Заметки');
      return;
    }

    try {
      final doc = await _firestoreService.getUser(widget.otherUserId);
      if (!doc.exists || !mounted) return;

      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _otherUserNickname = data['nickname'] ?? widget.otherUserId;
        _otherUserPhotoUrl = data['photoUrl'];
      });
    } catch (e, stack) {
      _logger.error('Failed to load other user info', error: e, stack: stack);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _markMessagesAsRead());
  }

  void _setupRealTimeChatStatus() {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    _chatStatusSubscription = chatRef.snapshots().listen((snapshot) {
      if (!mounted || !snapshot.exists) return;
      final data = snapshot.data()!;
      final onlineUsers = List<String>.from(data['onlineUsers'] ?? []);
      final typingUsers = List<String>.from(data['typingUsers'] ?? []);
      setState(() {
        _isOnlineInChat = onlineUsers.contains(widget.otherUserId);
        _isTyping = typingUsers.contains(widget.otherUserId);
        _lastSeen = data['lastSeen']?.toDate();
      });
    });
  }

  Future<void> _joinChat() async {
    await _firestoreService.updateChat(widget.chatId, {
      'onlineUsers': FieldValue.arrayUnion([_currentUser.uid]),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _leaveChat() async {
    await _firestoreService.updateChat(widget.chatId, {
      'onlineUsers': FieldValue.arrayRemove([_currentUser.uid]),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _updateTypingStatus() {
    if (widget.otherUserId == _currentUser.uid) return;
    final hasText = _messageController.text.trim().isNotEmpty;
    _firestoreService.updateChat(widget.chatId, {
      'typingUsers': hasText
          ? FieldValue.arrayUnion([_currentUser.uid])
          : FieldValue.arrayRemove([_currentUser.uid])
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (widget.otherUserId == _currentUser.uid) return;
    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');
      final unread = await messagesRef
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, stack) {
      _logger.error('Failed to mark messages as read', error: e, stack: stack);
    }
  }

  // ==================== ОТПРАВКА СООБЩЕНИЙ ====================
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Сбрасываем статус печати
    await _firestoreService.updateChat(widget.chatId, {
      'typingUsers': FieldValue.arrayRemove([_currentUser.uid])
    });

    final message = Message(
      id: '',
      senderId: _currentUser.uid,
      text: text,
      timestamp: Timestamp.now(),
      replyToMessageId: _replyingToId,
      repliedMessageText: _replyingToText,
    );

    await _chatRepository.sendMessage(widget.chatId, message);
    _messageController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToText = null;
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;

    await _sendMediaMessage(
      file: File(picked.path),
      type: 'image_hex',
      previewText: '📷 Фото',
    );
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.first.path!);
    await _sendMediaMessage(
      file: file,
      type: 'file_hex',
      previewText: '📎 ${file.path.split('/').last}',
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;

    await _sendMediaMessage(
      file: File(picked.path),
      type: 'image_hex',
      previewText: '📷 Фото',
    );
  }

  Future<void> _sendMediaMessage({
    required File file,
    required String type,
    required String previewText,
  }) async {
    try {
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last;

      // Проверка размера: если > 500 KB, используем чанки
      if (fileSize > 500 * 1024) {
        await _sendLargeFile(file, fileName, fileSize, previewText);
        return;
      }

      final bytes = await file.readAsBytes();
      final hexData = _bytesToHex(bytes);

      final mediaData = {
        'hexData': hexData,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileExtension': fileExtension,
      };

      final message = Message(
        id: '',
        senderId: _currentUser.uid,
        text: '',
        timestamp: Timestamp.now(),
        replyToMessageId: _replyingToId,
        repliedMessageText: _replyingToText,
        type: type,
        mediaData: mediaData,
      );

      await _chatRepository.sendMessage(widget.chatId, message);
      await _chatRepository.updateLastMessage(widget.chatId, previewText, type);
      setState(() {
        _replyingToId = null;
        _replyingToText = null;
      });
      _scrollToBottom();
    } catch (e, stack) {
      _logger.error('Failed to send media message', error: e, stack: stack);
      _showToast('Ошибка отправки файла');
    }
  }

  Future<void> _sendLargeFile(File file, String fileName, int fileSize, String previewText) async {
    try {
      final bytes = await file.readAsBytes();
      final fileId = await _chunkedFileService.uploadLargeFile(bytes, fileName);

      final mediaData = {
        'largeFileId': fileId,
        'fileName': fileName,
        'fileSize': fileSize,
      };

      final message = Message(
        id: '',
        senderId: _currentUser.uid,
        text: '',
        timestamp: Timestamp.now(),
        replyToMessageId: _replyingToId,
        repliedMessageText: _replyingToText,
        type: 'large_file',
        mediaData: mediaData,
      );

      await _chatRepository.sendMessage(widget.chatId, message);
      await _chatRepository.updateLastMessage(widget.chatId, '📁 $fileName', 'large_file');
      setState(() {
        _replyingToId = null;
        _replyingToText = null;
      });
      _scrollToBottom();
    } catch (e, stack) {
      _logger.error('Failed to send large file', error: e, stack: stack);
      _showToast('Ошибка отправки большого файла');
    }
  }

  // Вспомогательная функция для конвертации байт в hex
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ==================== ГОЛОСОВЫЕ И ВИДЕОКРУЖКИ ====================
  Future<void> _startVoiceRecording() async {
    await VoiceService.startRecording();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceRecorderDialog(
        onSend: (File file) async {
          // Отправка голосового через hex
          await _sendMediaMessage(
            file: file,
            type: 'voice',
            previewText: '🎤 Голосовое',
          );
        },
      ),
    );
  }

  Future<void> _startCircleVideoRecording() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CircleRecorderOverlay()),
    );
    if (result is File) {
      await CircleVideoService.sendRecordedCircle(widget.chatId, result, replyToId: _replyingToId);
      setState(() => _replyingToId = null);
    }
  }

  // ==================== ДЕЙСТВИЯ С СООБЩЕНИЯМИ ====================
  void _handleReply(String messageId, String text) {
    setState(() {
      _replyingToId = messageId;
      _replyingToText = text;
    });
  }

  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Текст скопирован')));
  }

  Future<void> _handleEdit(String messageId, String oldText) async {
    final controller = TextEditingController(text: oldText);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить сообщение'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Сохранить')),
        ],
      ),
    );
    if (newText == null || newText.isEmpty || newText == oldText) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'isEdited': true, 'editedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _handleDelete(String messageId, {required bool forEveryone}) async {
    if (forEveryone) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }

  void _handleForward() {
    _showToast('Переслать — в разработке');
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToText = null;
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getStatusText() {
    if (_isTyping) return 'печатает...';
    if (_isOnlineInChat == true) return 'В сети';
    if (_lastSeen == null) return 'Был(а) недавно';
    final diff = DateTime.now().difference(_lastSeen!);
    if (diff.inMinutes < 1) return 'Был(а) недавно';
    if (diff.inHours < 1) return 'Был(а) ${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return 'Был(а) ${diff.inHours} ч назад';
    if (diff.inDays < 7) return 'Был(а) ${diff.inDays} дн назад';
    return 'Был(а) ${_lastSeen!.day}.${_lastSeen!.month}.${_lastSeen!.year}';
  }

  void _showAttachmentMenu() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isLight ? Colors.grey.shade300 : Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: const Icon(Icons.photo_library, color: Colors.blue)),
              title: const Text('Фото из галереи'),
              onTap: () { Navigator.pop(context); _sendImage(); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.1), child: const Icon(Icons.insert_drive_file, color: Colors.green)),
              title: const Text('Файл'),
              onTap: () { Navigator.pop(context); _sendFile(); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.1), child: const Icon(Icons.camera_alt, color: Colors.purple)),
              title: const Text('Снять фото'),
              onTap: () { Navigator.pop(context); _takePhoto(); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.mic, color: Colors.red)),
              title: const Text('Голосовое сообщение'),
              onTap: () { Navigator.pop(context); _startVoiceRecording(); },
            ),
            // ListTile(
            //   leading: CircleAvatar(backgroundColor: Colors.pink.withValues(alpha: 0.1), child: const Icon(Icons.videocam_rounded, color: Colors.pink)),
            //   title: const Text('Видеокружок'),
            //   onTap: () { Navigator.pop(context); _startCircleVideoRecording(); },
            // ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _leaveChat();
    _chatStatusSubscription?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _otherUserNickname ?? widget.otherUserId;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final settings = Provider.of<SettingsProvider>(context);
    final bgColor = settings.chatBackgroundColor ?? (isLight ? Colors.white : Colors.black);
    final accentColor = settings.accentColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : null,
        foregroundColor: isLight ? Colors.black : null,
        title: GestureDetector(
          onTap: () {
            if (widget.otherUserId != _currentUser.uid) {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => UserProfileScreen(userId: widget.otherUserId)),
              );
            }
          },
          child: Row(
            children: [
              if (_otherUserPhotoUrl != null || widget.otherUserId == _currentUser.uid)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: _otherUserPhotoUrl != null ? NetworkImage(_otherUserPhotoUrl!) : null,
                  child: _otherUserPhotoUrl == null && widget.otherUserId != _currentUser.uid
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: TextStyle(color: isLight ? Colors.black : null, fontWeight: FontWeight.w600)),
                  if (widget.otherUserId != _currentUser.uid)
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTyping ? Colors.green : (_isOnlineInChat == true ? Colors.green : Colors.grey),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        centerTitle: false,
      ),
      body: ChatBackground(
        backgroundColor: bgColor,
        wallpaperUrl: settings.wallpaperUrl,
        enableEffects: settings.useProceduralBackground,
        // gradientStart: settings.gradientStartColor,
        // gradientEnd: settings.gradientEndColor,
        child: Column(
          children: [
            Expanded(
              child: MessageList(
                chatId: widget.chatId,
                currentUserId: _currentUser.uid,
                scrollController: _scrollController,
                onReplySwipe: _handleReply,
                onReply: _handleReply,
                onCopy: _handleCopy,
                onEdit: _handleEdit,
                onDeleteMe: (id) => _handleDelete(id, forEveryone: false),
                onDeleteAll: (id) => _handleDelete(id, forEveryone: true),
                onForward: _handleForward,
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
              decoration: BoxDecoration(
                color: isLight ? CupertinoColors.systemGrey6 : Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_replyingToId != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, color: accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ответ на сообщение', style: TextStyle(color: accentColor, fontSize: 12)),
                                Text(
                                  _replyingToText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: isLight ? Colors.black87 : Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: _cancelReply),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _showAttachmentMenu,
                        child: Icon(CupertinoIcons.paperclip, color: isLight ? CupertinoColors.systemGrey : Colors.grey, size: 28),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _messageController,
                          placeholder: 'Сообщение...',
                          placeholderStyle: TextStyle(color: isLight ? CupertinoColors.systemGrey : Colors.grey),
                          style: TextStyle(color: isLight ? CupertinoColors.black : Colors.white, fontSize: 17),
                          decoration: const BoxDecoration(),
                          maxLines: null,
                          minLines: 1,
                          keyboardAppearance: isLight ? Brightness.light : Brightness.dark,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => _updateTypingStatus(),
                          onSubmitted: (_) {
                            if (settings.sendByEnter) {
                              _sendMessage();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        onLongPress: _startVoiceRecording,
                        child: Icon(Icons.mic, color: isLight ? CupertinoColors.systemGrey : Colors.grey, size: 28),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: hasText ? _sendMessage : null,
                            child: Icon(
                              CupertinoIcons.arrow_up_circle_fill,
                              color: hasText ? accentColor : (isLight ? CupertinoColors.systemGrey3 : Colors.grey),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
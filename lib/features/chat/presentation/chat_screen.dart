import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:Rizz/shared/services/audio_player_service.dart';
import 'package:Rizz/shared/services/file_converter_service.dart';
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
import '../../../core/settings/settings_provider.dart';
import '../../../shared/services/firestore_service.dart'; 
import '../../../shared/services/voice_service.dart';
import '../../../shared/services/chunked_file_service.dart';
import '../../profile/presentation/user_profile_screen.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';
import '../widgets/message_list.dart';
import '../widgets/chat_background.dart';
import '../widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();
  File? _otherUserAvatarFile;

  // Инжектированные зависимости
  final _audioPlayerService = GetIt.I<AudioPlayerService>();
  final _chatRepository = GetIt.I<ChatRepository>();
  final _firestoreService = GetIt.I<FirestoreService>();
  final _logger = GetIt.I<AppLogger>(); 
  final _chunkedFileService = GetIt.I<ChunkedFileService>();

  String? _otherUserNickname;
  bool? _isOnlineInChat; 
  DateTime? _lastSeen;
  bool _isTyping = false;
  StreamSubscription? _chatStatusSubscription;

  String? _replyingToId;
  String? _replyingToText;
  bool _showScrollToBottom = false;
  String? _otherPinnedSongTitle;
  String? _otherPinnedSongArtist;
  String? _otherPinnedSongDuration;
  String? _otherPinnedSongLargeFileId;

  // === ГЛОБАЛЬНЫЙ ПЛЕЕР ===
  bool _isPlayerVisible = false;
  String? _nowPlayingTitle;
  String? _nowPlayingArtist;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _loadOtherUserInfo();
    _setupRealTimeChatStatus();
    _joinChat();

    _audioPlayerService.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _audioPlayerService.positionStream.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _audioPlayerService.durationStream.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur ?? Duration.zero);
    });
    _audioPlayerService.currentTitleStream.listen((title) {
      if (mounted) setState(() => _nowPlayingTitle = title);
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
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
      final pinnedSong = data['pinnedSong'] as Map<String, dynamic>? ?? {};
      final avatarHex = data['avatarHex'] as String?;

      File? avatarFile;
      if (avatarHex != null && avatarHex.isNotEmpty) {
        try {
          avatarFile = await FileConverterService.hexToFile(
            avatarHex,
            'avatar_${widget.otherUserId}.jpg',
          );
          if (await avatarFile.length() == 0) {
            await avatarFile.delete();
            avatarFile = null;
          }
        } catch (e, stack) {
          _logger.error('Failed to convert avatar hex to file', error: e, stack: stack);
          avatarFile = null;
        }
      }

      setState(() {
        _otherUserNickname = data['nickname'] ?? widget.otherUserId;
        _otherUserAvatarFile = avatarFile;
        _otherPinnedSongTitle = pinnedSong['title'];
        _otherPinnedSongArtist = pinnedSong['artist'];
        _otherPinnedSongDuration = pinnedSong['duration'] ?? '3:45';
        _otherPinnedSongLargeFileId = pinnedSong['largeFileId'];
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
  void _playSendAnimation(String text, Color bubbleColor) {
    final renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final offset = renderBox.localToGlobal(Offset.zero);
    final width = renderBox.size.width;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          onEnd: () => entry.remove(),
          builder: (context, value, child) {
            return Positioned(
              left: offset.dx + 40,
              top: offset.dy - (value * 120),
              width: width * 0.75,
              child: Opacity(
                opacity: 1.0 - value,
                child: Transform.scale(
                  scale: 1.0 - (value * 0.1),
                  child: Material(
                    color: Colors.transparent,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white, fontSize: 17),
                          maxLines: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    Overlay.of(context).insert(entry);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
 
    await _firestoreService.updateChat(widget.chatId, {
      'typingUsers': FieldValue.arrayRemove([_currentUser.uid])
    });

    HapticFeedback.lightImpact();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
     
    _playSendAnimation(text, settings.accentColor);

    final message = Message(
      id: '',
      senderId: _currentUser.uid,
      text: text,
      timestamp: Timestamp.now(),
      replyToMessageId: _replyingToId,
      repliedMessageText: _replyingToText,
    );
 
    _messageController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToText = null;
    });

    await _chatRepository.sendMessage(widget.chatId, message);
    await _chatRepository.updateLastMessage(widget.chatId, text, 'text');

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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _sendFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles();
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

  Future<void> _playOtherUserSong() async {
    if (_otherPinnedSongLargeFileId == null) {
      _showToast('Песня пока не доступна');
      return;
    }

    setState(() {
      _nowPlayingTitle = _otherPinnedSongTitle;
      _nowPlayingArtist = _otherPinnedSongArtist;
      _isPlayerVisible = true;
      _isPlaying = true;
    });

    try {
      // 1. Скачиваем все HEX-чанки из Firestore
      final bytes = await _chunkedFileService.downloadLargeFile(_otherPinnedSongLargeFileId!);

      // 2. Сохраняем во временный файл
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/pinned_song_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(bytes, flush: true);

      // 3. Воспроизводим через нативный Android-плеер (just_audio)
      await _audioPlayerService.playVoice(
        tempFile.path,
        title: _otherPinnedSongTitle ?? 'Песня',
      );
    } catch (e, stack) {
      _logger.error('Failed to play pinned song from HEX chunks', error: e, stack: stack);
      _showToast('Ошибка загрузки трека');
      setState(() => _isPlayerVisible = false);
    }
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
 
  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _startVoiceRecording() async {
    await VoiceService.startRecording();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceRecorderDialog(
        onSend: (File file) async { 
          await _sendMediaMessage(
            file: file,
            type: 'voice',
            previewText: '🎤 Голосовое',
          );
        },
      ),
    );
  }

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: isLight ? Colors.white.withOpacity(0.95) : Colors.black.withOpacity(0.95),
            child: SafeArea(
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
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
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
      extendBodyBehindAppBar: true,
      // ЕСТЕСТВЕННЫЙ ПОДЪЁМ ВСЕГО КОНТЕНТА (сообщения + input + player + кнопка вниз)
      // при открытии клавиатуры. Дополнительный ручной подъём через viewInsets.bottom УБРАН.
      // Лаги клавиатуры устранены за счёт RepaintBoundary вокруг всех BackdropFilter.
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      
      // ==================== БЛЮР TOP-BAR ====================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: AppBar(
              backgroundColor: isLight
                  ? Colors.white.withOpacity(0.65)
                  : Colors.black.withOpacity(0.65),
              foregroundColor: isLight ? Colors.black : Colors.white,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  color: isLight ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                  height: 0.5,
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  if (widget.otherUserId != _currentUser.uid) {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => UserProfileScreen(userId: widget.otherUserId)));
                  }
                },
                child: Row(
                  children: [
                    if (_otherUserAvatarFile != null || widget.otherUserId == _currentUser.uid)
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: _otherUserAvatarFile != null
                            ? FileImage(_otherUserAvatarFile!)
                            : null,
                        child: _otherUserAvatarFile == null && widget.otherUserId != _currentUser.uid
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                        if (widget.otherUserId != _currentUser.uid)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _getStatusText(),
                              key: ValueKey(_isTyping),
                              style: TextStyle(
                                fontSize: 13,
                                color: _isTyping ? accentColor : (_isOnlineInChat == true ? accentColor : Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              centerTitle: false,
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // 1. Фон и Сообщения
          ChatBackground(
            backgroundColor: bgColor,
            wallpaperUrl: settings.wallpaperUrl,
            enableEffects: settings.useProceduralBackground,
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
 
          // ==================== БЛЮР-Виджет музыки собеседника ====================
          if (_otherPinnedSongTitle != null && _otherPinnedSongTitle!.isNotEmpty)
            Positioned(
              top: kToolbarHeight + 60,
              left: 16,
              right: 16,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.white.withOpacity(0.65)
                            : Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _playOtherUserSong,
                        child: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.deepPurple, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_otherPinnedSongTitle!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(_otherPinnedSongArtist ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Text(_otherPinnedSongDuration ?? '', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            const Icon(Icons.play_arrow_rounded, color: Colors.deepPurple),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 2. Плавающая кнопка "Вниз"
          Positioned(
            bottom: 72,
            right: 16,
            child: AnimatedScale(
              scale: _showScrollToBottom ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: RepaintBoundary(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isLight 
                                  ? Colors.white.withOpacity(0.4) 
                                  : Colors.grey[800]!.withOpacity(0.4)),
                          border: Border.all(
                            color: (isLight ? Colors.white : Colors.white10).withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 30,
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. ПЛАВАЮЩЕЕ ПОЛЕ ВВОДА (ChatInputBar)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: ChatInputBar(
              replyingToText: _replyingToText,
              onCancelReply: _cancelReply,
              onAttachmentPressed: _showAttachmentMenu,
              onSend: _sendMessage,
              onVoiceRecording: _startVoiceRecording,
              controller: _messageController,
              accentColor: accentColor,
              textFieldKey: _textFieldKey,
              onChanged: _updateTypingStatus,
              onSubmitted: settings.sendByEnter ? () => _sendMessage() : null,
            ),
          ),

          // ==================== ГЛОБАЛЬНЫЙ ПЛЕЕР ====================
          if (_isPlayerVisible)
            Positioned(
              bottom: 88,
              left: 16,
              right: 16,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLight 
                            ? Colors.white.withOpacity(0.92)
                            : const Color(0xFF1C1C1D).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [ 
                          Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.deepPurple, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nowPlayingTitle ?? 'Сейчас играет',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_nowPlayingArtist != null)
                                      Text(
                                        _nowPlayingArtist!,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                           color: Colors.deepPurple),
                                onPressed: () async {
                                  if (_isPlaying) {
                                    await _audioPlayerService.pause();
                                  } else {
                                    await _audioPlayerService.resume();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 22),
                                onPressed: () {
                                  _audioPlayerService.stop();
                                  setState(() => _isPlayerVisible = false);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
 
                          Row(
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  ),
                                  child: Slider(
                                    value: _currentPosition.inMilliseconds.toDouble().clamp(
                                          0,
                                          (_totalDuration.inMilliseconds > 0 
                                              ? _totalDuration.inMilliseconds 
                                              : 1).toDouble(),
                                        ),
                                    max: _totalDuration.inMilliseconds.toDouble() > 0 
                                        ? _totalDuration.inMilliseconds.toDouble() 
                                        : 1,
                                    activeColor: Colors.deepPurple,
                                    inactiveColor: Colors.grey.withOpacity(0.3),
                                    onChanged: (value) {
                                      _audioPlayerService.seek(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
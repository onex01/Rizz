import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/file_converter_service.dart';
import '../../../shared/services/chunked_file_service.dart';
import '../../../shared/services/audio_player_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _firestoreService = GetIt.I<FirestoreService>();
  final _chunkedFileService = GetIt.I<ChunkedFileService>();
  final _audioPlayerService = GetIt.I<AudioPlayerService>();
  final _logger = GetIt.I<AppLogger>();

  String? _nickname;
  String? _avatarHex;
  String? _phoneNumber;
  String? _bio;
  bool _isLoading = true;

  // Данные закреплённой песни
  String? _pinnedSongTitle;
  String? _pinnedSongArtist;
  String? _pinnedSongLargeFileId;   // ← Добавлено

  bool _isPlayingPinnedSong = false;

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
        final pinnedSong = data['pinnedSong'] as Map<String, dynamic>? ?? {};

        setState(() {
          _nickname = data['nickname'] ?? _user.email?.split('@')[0];
          _avatarHex = data['avatarHex'];
          _phoneNumber = data['phoneNumber'];
          _bio = data['bio'] ?? 'Привет! Я использую Rizz';

          _pinnedSongTitle = pinnedSong['title'];
          _pinnedSongArtist = pinnedSong['artist'];
          _pinnedSongLargeFileId = pinnedSong['largeFileId'];

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.error('Error loading profile', error: e);
      setState(() => _isLoading = false);
    }
  }

  // ==================== ВОСПРОИЗВЕДЕНИЕ ЗАКРЕПЛЁННОЙ ПЕСНИ =================== 
Future<void> _playPinnedSong() async {
  if (_pinnedSongLargeFileId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Музыка ещё не загружена')),
    );
    return;
  }

  setState(() => _isPlayingPinnedSong = true);

  try {
    final bytes = await _chunkedFileService.downloadLargeFile(_pinnedSongLargeFileId!);
    if (bytes.isEmpty) throw Exception("Файл пуст");

    final tempDir = await getTemporaryDirectory();

    // Берём оригинальное имя файла из Firestore (если есть) или делаем надёжное имя
    final safeFileName = '${DateTime.now().millisecondsSinceEpoch}_pinned_song.mp3';
    final tempPath = '${tempDir.path}/$safeFileName';
    final tempFile = File(tempPath);

    await tempFile.writeAsBytes(bytes, flush: true); // flush — критично!

    if (await tempFile.exists()) {
      _logger.info('▶️ Playing pinned song: ${tempFile.path}');

      await _audioPlayerService.playVoice(
        tempFile.path,
        title: _pinnedSongTitle ?? 'Закреплённая песня',
        artist: _pinnedSongArtist ?? 'Rizz App',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('▶️ ${_pinnedSongTitle ?? "Песня"}')),
      );
    }
  } catch (e, stack) {
    _logger.error('Failed to play pinned song', error: e, stack: stack);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка воспроизведения: ${e.toString()}')),
    );
  } finally {
    if (mounted) setState(() => _isPlayingPinnedSong = false);
  }
}

  Widget _buildAvatar() {
    if (_avatarHex != null && _avatarHex!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: FileConverterService.hexToFile(_avatarHex!, 'avatar_${_user.uid}.jpg'),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: 60,
              backgroundImage: FileImage(snapshot.data!),
            );
          }
          return const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60));
        },
      );
    }
    return const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60));
  }

  void _showQrCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Мой QR-код'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'rizz://profile/${_user.uid}',
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Text('UID: ${_user.uid}', style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.share('Мой Rizz профиль: rizz://profile/${_user.uid}');
            },
            icon: const Icon(Icons.share),
            label: const Text('Поделиться'),
          ),
        ],
      ),
    );
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
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              _loadProfile();
            },
            child: const Text('Редактировать', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Center(child: _buildAvatar()),
                  const SizedBox(height: 16),
                  Text(
                    _nickname ?? 'Пользователь',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isLight ? Colors.black : Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(_user.email ?? '', style: TextStyle(fontSize: 14, color: isLight ? Colors.grey.shade600 : Colors.grey.shade400)),
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

                  // ==================== КАРТОЧКА С МУЗЫКОЙ ====================
                  if (_pinnedSongTitle != null && _pinnedSongTitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        elevation: 0,
                        color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.music_note, color: Colors.deepPurple, size: 32),
                          title: Text(
                            _pinnedSongTitle!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(_pinnedSongArtist ?? ''),
                          trailing: _isPlayingPinnedSong
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 32),
                          onTap: _playPinnedSong,
                        ),
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.phone, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
                          title: Text('Телефон', style: TextStyle(color: isLight ? Colors.black87 : Colors.white70)),
                          subtitle: Text(_phoneNumber ?? 'Не указан', style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.grey.shade500)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.qr_code, color: isLight ? Colors.grey.shade700 : Colors.grey.shade400),
                          title: Text('QR-код', style: TextStyle(color: isLight ? Colors.black87 : Colors.white70)),
                          subtitle: const Text('Показать QR-код профиля', style: TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showQrCode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
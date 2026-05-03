import 'dart:io';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger/app_logger.dart';

class AudioPlayerService {
  static AudioPlayerService get I => GetIt.I<AudioPlayerService>();

  final AudioPlayer _player = AudioPlayer();
  final _logger = GetIt.I<AppLogger>();

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Определяем иконку уведомления на основе текущего алиаса
      String iconName = 'ic_stat_audio_default';
      try {
        final prefs = await SharedPreferences.getInstance();
        final alias = prefs.getString('app_icon_alias') ?? 'MainActivityDefault';
        switch (alias) {
          case 'MainActivityBlack':
          case 'MainActivityDark':
            iconName = 'ic_stat_audio_black';
            break;
          case 'MainActivityWhite':
            iconName = 'ic_stat_audio_white';
            break;
          case 'MainActivityBlackWhite':
            iconName = 'ic_stat_audio_black_white';
            break;
          case 'MainActivityBrize':
            iconName = 'ic_stat_audio_brize';
            break;
          case 'MainActivityIngYang':
            iconName = 'ic_stat_audio_ing_yang';
            break;
        }
      } catch (_) {}

      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.rizz.app.audio',
        androidNotificationChannelName: 'Rizz Playback',
        androidNotificationOngoing: true,
        notificationColor: const Color(0xFF6B46C2),
        androidNotificationIcon: iconName,
      );

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _initialized = true;
      _logger.info('Audio player ready (icon: $iconName)');
    } catch (e, stack) {
      _logger.error('AudioPlayerService init error', error: e, stack: stack);
    }
  }

  Future<void> playVoice(String filePath, {String? title, String? artist}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.error('File not found: $filePath');
        return;
      }
      _logger.info('Starting playback: $filePath');
      final mediaItem = MediaItem(
        id: filePath,
        title: title ?? 'Аудио',
        artist: artist ?? 'Rizz App',
      );
      await _player.setAudioSource(AudioSource.file(filePath, tag: mediaItem));
      await _player.play();
    } catch (e, stack) {
      _logger.error('Playback error', error: e, stack: stack);
      try { await _player.stop(); } catch (_) {}
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration pos) => _player.seek(pos);
}
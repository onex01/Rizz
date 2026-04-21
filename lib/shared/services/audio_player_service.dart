import 'dart:ui'; 
import 'package:audio_session/audio_session.dart'; 
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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
      // Критично: используем dedicated drawable иконку (решает "no valid small icon")
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.rizz.app.audio',
        androidNotificationChannelName: 'Rizz Playback',
        androidNotificationOngoing: true,
        notificationColor: const Color(0xFF6B46C2),
        androidNotificationIcon: 'drawable/ic_stat_audio',   // ← ЭТО ИСПРАВЛЯЕТ КРАШ
      );

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _initialized = true;
      _logger.info('AudioPlayerService initialized with valid notification icon');
    } catch (e) {
      _logger.error('Failed to init audio', error: e);
    }
  }

  /// Главный метод: играет файл и вешает его в шторку
  Future<void> playVoice(String filePath, {String? title, String? artist}) async {
    try {
      final mediaItem = MediaItem(
        id: filePath,
        title: title ?? 'Закреплённый трек',
        artist: artist ?? 'Rizz App',
      );

      await _player.setAudioSource(
        AudioSource.file(filePath, tag: mediaItem),
      );

      await _player.play();
    } catch (e) {
      _logger.error('Playback error', error: e);
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration pos) => _player.seek(pos);
}
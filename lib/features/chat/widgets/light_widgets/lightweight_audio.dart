import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../shared/services/audio_player_service.dart';
import '../../../../shared/services/cache_service.dart';
import '../../../../shared/services/media_api_service.dart';
import '../../../../core/logger/app_logger.dart';

class LightweightAudioWidget extends StatefulWidget {
  final File? localFile;
  final String? mediaUrl;
  final String title;
  final String artist;
  final bool isMe;
  final String time;
  final double fontSize;

  const LightweightAudioWidget({
    super.key,
    this.localFile,
    this.mediaUrl,
    required this.title,
    required this.artist,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<LightweightAudioWidget> createState() => _LightweightAudioWidgetState();
}

class _LightweightAudioWidgetState extends State<LightweightAudioWidget> {
  final _service = GetIt.I<AudioPlayerService>();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _loading = false;
  File? _audioFile;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<Duration?> _durationSub;

  @override
  void initState() {
    super.initState();
    _playingSub = _service.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _positionSub = _service.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _service.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (widget.localFile != null) {
      _audioFile = widget.localFile;
      return;
    }
    if (widget.mediaUrl != null) {
      setState(() => _loading = true);
      try {
        final cache = GetIt.I<MessageFileCache>();
        File? cached = await cache.getCachedFile(widget.mediaUrl!);
        if (cached == null) {
          final downloaded = await GetIt.I<MediaApiService>().downloadFile(widget.mediaUrl!);
          if (downloaded != null) {
            await cache.cacheFile(widget.mediaUrl!, downloaded);
            cached = downloaded;
          }
        }
        _audioFile = cached;
      } catch (_) {}
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    if (!File(_audioFile!.path).existsSync()) {
      GetIt.I<AppLogger>().error('Audio file not found: ${_audioFile!.path}');
      return;
    }

    if (_audioFile == null) return;
    try {
      if (_isPlaying) {
        await _service.pause();
      } else {
        await _service.playVoice(_audioFile!.path, title: widget.title, artist: widget.artist);
      }
    } catch (e) {
      GetIt.I<AppLogger>().error('Audio playback error', error: e);
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _playingSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(width: 200, height: 80, child: Center(child: CircularProgressIndicator()));
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.deepPurple.shade100,
              ),
              child: const Icon(Icons.music_note, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(widget.artist, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4)),
                        child: Slider(
                          value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1),
                          max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
                          onChanged: (v) => _service.seek(Duration(milliseconds: v.toInt())),
                          activeColor: Colors.deepPurple,
                          inactiveColor: Colors.grey,
                        ),
                      ),
                    ),
                    Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.deepPurple),
              onPressed: _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}
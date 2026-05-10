import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../shared/services/audio_player_service.dart';
import '../../../../core/logger/app_logger.dart';

class LightweightVoiceWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final String time;
  final double fontSize;

  const LightweightVoiceWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.time,
    required this.fontSize,
  });

  @override
  State<LightweightVoiceWidget> createState() => _LightweightVoiceWidgetState();
}

class _LightweightVoiceWidgetState extends State<LightweightVoiceWidget> {
  final _service = GetIt.I<AudioPlayerService>();
  final _logger = GetIt.I<AppLogger>();

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _service.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _service.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _service.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _service.pause();
      } else {
        await _service.playVoice(widget.url, title: 'Голосовое сообщение');
      }
    } catch (e, stack) {
      _logger.error('Voice playback error', error: e, stack: stack);
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionText = '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}';
    final durationText = _duration != Duration.zero
        ? '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '0:00';

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlay,
            ),
            const SizedBox(width: 8),
            Text('$positionText / $durationText', style: TextStyle(fontSize: widget.fontSize - 2)),
            const SizedBox(width: 8),
            Text(widget.time, style: TextStyle(fontSize: widget.fontSize - 4, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
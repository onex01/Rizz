import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/settings_provider.dart';

class ChatBackground extends StatelessWidget {
  final Widget child;
  const ChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Stack(
      children: [
        _buildBackground(settings),
        child,
      ],
    );
  }

  Widget _buildBackground(SettingsProvider settings) {
    switch (settings.chatBgType) {
      case ChatBackgroundType.color:
        return Container(color: settings.chatSolidColor ?? Colors.white);
      case ChatBackgroundType.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                settings.chatGradientColor1 ?? Colors.blue,
                settings.chatGradientColor2 ?? Colors.purple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      case ChatBackgroundType.image:
        if (settings.chatImagePath != null) {
          return Image.file(File(settings.chatImagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        }
        return const _ProceduralGradientBackground();
      case ChatBackgroundType.procedural:
        return const _ProceduralGradientBackground();
    }
  }
}

class _ProceduralGradientBackground extends StatefulWidget {
  const _ProceduralGradientBackground();

  @override
  State<_ProceduralGradientBackground> createState() => _ProceduralGradientBackgroundState();
}

class _ProceduralGradientBackgroundState extends State<_ProceduralGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(math.sin(t) * 0.5, math.cos(t * 0.7) * 0.3),
              radius: 1.5,
              colors: const [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
                Color(0xFFe94560),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
}
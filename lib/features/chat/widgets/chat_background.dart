import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChatBackground extends StatelessWidget {
  final Color? backgroundColor;
  final String? wallpaperUrl;
  final bool enableEffects;
  final Color? gradientStart;
  final Color? gradientEnd;
  final Widget child;

  const ChatBackground({
    super.key,
    this.backgroundColor,
    this.wallpaperUrl,
    this.enableEffects = false,
    this.gradientStart,
    this.gradientEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (wallpaperUrl != null && wallpaperUrl!.isNotEmpty) {
      // Обои из URL
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(wallpaperUrl!),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
    } else if (enableEffects) {
      // Процедурный градиент с эффектами
      return _ProceduralBackground(
        baseColor: backgroundColor ?? Colors.white,
        child: child,
      );
    } else {
      // Однотонный цвет
      return Container(
        color: backgroundColor,
        child: child,
      );
    }
  }
}

class _ProceduralBackground extends StatefulWidget {
  final Color baseColor;
  final Widget child;

  const _ProceduralBackground({required this.baseColor, required this.child});

  @override
  _ProceduralBackgroundState createState() => _ProceduralBackgroundState();
}

class _ProceduralBackgroundState extends State<_ProceduralBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
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
      builder: (context, _) {
        return CustomPaint(
          painter: _ProceduralPainter(
            baseColor: widget.baseColor,
            time: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _ProceduralPainter extends CustomPainter {
  final Color baseColor;
  final double time;

  _ProceduralPainter({required this.baseColor, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Создаём линейный градиент, который слегка меняется со временем
    final rect = Offset.zero & size;
    final start = Offset(0, size.height * (0.3 + 0.1 * math.sin(time * 2 * math.pi)));
    final end = Offset(size.width, size.height * (0.7 + 0.1 * math.cos(time * 2 * math.pi)));

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withBlue((baseColor.blue + 40).clamp(0, 255)),
        baseColor.withRed((baseColor.red - 30).clamp(0, 255)),
        baseColor.withGreen((baseColor.green + 20).clamp(0, 255)),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
      transform: _GradientRotation(time * 2 * math.pi),
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Рисуем волны (рябь)
    // _drawWaves(canvas, size);
  }

  // void _drawWaves(Canvas canvas, Size size) {
  //   final wavePaint = Paint()
  //     ..color = Colors.white.withOpacity(0.03)
  //     ..style = PaintingStyle.fill;

  //   final path = Path();
  //   final waveHeight = 30.0;
  //   final waveCount = 3;

  //   for (int i = 0; i < waveCount; i++) {
  //     final offsetY = size.height * (0.4 + i * 0.2);
  //     path.reset();
  //     path.moveTo(0, offsetY);
  //     for (double x = 0; x <= size.width; x += 2) {
  //       final y = offsetY +
  //           waveHeight *
  //               math.sin((x / 150) * 2 * math.pi + time * 2 * math.pi + i);
  //       path.lineTo(x, y);
  //     }
  //     path.lineTo(size.width, size.height);
  //     path.lineTo(0, size.height);
  //     path.close();
  //     canvas.drawPath(path, wavePaint);
  //   }
  // }

  @override
  bool shouldRepaint(covariant _ProceduralPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.baseColor != baseColor;
}

class _GradientRotation extends GradientTransform {
  final double angle;
  const _GradientRotation(this.angle);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.rotationZ(angle);
  }
}
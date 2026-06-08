import 'package:flutter/material.dart';

import 'chat_style.dart';

/// Telegram-style chat wallpaper: a soft teal gradient overlaid with a faint
/// tiled doodle pattern, sitting behind the message bubbles.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ChatStyle.wallpaperTop, ChatStyle.wallpaperBottom],
        ),
      ),
      child: CustomPaint(
        painter: _WallpaperPainter(),
        child: child,
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  static const double _tile = 58;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ChatStyle.wallpaperDoodle.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var row = 0;
    for (double y = _tile / 2; y < size.height + _tile; y += _tile) {
      final offsetX = row.isEven ? 0.0 : _tile / 2;
      for (double x = _tile / 2 + offsetX; x < size.width + _tile; x += _tile) {
        _drawGlyph(canvas, Offset(x, y), (row + (x ~/ _tile)) % 4, stroke);
      }
      row++;
    }
  }

  void _drawGlyph(Canvas canvas, Offset center, int variant, Paint paint) {
    switch (variant) {
      case 0:
        _heart(canvas, center, paint);
      case 1:
        canvas.drawCircle(center, 8, paint);
      case 2:
        _star(canvas, center, paint);
      default:
        final rect = Rect.fromCenter(center: center, width: 14, height: 14);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
    }
  }

  void _heart(Canvas canvas, Offset c, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy + 7)
      ..cubicTo(c.dx - 12, c.dy - 4, c.dx - 5, c.dy - 10, c.dx, c.dy - 4)
      ..cubicTo(c.dx + 5, c.dy - 10, c.dx + 12, c.dy - 4, c.dx, c.dy + 7)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _star(Canvas canvas, Offset c, Paint paint) {
    const r = 8.0;
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), paint);
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), paint);
    canvas.drawLine(c.translate(-r * 0.7, -r * 0.7),
        c.translate(r * 0.7, r * 0.7), paint);
    canvas.drawLine(c.translate(r * 0.7, -r * 0.7),
        c.translate(-r * 0.7, r * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter oldDelegate) => false;
}

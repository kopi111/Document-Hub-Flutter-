import 'package:flutter/material.dart';

import 'chat_style.dart';

/// Telegram-style chat wallpaper: a light blue gradient overlaid with a faint
/// tiled bubble/dot pattern, sitting behind the message bubbles.
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
        canvas.drawCircle(center, 7, paint);
      case 1:
        canvas.drawCircle(center, 4, paint);
      case 2:
        canvas.drawCircle(center, 10, paint);
      default:
        canvas.drawCircle(center, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperPainter oldDelegate) => false;
}

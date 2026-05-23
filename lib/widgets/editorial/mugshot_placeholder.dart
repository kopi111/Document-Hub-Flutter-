import 'package:flutter/material.dart';

import '../../theme/duty_theme.dart';

/// Special-Case stand-in for a missing or failed photo.
///
/// Slab initials centred on the duty palette with a faint cross-hatch so the
/// surface never feels broken when a mugshot URL is null or unreachable.
class MugshotPlaceholder extends StatelessWidget {
  const MugshotPlaceholder({
    super.key,
    required this.initials,
    this.tint,
  });

  final String initials;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final base = tint ?? DutyTheme.glaucous;
    return CustomPaint(
      painter: _HatchPainter(line: colors.hairline.withValues(alpha: 0.5)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(alpha: 0.92),
              base.withValues(alpha: 0.74),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials.toUpperCase(),
          style: DutyTheme.slab(
            size: 34,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.line});
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 0.5;
    const step = 12.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) => old.line != line;
}

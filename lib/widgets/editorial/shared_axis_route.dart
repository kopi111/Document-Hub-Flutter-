import 'package:flutter/material.dart';

/// Editorial page transition: short horizontal slide + fade.
///
/// Replaces `MaterialPageRoute` for redesigned screens. Reads like turning a
/// page in a manual rather than the default Android push.
Route<T> sharedAxis<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, a, b) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, secondary, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

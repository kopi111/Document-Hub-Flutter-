import 'package:flutter/material.dart';

/// Design tokens for the redesigned "Hub" look: deep blue→indigo gradient
/// headers, soft white cards, and colour-coded service tiles.
///
/// This is the single source of truth for the new visual language. Screens read
/// gradients, tile tints, shadows, and radii from here so the redesign stays
/// consistent as it rolls out screen by screen.
class HubStyle {
  const HubStyle._();

  // Header / hero gradient — navy to indigo, drifting purple at the far edge.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C2E72), Color(0xFF18398A), Color(0xFF2E2E97)],
  );

  // The three-colour accent stripe that underlines headers and hero cards.
  static const List<Color> accentStripe = [
    Color(0xFF24B8E8), // cyan
    Color(0xFF3FB95A), // green
    Color(0xFFF4A623), // amber
  ];

  // Page + surface neutrals.
  static const Color pageBackground = Color(0xFFEFF3F8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color navBackground = Color(0xFF0B1F47);

  // Text.
  static const Color textPrimary = Color(0xFF15233B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color onGradient = Color(0xFFFFFFFF);
  static final Color onGradientMuted = Colors.white.withValues(alpha: 0.82);

  // Radii.
  static const double cardRadius = 16;
  static const double heroRadius = 18;
  static const double tileRadius = 16;

  /// Soft drop shadow used on white cards and tiles.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1E293B).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// A flat strip of the three accent colours, for the foot of a hero card.
  static Widget accentBar({double height = 4}) => Row(
        children: [
          for (final color in accentStripe)
            Expanded(child: Container(height: height, color: color)),
        ],
      );
}

/// Background + foreground pairing for a colour-coded service tile icon.
@immutable
class HubTint {
  const HubTint(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static const HubTint blue =
      HubTint(Color(0xFFE7F0FE), Color(0xFF2D6CDF));
  static const HubTint green =
      HubTint(Color(0xFFE6F6EC), Color(0xFF1E9E54));
  static const HubTint orange =
      HubTint(Color(0xFFFFF0E1), Color(0xFFEF8A23));
  static const HubTint red =
      HubTint(Color(0xFFFDE9EB), Color(0xFFE0414C));
  static const HubTint purple =
      HubTint(Color(0xFFEDE8FB), Color(0xFF7A4FE0));
  static const HubTint teal =
      HubTint(Color(0xFFE2F4F3), Color(0xFF1AA39B));
}

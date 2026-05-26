import 'package:flutter/material.dart';

/// Unified JCF Document Hub color grading.
///
/// Single source of truth for every screen. Law-enforcement branding: dark,
/// authoritative, high-contrast, with explicit urgency cues. No screen defines
/// its own colors — they all draw from these tokens, [DutyTheme], or [NamStyle]
/// (both of which are wired to this palette).
class JcfPalette {
  const JcfPalette._();

  // Core palette.
  static const Color primary = Color(0xFF0A1C3A); // JCF Dark Blue
  static const Color primaryVariant = Color(0xFF1E3A6F); // JCF Blue
  static const Color secondary = Color(0xFF3A4A5C); // Steel Grey
  static const Color accent = Color(0xFFF5A623); // Amber Alert
  static const Color background = Color(0xFF121826); // Deep Slate
  static const Color surface = Color(0xFF1E293B); // Card Grey
  static const Color surfaceRaised = Color(0xFF243043); // raised cards/sheets

  // Semantic status.
  static const Color success = Color(0xFF10B981); // Operational Green
  static const Color warning = Color(0xFFF59E0B); // Urgent Amber
  static const Color danger = Color(0xFFDC2626); // Critical Red
  static const Color info = Color(0xFF3B82F6); // Patrol Blue

  // Text.
  static const Color textPrimary = Color(0xFFF1F5F9); // high emphasis
  static const Color textSecondary = Color(0xFF94A3B8); // low emphasis
  static const Color textDisabled = Color(0xFF475569);
  static const Color onAccent = Color(0xFF121826); // dark text on amber
  static const Color onDanger = Color(0xFFFFFFFF);

  // Icons.
  static const Color iconDefault = Color(0xFFCBD5E1);
  static const Color iconActive = accent;
  static const Color iconCritical = danger;

  // Structure.
  static const Color hairline = Color(0xFF2A3649); // dividers/borders
  static const Color dangerBorder = Color(0xFFF87171);

  /// Hero-card gradient for high-impact headers (e.g. wanted person card).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // 135deg
    colors: [Color(0xFF0A1C3A), Color(0xFF1E3A6F), Color(0xFF2D4A7C)],
  );
}

/// Operational urgency levels with their badge grading.
enum UrgencyLevel { urgent, high, medium, routine }

/// Badge color grading per urgency level. Read [background], [foreground], and
/// optional [border] to dress any urgency chip consistently across screens.
class UrgencyStyle {
  const UrgencyStyle({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;

  static const UrgencyStyle urgent = UrgencyStyle(
    background: JcfPalette.danger,
    foreground: Color(0xFFFFFFFF),
    border: JcfPalette.dangerBorder,
  );
  static const UrgencyStyle high = UrgencyStyle(
    background: JcfPalette.warning,
    foreground: JcfPalette.background,
  );
  static const UrgencyStyle medium = UrgencyStyle(
    background: JcfPalette.info,
    foreground: Color(0xFFFFFFFF),
  );
  static const UrgencyStyle routine = UrgencyStyle(
    background: JcfPalette.textDisabled,
    foreground: JcfPalette.textPrimary,
  );

  static UrgencyStyle of(UrgencyLevel level) => switch (level) {
        UrgencyLevel.urgent => urgent,
        UrgencyLevel.high => high,
        UrgencyLevel.medium => medium,
        UrgencyLevel.routine => routine,
      };
}

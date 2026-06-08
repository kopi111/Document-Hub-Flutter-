import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'duty_theme.dart';
import 'jcf_palette.dart';

/// Screen-local dark styling for the West-Ops and communications screens.
///
/// Deliberately NOT wired into the global [ThemeData]. These tokens, the local
/// [theme] override, and the text helpers dress the wanted/missing/stolen,
/// directory, email and chat screens in a cinematic charcoal language accented
/// with JCF blue. The [gold] token is retained by name but resolves to the JCF
/// blue brand accent ([JcfPalette.accent]); depth comes from elevation.
class NamStyle {
  const NamStyle._();

  static const Color background = JcfPalette.background;
  static const Color surface = JcfPalette.surface;
  static const Color surfaceRaised = JcfPalette.surfaceRaised;
  static const Color gold = JcfPalette.accent;
  static const Color goldSoft = JcfPalette.warning;
  static const Color onGold = JcfPalette.onAccent;
  static const Color textPrimary = JcfPalette.textPrimary;
  static const Color textSecondary = JcfPalette.textSecondary;
  static const Color hairline = JcfPalette.hairline;
  static const Color found = JcfPalette.success;
  static const Color alert = JcfPalette.danger;

  static const double cardRadius = 16;
  static const double posterRadius = 12;
  static const double pageInset = 20;

  /// Dark/gold theme applied only to the West-Ops person screens. Built from
  /// the duty dark theme so the AppBar, breadcrumb, and dividers inherit the
  /// charcoal-and-gold palette without altering the global theme.
  static ThemeData theme() {
    final base = DutyTheme.light();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        surface: background,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        primary: gold,
        onPrimary: onGold,
        outline: hairline,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: title(size: 18, weight: FontWeight.w700),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        DutyColors(
          alertRed: alert,
          mutedGold: gold,
          hairline: hairline,
          missingTeal: gold,
        ),
      ],
    );
  }

  static TextStyle title({
    double size = 18,
    FontWeight weight = FontWeight.w600,
    Color color = textPrimary,
    double height = 1.15,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textSecondary,
    double height = 1.4,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = gold,
    double letterSpacing = 1.2,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

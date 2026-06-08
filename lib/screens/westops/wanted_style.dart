import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FBI-Wanted-flavoured styling for the wanted screens only.
///
/// A light, document-board look: white app bar with navy title, grey canvas,
/// white photo cards, red crime tags, gold reward/most-wanted accents, and
/// blue/green/gold action buttons on the detail page. Scoped to the wanted
/// list and detail so the rest of West-Ops keeps its dark language.
class WantedStyle {
  const WantedStyle._();

  // Brand -------------------------------------------------------------------
  static const Color navy = Color(0xFF16306B);
  static const Color blue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFF2B100);
  static const Color red = Color(0xFFD42E2E);
  static const Color green = Color(0xFF1E9E57);

  // Surfaces ----------------------------------------------------------------
  static const Color canvas = Color(0xFFEEF1F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color chip = Color(0xFFF1F3F6);

  // Text --------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color hairline = Color(0xFFE3E7ED);

  static const double cardRadius = 14;
  static const double pageInset = 16;

  static ThemeData theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        onPrimary: Colors.white,
        surface: card,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: hairline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        titleTextStyle: title(size: 19, weight: FontWeight.w800, color: navy),
      ),
    );
  }

  static TextStyle title({
    double size = 18,
    FontWeight weight = FontWeight.w700,
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

  static TextStyle label({
    double size = 10,
    FontWeight weight = FontWeight.w800,
    Color color = textSecondary,
    double letterSpacing = 0.8,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

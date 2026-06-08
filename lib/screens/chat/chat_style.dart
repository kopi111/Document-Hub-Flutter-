import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Telegram-flavoured styling for the chat feature only.
///
/// The rest of the app keeps its dark "Field Manual" language; the chat screens
/// adopt a light list, a blue header, a teal doodle wallpaper, white incoming
/// bubbles and pale-green outgoing bubbles to mirror Telegram. Mirrors the
/// shape of NamStyle (token names + text helpers) so the screens read the same.
class ChatStyle {
  const ChatStyle._();

  // Surfaces ----------------------------------------------------------------
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF1F3F4);

  // Brand accent (Telegram blue) — kept as `gold` so screen code is unchanged.
  static const Color gold = Color(0xFF3390EC);
  static const Color goldSoft = Color(0xFF54A9EB);
  static const Color onGold = Color(0xFFFFFFFF);

  // Text --------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B7280); // WCAG AA (~4.8:1 on white)
  static const Color hairline = Color(0xFFE5E5EA);

  // Status ------------------------------------------------------------------
  static const Color unread = Color(0xFF4DCB5D);
  static const Color onlineGreen = Color(0xFF4DCB5D);

  // Bubbles -----------------------------------------------------------------
  static const Color incomingBubble = Color(0xFFFFFFFF);
  static const Color outgoingBubble = Color(0xFFEFFDDE);
  static const Color readTick = Color(0xFF60B8F0);

  // Wallpaper ---------------------------------------------------------------
  static const Color wallpaperTop = Color(0xFFC6E7D6);
  static const Color wallpaperBottom = Color(0xFFA8D8C6);
  static const Color wallpaperDoodle = Color(0xFFFFFFFF);

  // Metrics -----------------------------------------------------------------
  static const double cardRadius = 16;
  static const double bubbleRadius = 14;
  static const double pageInset = 16;

  /// Light theme applied only to the chat screens.
  static ThemeData theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: gold,
        onPrimary: onGold,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: hairline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: title(size: 18, weight: FontWeight.w700, color: Colors.white),
      ),
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
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

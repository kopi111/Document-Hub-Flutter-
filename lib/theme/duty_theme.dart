import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'jcf_palette.dart';

/// Field-manual / editorial theme for the JCF Duty shell.
///
/// Two typefaces of authority + one of data. Roboto Slab anchors display, IBM
/// Plex Sans carries body, IBM Plex Mono is reserved for case numbers, plates,
/// counts, and any tabular figure. Gold is reserved for points of authority
/// (corner banners, hairline rules, the shield); never decorative.
class DutyTheme {
  const DutyTheme._();

  // Provided brand palette.
  static const Color inkBlack = Color(0xFF04080F);
  static const Color glaucous = Color(0xFF507DBC);
  static const Color powderBlue = Color(0xFFA1C6EA);
  static const Color paleSky = Color(0xFFBBD1EA);
  static const Color alabasterGrey = Color(0xFFDAE3E5);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  /// Monospace style for case IDs, plate numbers, fine amounts, dates, counts.
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.2,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Display style for section headings and titles (Poppins, redesigned look).
  static TextStyle slab({
    double size = 18,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = isLight
        ? FlexThemeData.light(
            colors: const FlexSchemeColor(
              primary: JcfPalette.primary,
              primaryContainer: JcfPalette.primaryVariant,
              secondary: JcfPalette.accent,
              secondaryContainer: JcfPalette.primaryVariant,
              tertiary: JcfPalette.info,
              tertiaryContainer: JcfPalette.primaryVariant,
              appBarColor: JcfPalette.primary,
              error: JcfPalette.danger,
            ),
            scaffoldBackground: JcfPalette.background,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 1,
            appBarStyle: FlexAppBarStyle.primary,
            subThemesData: _subThemes,
            visualDensity: VisualDensity.standard,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
          )
        : FlexThemeData.dark(
            colors: const FlexSchemeColor(
              primary: JcfPalette.primary,
              primaryContainer: JcfPalette.primaryVariant,
              secondary: JcfPalette.accent,
              secondaryContainer: JcfPalette.primaryVariant,
              tertiary: JcfPalette.info,
              tertiaryContainer: JcfPalette.primaryVariant,
              appBarColor: JcfPalette.primary,
              error: JcfPalette.danger,
            ),
            scaffoldBackground: JcfPalette.background,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 6,
            appBarStyle: FlexAppBarStyle.primary,
            subThemesData: _subThemes,
            visualDensity: VisualDensity.standard,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
          );

    final ColorScheme scheme = base.colorScheme.copyWith(
      surface: JcfPalette.surface,
      onSurface: JcfPalette.textPrimary,
      onSurfaceVariant: JcfPalette.textSecondary,
      surfaceContainerLowest: JcfPalette.background,
      surfaceContainerLow: JcfPalette.surface,
      surfaceContainer: JcfPalette.surface,
      surfaceContainerHigh: JcfPalette.surfaceRaised,
      surfaceContainerHighest: JcfPalette.surfaceRaised,
      outline: JcfPalette.hairline,
      outlineVariant: JcfPalette.hairline,
      onPrimary: const Color(0xFFFFFFFF),
      onSecondary: JcfPalette.onAccent,
      onError: JcfPalette.onDanger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: JcfPalette.background,
      textTheme: _typography(base.textTheme),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: <ThemeExtension<dynamic>>[
        isLight ? DutyColors.light : DutyColors.dark,
      ],
      dividerTheme: DividerThemeData(
        color: (isLight ? DutyColors.light : DutyColors.dark).hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0.6,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: base.colorScheme.onSurface,
        ),
      ),
    );
  }

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    useM2StyleDividerInM3: false,
    defaultRadius: 8,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    inputDecoratorBorderType: FlexInputBorderType.underline,
    inputDecoratorRadius: 0,
    inputDecoratorFocusedHasBorder: true,
    inputDecoratorIsFilled: false,
    cardRadius: 16,
    cardElevation: 0,
    bottomNavigationBarElevation: 0,
    navigationBarElevation: 0,
    bottomSheetRadius: 8,
    chipRadius: 4,
    appBarCenterTitle: false,
    appBarScrolledUnderElevation: 0.6,
  );

  static TextTheme _typography(TextTheme base) {
    final body = GoogleFonts.poppinsTextTheme(base);
    return body.copyWith(
      headlineLarge: GoogleFonts.poppins(
        textStyle: body.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: body.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: body.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: body.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: body.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: (body.labelLarge ?? const TextStyle()).copyWith(
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      labelMedium: (body.labelMedium ?? const TextStyle()).copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    );
  }
}

/// Semantic colors that the Material ColorScheme cannot express.
///
/// Read via `Theme.of(context).extension<DutyColors>()!`. Both light and dark
/// themes register their own instance.
@immutable
class DutyColors extends ThemeExtension<DutyColors> {
  const DutyColors({
    required this.alertRed,
    required this.mutedGold,
    required this.hairline,
    required this.missingTeal,
  });

  final Color alertRed;
  final Color mutedGold;
  final Color hairline;
  final Color missingTeal;

  static const DutyColors light = DutyColors(
    alertRed: JcfPalette.danger,
    mutedGold: JcfPalette.accent,
    hairline: JcfPalette.hairline,
    missingTeal: JcfPalette.info,
  );

  static const DutyColors dark = DutyColors(
    alertRed: JcfPalette.danger,
    mutedGold: JcfPalette.accent,
    hairline: JcfPalette.hairline,
    missingTeal: JcfPalette.info,
  );

  @override
  DutyColors copyWith({
    Color? alertRed,
    Color? mutedGold,
    Color? hairline,
    Color? missingTeal,
  }) =>
      DutyColors(
        alertRed: alertRed ?? this.alertRed,
        mutedGold: mutedGold ?? this.mutedGold,
        hairline: hairline ?? this.hairline,
        missingTeal: missingTeal ?? this.missingTeal,
      );

  @override
  DutyColors lerp(ThemeExtension<DutyColors>? other, double t) {
    if (other is! DutyColors) return this;
    return DutyColors(
      alertRed: Color.lerp(alertRed, other.alertRed, t)!,
      mutedGold: Color.lerp(mutedGold, other.mutedGold, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      missingTeal: Color.lerp(missingTeal, other.missingTeal, t)!,
    );
  }
}

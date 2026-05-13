import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme palette and builders for the JCF Duty shell.
///
/// `dutyGreen` is the operational primary; `dutyGold` is a restrained accent
/// reserved for shields, headings, and highlights. The palette is intentionally
/// muted so badges and status indicators stay legible at a glance.
class DutyTheme {
  const DutyTheme._();

  static const Color dutyGreen = Color(0xFF0F3D2E);
  static const Color dutyGold = Color(0xFFC9A227);
  static const Color dutyNavy = Color(0xFF11243C);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = isLight
        ? FlexThemeData.light(
            colors: const FlexSchemeColor(
              primary: dutyGreen,
              primaryContainer: Color(0xFFCDE5D8),
              secondary: dutyGold,
              secondaryContainer: Color(0xFFF1E2B0),
              tertiary: dutyNavy,
              tertiaryContainer: Color(0xFFCFDCEB),
              appBarColor: dutyGreen,
              error: Color(0xFFB3261E),
            ),
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 8,
            appBarStyle: FlexAppBarStyle.primary,
            subThemesData: _subThemes,
            visualDensity: VisualDensity.standard,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
          )
        : FlexThemeData.dark(
            colors: const FlexSchemeColor(
              primary: Color(0xFF6FBF9A),
              primaryContainer: Color(0xFF11402F),
              secondary: Color(0xFFE2BE5D),
              secondaryContainer: Color(0xFF4A3A0E),
              tertiary: Color(0xFF8FB6E1),
              tertiaryContainer: Color(0xFF1B2F47),
              appBarColor: Color(0xFF0B2A20),
              error: Color(0xFFEFB8B1),
            ),
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 14,
            appBarStyle: FlexAppBarStyle.background,
            subThemesData: _subThemes,
            visualDensity: VisualDensity.standard,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
          );

    return base.copyWith(
      textTheme: _typography(base.textTheme),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    useM2StyleDividerInM3: true,
    defaultRadius: 14,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorRadius: 12,
    inputDecoratorFocusedHasBorder: true,
    inputDecoratorIsFilled: true,
    cardRadius: 16,
    cardElevation: 1,
    bottomNavigationBarElevation: 2,
    bottomNavigationBarOpacity: 0.96,
    navigationBarOpacity: 0.96,
    bottomSheetRadius: 20,
    chipRadius: 10,
    appBarCenterTitle: true,
    appBarScrolledUnderElevation: 1,
  );

  static TextTheme _typography(TextTheme base) {
    final body = GoogleFonts.interTextTheme(base);
    return body.copyWith(
      headlineLarge: GoogleFonts.robotoSlab(
        textStyle: body.headlineLarge,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.robotoSlab(
        textStyle: body.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.robotoSlab(
        textStyle: body.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.robotoSlab(
        textStyle: body.titleLarge,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

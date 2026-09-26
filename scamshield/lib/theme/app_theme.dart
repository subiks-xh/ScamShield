import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ScamShield Design System Tokens
class AppColors {
  // Primary palette (Cyber/Neon Theme)
  static const Color royalNavy = Color(0xFF0F172A); // Deep slate
  static const Color navyLight = Color(0xFF1E293B);
  static const Color navyDark = Color(0xFF020617);
  static const Color royalPurple = Color(0xFF7C3AED); // Bright purple
  static const Color purpleLight = Color(0xFF8B5CF6);
  static const Color antiqueGold = Color(0xFFF59E0B); // Amber/Neon orange
  static const Color goldLight = Color(0xFFFCD34D);
  static const Color goldDim = Color(0xFFB45309);
  static const Color ivory = Color(0xFFF8FAFC);
  static const Color ivoryDim = Color(0xFFCBD5E1);

  // Risk states
  static const Color deepCrimson = Color(0xFFE11D48); // Neon Rose
  static const Color crimsonLight = Color(0xFFFB7185);
  static const Color amberWarn = Color(0xFFF97316);
  static const Color amberWarnLight = Color(0xFFFDBA74);
  static const Color deepEmerald = Color(0xFF10B981); // Neon Emerald
  static const Color emeraldLight = Color(0xFF34D399);

  // UI
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color divider = Color(0xFF334155);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  // Score colors
  static Color scoreColor(double score) {
    if (score > 60) return deepCrimson;
    if (score > 30) return amberWarn;
    return deepEmerald;
  }

  static Color verdictColor(String verdict) {
    switch (verdict) {
      case 'high_risk':
        return deepCrimson;
      case 'medium_risk':
        return amberWarn;
      default:
        return deepEmerald;
    }
  }
}

/// Typography using Google Fonts
class AppTypography {
  // Fraunces: serif for headings/verdict
  static TextStyle heading1(BuildContext context, {Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ivory,
        height: 1.1,
      );

  static TextStyle heading2(BuildContext context, {Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ivory,
        height: 1.2,
      );

  static TextStyle verdictText(BuildContext context, {Color? color, bool simple = false}) =>
      GoogleFonts.fraunces(
        fontSize: simple ? 28 : 22,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ivory,
      );

  // Manrope: body/buttons/labels
  static TextStyle body(BuildContext context, {Color? color, bool simple = false}) =>
      GoogleFonts.manrope(
        fontSize: simple ? 18 : 14,
        color: color ?? AppColors.ivoryDim,
        height: 1.5,
      );

  static TextStyle label(BuildContext context, {Color? color, bool simple = false}) =>
      GoogleFonts.manrope(
        fontSize: simple ? 16 : 12,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textMuted,
        letterSpacing: 0.05,
      );

  static TextStyle button(BuildContext context, {bool simple = false}) =>
      GoogleFonts.manrope(
        fontSize: simple ? 18 : 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02,
      );

  // IBM Plex Mono: score numbers ONLY
  static TextStyle scoreNumber({Color? color, bool simple = false}) =>
      const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ).copyWith(
        color: color ?? AppColors.ivory,
        fontSize: simple ? 28 : 22,
      );

  static TextStyle mono({Color? color, double? size}) =>
      TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: size ?? 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textMuted,
      );
}

/// The main theme
class AppTheme {
  static ThemeData dark({bool simpleMode = false}) {
    final base = ThemeData.dark();
    final scale = simpleMode ? 1.4 : 1.0;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.royalNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.antiqueGold,
        secondary: AppColors.royalPurple,
        surface: AppColors.navyLight,
        error: AppColors.deepCrimson,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.royalPurple,
        foregroundColor: AppColors.ivory,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w700,
          color: AppColors.ivory,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.royalNavy,
        selectedItemColor: AppColors.antiqueGold,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11 * scale,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.antiqueGold,
          foregroundColor: AppColors.royalNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: simpleMode ? 18 : 14,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.antiqueGold,
          side: const BorderSide(color: AppColors.antiqueGold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: simpleMode ? 18 : 14,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.navyLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.antiqueGold, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(color: AppColors.textMuted),
        hintStyle: GoogleFonts.manrope(color: AppColors.textDim),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.royalNavy
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.antiqueGold
              : AppColors.divider,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.manrope(color: AppColors.ivory),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.antiqueGold,
      ),
      textTheme: base.textTheme.copyWith(
        bodyLarge: GoogleFonts.manrope(color: AppColors.ivoryDim),
        bodyMedium: GoogleFonts.manrope(color: AppColors.ivoryDim),
        labelMedium: GoogleFonts.manrope(color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData light({bool simpleMode = false}) {
    // Same tokens, swapped background/text
    return dark(simpleMode: simpleMode).copyWith(
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.antiqueGold,
        secondary: AppColors.royalPurple,
        surface: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
            bodyLarge: GoogleFonts.manrope(color: AppColors.royalNavy),
            bodyMedium: GoogleFonts.manrope(color: AppColors.royalNavy),
          ),
    );
  }
}

/// Card widget with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyLight, AppColors.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor ?? AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

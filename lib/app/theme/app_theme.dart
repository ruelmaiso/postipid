import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const ink = Color(0xFF1F2430);
  static const slate = Color(0xFF6A7387);
  static const mist = Color(0xFFF6F2EA);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceAlt = Color(0xFFF3EEE5);
  static const surfaceTint = Color(0xFFEEE7DA);
  static const paper = Color(0xFFFFFEFB);
  static const line = Color(0xFFE1D9CC);

  static const midnight = Color(0xFF11151B);
  static const nightSurface = Color(0xFF171C24);
  static const nightSurfaceAlt = Color(0xFF1E2530);
  static const nightLine = Color(0xFF2A3240);

  static const primary = Color(0xFF3D73E8);
  static const primaryDeep = Color(0xFF2759C7);
  static const lilac = Color(0xFFB7C7F8);
  static const lilacSoft = Color(0xFFE8EEFC);
  static const emerald = Color(0xFF2E9C6A);
  static const emeraldSoft = Color(0xFFE4F3EA);
  static const amber = Color(0xFFE9B15A);
  static const amberSoft = Color(0xFFFFF0D5);
  static const coral = Color(0xFFE47D68);
  static const coralSoft = Color(0xFFFBE5E0);
  static const ocean = Color(0xFF7AA8F5);
  static const oceanSoft = Color(0xFFE2ECFD);

  static const shellGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFCF8),
      Color(0xFFF6F2EA),
    ],
  );

  static const darkShellGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF11151B),
      Color(0xFF151A22),
    ],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B62D8),
      Color(0xFF3F80F2),
      Color(0xFF69B0F5),
    ],
  );
}

class AppTheme {
  static ThemeData buildLight() {
    final textTheme = _textTheme(AppPalette.ink, AppPalette.slate);
    const colorScheme = ColorScheme.light(
      primary: AppPalette.primary,
      secondary: AppPalette.lilac,
      error: AppPalette.coral,
      surface: AppPalette.surface,
      onPrimary: Colors.white,
      onSecondary: AppPalette.ink,
      onSurface: AppPalette.ink,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppPalette.mist,
      cardColor: AppPalette.surface,
      dividerColor: AppPalette.line,
      textTheme: textTheme,
      isDark: false,
    );
  }

  static ThemeData buildDark() {
    final textTheme = _textTheme(Colors.white, const Color(0xFFB4BCD3));
    const colorScheme = ColorScheme.dark(
      primary: AppPalette.primary,
      secondary: AppPalette.lilac,
      error: AppPalette.coral,
      surface: AppPalette.nightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppPalette.midnight,
      cardColor: AppPalette.nightSurface,
      dividerColor: AppPalette.nightLine,
      textTheme: textTheme,
      isDark: true,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color dividerColor,
    required TextTheme textTheme,
    required bool isDark,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
    );

    final inputFill = isDark ? AppPalette.nightSurfaceAlt : Colors.white;
    final borderColor = dividerColor;

    return base.copyWith(
      cardColor: cardColor,
      dividerColor: dividerColor,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppPalette.nightSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppPalette.nightSurfaceAlt : AppPalette.ink,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: isDark ? AppPalette.nightLine : AppPalette.lilacSoft,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? AppPalette.nightSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? AppPalette.nightSurfaceAlt : AppPalette.lilacSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : textTheme.bodyLarge?.color,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? (isDark ? AppPalette.nightSurfaceAlt : AppPalette.lilacSoft)
                : inputFill,
          ),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppPalette.nightSurfaceAlt : AppPalette.lilacSoft,
        selectedColor: isDark ? AppPalette.nightSurfaceAlt : AppPalette.lilacSoft,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: inputFill,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dividerColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: borderColor),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: inputFill,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color muted) {
    return GoogleFonts.manropeTextTheme().copyWith(
      headlineMedium: GoogleFonts.outfit(
        fontSize: 29,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.8,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.6,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 14,
        height: 1.5,
        color: ink,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 13,
        height: 1.5,
        color: muted,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// NewsApp Design System
/// Aesthetic: Editorial Dark — deep charcoal & obsidian surfaces,
/// electric amber accents, Playfair Display headlines, DM Sans body.
class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFF5A623); // Electric amber
  static const Color primaryDark = Color(0xFFD4891A);
  static const Color primaryLight = Color(0xFFFFC84A);

  static const Color surface = Color(0xFF111318); // Deep obsidian
  static const Color surfaceElevated = Color(0xFF1A1D24); // Cards
  static const Color surfaceOverlay = Color(0xFF22262F); // Modals/sheets
  static const Color divider = Color(0xFF2A2D36);

  static const Color onSurface = Color(0xFFF2F2F2);
  static const Color onSurfaceMid = Color(0xFFB0B3BB);
  static const Color onSurfaceLow = Color(0xFF6B6E78);

  static const Color accent = Color(0xFF3D8EFF); // Sapphire blue
  static const Color success = Color(0xFF2ED573);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFBE21);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF111318), Color(0xFF0D0F14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme get _textTheme {
    final dmSans = GoogleFonts.dmSansTextTheme();
    return dmSans.copyWith(
      // Display — Playfair for editorial headlines
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -1.0,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      // Headline — DM Sans medium weight
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Title
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurfaceMid,
      ),
      // Body
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.55,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurfaceMid,
        height: 1.5,
      ),
      // Label
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceMid,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF1A0F00),
        primaryContainer: Color(0xFF3D2800),
        onPrimaryContainer: primaryLight,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceElevated,
        outline: divider,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF1A0F00),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: GoogleFonts.dmSans(color: onSurfaceLow, fontSize: 15),
        labelStyle: GoogleFonts.dmSans(color: onSurfaceMid, fontSize: 15),
        floatingLabelStyle: GoogleFonts.dmSans(color: primary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceOverlay,
        labelStyle: GoogleFonts.dmSans(color: onSurfaceMid, fontSize: 12),
        side: const BorderSide(color: divider, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceElevated,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceLow,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceOverlay,
        contentTextStyle: GoogleFonts.dmSans(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceLow,
        indicatorColor: primary,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : onSurfaceLow,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withOpacity(0.3)
              : divider,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}

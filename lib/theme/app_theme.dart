import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Statyczne kolory (stałe dla ciemnego motywu / fallback) ──
  static const Color bgDark       = Color(0xFF0D0D0D);
  static const Color bgCard       = Color(0xFF1A1A2E); // tylko dark – używaj Theme.of(ctx).cardColor
  static const Color accent       = Color(0xFFE94560);
  static const Color accentSecond = Color(0xFF0F3460);
  static const Color textPrimary  = Color(0xFFF5F5F5);
  static const Color textSecond   = Color(0xFF9E9E9E);
  static const Color success      = Color(0xFF4CAF50);
  static const Color warning      = Color(0xFFFF9800);

  // ── Kolory jasnego motywu ─────────────────────────────────────
  static const Color bgLight      = Color(0xFFF0F2F5);
  static const Color bgCardLight  = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondLight  = Color(0xFF6B7280);
  static const Color borderLight  = Color(0xFFE5E7EB);
  static const Color borderDark   = Color(0x1AFFFFFF); // white10

  // ── Pomocnicze adaptywne gettery (wymagają BuildContext) ──────
  static Color cardBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? bgCard : bgCardLight;

  static Color scaffoldBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? bgDark : bgLight;

  static Color textPrim(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? textPrimary : textPrimaryLight;

  static Color textSec(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? textSecond : textSecondLight;

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? borderDark : borderLight;

  static Color subtleOverlay(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04);

  static Color subtleOverlayStrong(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08);

  static Color modalBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : Colors.white;

  // ── Ciemny motyw ─────────────────────────────────────────────
  static ThemeData darkTheme({Color accentColor = accent}) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentSecond,
        surface: bgCard,
        error: const Color(0xFFCF6679),
        scrim: bgDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: textPrimary),
          bodyMedium:    TextStyle(color: textSecond),
          bodySmall:     TextStyle(color: textSecond),
          labelLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecond,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5)),
        labelStyle: const TextStyle(color: textSecond),
        hintStyle: const TextStyle(color: textSecond),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentColor : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accentColor.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        labelStyle: const TextStyle(color: textSecond),
        side: const BorderSide(color: borderDark),
      ),
      dividerColor: borderDark,
      useMaterial3: true,
    );
  }

  // ── Jasny motyw ───────────────────────────────────────────────
  static ThemeData lightTheme({Color accentColor = accent}) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentSecond,
        surface: bgCardLight,
        onSurface: textPrimaryLight,
        surfaceContainerHighest: bgLight,
        error: const Color(0xFFB00020),
        outline: borderLight,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
          titleLarge:    TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: textPrimaryLight),
          bodyMedium:    TextStyle(color: textSecondLight),
          bodySmall:     TextStyle(color: textSecondLight),
          labelLarge:    TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgCardLight,
        elevation: 0,
        shadowColor: Colors.black12,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimaryLight, fontSize: 22, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: textPrimaryLight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgCardLight,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondLight,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: bgCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5)),
        labelStyle: const TextStyle(color: textSecondLight),
        hintStyle: const TextStyle(color: textSecondLight),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentColor : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accentColor.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgCardLight,
        labelStyle: const TextStyle(color: textSecondLight),
        side: const BorderSide(color: borderLight),
      ),
      dividerColor: borderLight,
      useMaterial3: true,
    );
  }
}

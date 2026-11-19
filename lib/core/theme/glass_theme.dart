import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean, High-Contrast Black & White Luxury Theme (Roboto Typography, Zero Glow)
class GlassTheme {
  GlassTheme._();

  // Pure Obsidian & Clean Precision Neutrals
  static const Color black = Color(0xFF000000);
  static const Color darkBg = Color(0xFF09090B);
  static const Color cardBg = Color(0xFF131316);
  static const Color cardHover = Color(0xFF1B1B20);
  
  // Sharp Monochrome Accents
  static const Color white = Color(0xFFFFFFFF);
  static const Color silver = Color(0xFFE4E4E7);
  static const Color chrome = Color(0xFFA1A1AA);
  static const Color mutedSilver = Color(0xFF71717A);
  static const Color border = Color(0xFF27272A);
  static const Color subtleBorder = Color(0xFF1F1F23);

  // Status Colors (Subtle, Crisp, Non-Glowing)
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusBlue = Color(0xFF3B82F6);
  static const Color statusOrange = Color(0xFFF97316);
  static const Color statusRed = Color(0xFFEF4444);

  // High-End Accent Font Palette (Precision colored typography)
  static const Color accentEmerald = Color(0xFF10B981); // Emerald Mint
  static const Color accentCyan = Color(0xFF06B6D4);    // Electric Cyan
  static const Color accentSky = Color(0xFF38BDF8);     // Ice Sky Blue
  static const Color accentAmber = Color(0xFFF59E0B);   // Golden Amber
  static const Color accentViolet = Color(0xFFA855F7);  // Royal Violet
  static const Color accentRose = Color(0xFFF43F5E);    // Alert Rose Red

  // Compatibility aliases
  static const Color appleGreen = statusGreen;
  static const Color appleBlue = statusBlue;
  static const Color appleOrange = statusOrange;
  static const Color appleRed = statusRed;

  static ThemeData get theme {
    // Roboto Font Family with crisp letter spacing & line heights
    final textTheme = GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(color: white, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: const TextStyle(color: white, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineMedium: const TextStyle(color: white, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: const TextStyle(color: white, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: white, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(color: silver, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: const TextStyle(color: chrome, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: const TextStyle(color: mutedSilver, fontWeight: FontWeight.w400),
      labelLarge: const TextStyle(color: white, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: white,
        onPrimary: black,
        secondary: silver,
        surface: cardBg,
        onSurface: white,
        error: statusRed,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

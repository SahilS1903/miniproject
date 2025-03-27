import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF00F0FF); // Neon cyan
  static const Color secondaryColor = Color(0xFF7B61FF); // Neon purple
  static const Color accentColor = Color(0xFF00FF94); // Neon green
  static const Color backgroundDark = Color(0xFF0A0E17); // Dark blue-black
  static const Color cardDark = Color(0xFF151921); // Slightly lighter dark
  static const Color textLight = Color(0xFFE0E0FF);
  static const Color textDark = Color(0xFF8B8B9D);
  static const Color errorColor = Color(0xFFFF4D4D);
  static const Color successColor = Color(0xFF00FF94);
  static const Color warningColor = Color(0xFFFFB800);
  static const Color dividerColor = Color(0xFF2A2E35);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundDark,
      ),

      // Text Theme
      textTheme: TextTheme(
        titleLarge: GoogleFonts.spaceMono(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: 1,
        ),
        titleMedium: GoogleFonts.spaceMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          color: textLight,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          color: textDark,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundDark,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        color: cardDark,
        shadowColor: primaryColor.withOpacity(0.1),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textLight,
          backgroundColor: cardDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: primaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.2),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.5,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          color: textDark,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: textLight,
        ),
      ),
    );
  }
}

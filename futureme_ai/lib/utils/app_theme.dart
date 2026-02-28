import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryNeon = Color(0xFF00E5FF); // Neon Cyan
  static const Color secondaryNeon = Color(0xFF7C4DFF); // Neon Purple
  static const Color backgroundDark = Color(0xFF0A0E21);
  static const Color surfaceDark = Color(0xFF1D1E33);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surfaceDark,
      ),
      textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.orbitron(color: primaryNeon, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: Colors.white70),
        bodyMedium: GoogleFonts.inter(color: Colors.white60),
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

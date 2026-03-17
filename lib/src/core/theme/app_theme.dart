// lib/src/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1976D2),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: const Color(0xFFFFFFFF),
      dividerColor: const Color(0xFFE2E8F0),

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        primary: const Color(0xFF1976D2),
        background: const Color(0xFFF8FAFC),
        surface: const Color(0xFFFFFFFF),
        outline: const Color(0xFFE2E8F0),
        brightness: Brightness.light,
      ),

      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: const Color(0xFF334155)),
        bodyMedium: GoogleFonts.outfit(color: const Color(0xFF334155)),
        bodySmall: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        labelLarge: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        labelMedium: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        labelSmall: GoogleFonts.outfit(color: const Color(0xFF64748B)),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1976D2),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      dividerColor: const Color(0xFF334155),

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        primary: const Color(0xFF1976D2),
        background: const Color(0xFF0F172A),
        surface: const Color(0xFF1E293B),
        outline: const Color(0xFF334155),
        brightness: Brightness.dark,
      ),

      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7)),
        bodyMedium: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7)),
        bodySmall: GoogleFonts.outfit(color: Colors.white.withOpacity(0.38)),
        labelLarge: GoogleFonts.outfit(color: Colors.white.withOpacity(0.38)),
        labelMedium: GoogleFonts.outfit(color: Colors.white.withOpacity(0.38)),
        labelSmall: GoogleFonts.outfit(color: Colors.white.withOpacity(0.38)),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        labelStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

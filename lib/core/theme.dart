import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom theme configuration for the application
/// Provides both dark and light themes with green primary color for consistency across the app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color constants
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _primaryColor = Colors.green;
  static const Color primaryColor = Colors.green;
  static const Color accentColor = Colors.greenAccent;

  /// Shared TextTheme configuration with custom font sizes
  /// Used for both light and dark themes
  static TextTheme _buildTextTheme(TextTheme baseTheme, {Color? textColor}) {
    return GoogleFonts.poppinsTextTheme(baseTheme).copyWith(
      // Custom headline sizes
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );
  }

  /// Shared CardThemeData configuration
  /// Applied to both light and dark themes
  static const CardThemeData _cardTheme = CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 2,
  );

  /// Dark theme configuration with green primary color
  static ThemeData darkTheme() {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: false,
      ),
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: Colors.greenAccent,
        surface: _darkSurface,
      ),
      cardTheme: _cardTheme,
      textTheme: _buildTextTheme(baseTheme.textTheme),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Light theme configuration with green primary color
  static ThemeData lightTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return baseTheme.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: const Color(0xFFFAFAFA),
      ),
      cardTheme: _cardTheme,
      textTheme: _buildTextTheme(baseTheme.textTheme, textColor: Colors.black87),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom theme configuration for the application
/// Provides both dark and light themes with green primary color for consistency across the app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color constants
  static const Color _darkBackground = Color(0xFF121212);
  static const Color primaryColor = Colors.green;
  static const Color accentColor = Colors.greenAccent;

  // High-contrast palette tuned for AA-level readability in dark mode.
  static const Color _darkPrimary = Color(0xFF7EE787);
  static const Color _darkOnPrimary = Color(0xFF05210F);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkSurfaceContainer = Color(0xFF1F2630);
  static const Color _darkOnSurface = Color(0xFFF2F4F8);
  static const Color _darkOnSurfaceVariant = Color(0xFFCBD3DC);
  static const Color _darkOutline = Color(0xFF8D99A8);
  static const Color _darkDisabled = Color(0xFF98A2B3);

  // Light palette keeps strong contrast while matching the existing green theme.
  static const Color _lightPrimary = Color(0xFF1B5E20);
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF111827);
  static const Color _lightOnSurfaceVariant = Color(0xFF374151);
  static const Color _lightOutline = Color(0xFF6B7280);
  static const Color _lightDisabled = Color(0xFF5F6673);

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
  static ThemeData darkTheme({int? seedColor}) {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    final seededPrimary = seedColor != null ? Color(seedColor) : _darkPrimary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seededPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      // Verify in Flutter DevTools Accessibility Inspector and the
      // Semantics/Contrast overlays for AA contrast compliance.
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      surface: _darkSurface,
      surfaceContainerHighest: _darkSurfaceContainer,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      outline: _darkOutline,
    );

    return baseTheme.copyWith(
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: false,
        foregroundColor: colorScheme.onSurface,
      ),
      colorScheme: colorScheme,
      cardTheme: _cardTheme,
      textTheme: _buildTextTheme(
        baseTheme.textTheme,
        textColor: colorScheme.onSurface,
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      disabledColor: _darkDisabled,
      dividerColor: colorScheme.outline.withValues(alpha: 0.45),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: _darkDisabled,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: _darkDisabled,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Light theme configuration with green primary color
  static ThemeData lightTheme({int? seedColor}) {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final seededPrimary = seedColor != null ? Color(seedColor) : _lightPrimary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seededPrimary,
      brightness: Brightness.light,
    ).copyWith(
      // Validate against DevTools Accessibility Inspector to keep readable
      // contrast under large-text and high-emphasis content scenarios.
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      onSurfaceVariant: _lightOnSurfaceVariant,
      outline: _lightOutline,
    );

    return baseTheme.copyWith(
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        foregroundColor: colorScheme.onSurface,
      ),
      colorScheme: colorScheme,
      cardTheme: _cardTheme,
      textTheme: _buildTextTheme(
        baseTheme.textTheme,
        textColor: colorScheme.onSurface,
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      disabledColor: _lightDisabled,
      dividerColor: colorScheme.outline.withValues(alpha: 0.35),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: _lightDisabled,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: _lightDisabled,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

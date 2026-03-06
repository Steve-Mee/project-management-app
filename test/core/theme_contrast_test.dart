import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_management_app/core/theme.dart';

/// WCAG contrast ratio between two colors.
double _contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectAaContrast({
  required String label,
  required Color foreground,
  required Color background,
  double minRatio = 4.5,
}) {
  final ratio = _contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(minRatio),
    reason: '$label contrast ratio ${ratio.toStringAsFixed(2)} is below '
        'WCAG AA minimum ${minRatio.toStringAsFixed(1)}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Theme contrast (WCAG AA)', () {
    test('dark theme key text and controls meet AA contrast', () {
      final darkTheme = AppTheme.darkTheme();
      final scheme = darkTheme.colorScheme;

      // Core dark text readability on surfaces.
      _expectAaContrast(
        label: 'Dark onSurface on surface',
        foreground: scheme.onSurface,
        background: scheme.surface,
      );

      _expectAaContrast(
        label: 'Dark onSurfaceVariant on surface',
        foreground: scheme.onSurfaceVariant,
        background: scheme.surface,
      );

      // Primary button readability.
      _expectAaContrast(
        label: 'Dark onPrimary on primary',
        foreground: scheme.onPrimary,
        background: scheme.primary,
      );

      // Disabled-state readability against scaffold background.
      _expectAaContrast(
        label: 'Dark disabled on scaffold background',
        foreground: darkTheme.disabledColor,
        background: darkTheme.scaffoldBackgroundColor,
      );
    });

    test('light theme key text and controls meet AA contrast', () {
      final lightTheme = AppTheme.lightTheme();
      final scheme = lightTheme.colorScheme;

      // Core light text readability on surfaces.
      _expectAaContrast(
        label: 'Light onSurface on surface',
        foreground: scheme.onSurface,
        background: scheme.surface,
      );

      // Primary button readability.
      _expectAaContrast(
        label: 'Light onPrimary on primary',
        foreground: scheme.onPrimary,
        background: scheme.primary,
      );

      // Disabled-state readability against scaffold background.
      _expectAaContrast(
        label: 'Light disabled on scaffold background',
        foreground: lightTheme.disabledColor,
        background: lightTheme.scaffoldBackgroundColor,
      );
    });
  });
}

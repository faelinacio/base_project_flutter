import 'package:flutter/material.dart';

/// App-wide Material 3 theme. Blue seed color to match base_project_react's Chakra UI
/// `blue.600` accent; light and dark variants both defined for platform theme-mode support.
class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Colors.blue;

  static ThemeData get light => _themeFrom(
    ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
  );

  static ThemeData get dark => _themeFrom(
    ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
  );

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

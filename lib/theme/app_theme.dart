import 'package:flutter/material.dart';

/// The accent colors the user can pick from in Settings.
/// Adding a new accent is as simple as adding a new entry here — nothing
/// else in the app needs to change.
enum AppAccentColor { blue, green, purple, orange }

extension AppAccentColorX on AppAccentColor {
  String get label {
    switch (this) {
      case AppAccentColor.blue:
        return 'Blue';
      case AppAccentColor.green:
        return 'Green';
      case AppAccentColor.purple:
        return 'Purple';
      case AppAccentColor.orange:
        return 'Orange';
    }
  }

  Color get seedColor {
    switch (this) {
      case AppAccentColor.blue:
        return const Color(0xFF3D5AFE); // indigo/blue
      case AppAccentColor.green:
        return const Color(0xFF2E7D32);
      case AppAccentColor.purple:
        return const Color(0xFF7B1FA2);
      case AppAccentColor.orange:
        return const Color(0xFFEF6C00);
    }
  }
}

/// Centralizes all `ThemeData` construction so no widget in the app ever
/// hardcodes a `Color` or `TextStyle` directly — everything reads from
/// `Theme.of(context)` / `ColorScheme.of(context)` instead. This is what
/// lets a single accent-color change ripple through the entire UI.
class AppTheme {
  AppTheme._();

  static ThemeData light(AppAccentColor accent) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark(AppAccentColor accent) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A small, fixed palette notes can be tagged with. Stored as
  /// `Color.value` (an int) in the database via `Note.color`.
  static const List<Color> noteColors = [
    Color(0xFFEF9A9A), // red
    Color(0xFFFFCC80), // orange
    Color(0xFFFFF59D), // yellow
    Color(0xFFA5D6A7), // green
    Color(0xFF90CAF9), // blue
    Color(0xFFCE93D8), // purple
    Color(0xFFB0BEC5), // grey
  ];
}

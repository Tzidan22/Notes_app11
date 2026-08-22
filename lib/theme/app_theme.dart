import 'package:flutter/material.dart';

enum AppAccent {
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  orange('Orange', Colors.orange),
  teal('Teal', Colors.teal);

  const AppAccent(this.label, this.color);

  final String label;
  final Color color;
}

class AppTheme {
  const AppTheme._();

  static ThemeData build(AppAccent accent, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.color,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}


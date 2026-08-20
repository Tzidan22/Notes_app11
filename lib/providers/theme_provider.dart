import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Holds the user's chosen ThemeMode (system/light/dark) and accent color,
/// and persists both choices to disk with SharedPreferences so they survive
/// an app restart.
///
/// Like [NotesProvider], this is a ChangeNotifier: when the user picks a
/// new theme on the Settings screen, `notifyListeners()` fires and
/// `MaterialApp` (which watches this provider in `main.dart`) rebuilds with
/// the new `ThemeData`, instantly restyling every screen currently on
/// screen — no navigation or restart required.
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _accentColorKey = 'accentColor';

  ThemeMode _themeMode = ThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.blue;

  ThemeMode get themeMode => _themeMode;
  AppAccentColor get accentColor => _accentColor;

  ThemeData get lightTheme => AppTheme.light(_accentColor);
  ThemeData get darkTheme => AppTheme.dark(_accentColor);

  /// Loads any previously saved preferences. Called once at app startup.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }

    final savedAccent = prefs.getString(_accentColorKey);
    if (savedAccent != null) {
      _accentColor = AppAccentColor.values.firstWhere(
        (accent) => accent.name == savedAccent,
        orElse: () => AppAccentColor.blue,
      );
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setAccentColor(AppAccentColor accent) async {
    _accentColor = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, accent.name);
  }
}

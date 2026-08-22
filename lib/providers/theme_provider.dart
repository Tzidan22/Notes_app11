import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  ThemeMode _themeMode = ThemeMode.system;
  AppAccent _accent = AppAccent.blue;

  ThemeMode get themeMode => _themeMode;
  AppAccent get accent => _accent;
  ThemeData get lightTheme => AppTheme.build(_accent, Brightness.light);
  ThemeData get darkTheme => AppTheme.build(_accent, Brightness.dark);

  Future<void> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final mode = preferences.getString(_themeModeKey);
    final accentIndex = preferences.getInt(_accentKey);

    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (accentIndex != null && accentIndex >= 0 && accentIndex < AppAccent.values.length) {
      _accent = AppAccent.values[accentIndex];
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }

  Future<void> setAccent(AppAccent accent) async {
    _accent = accent;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_accentKey, accent.index);
  }
}

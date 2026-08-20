import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/notes_screen.dart';

Future<void> main() async {
  // Required before doing any async/plugin work (SharedPreferences, sqflite)
  // before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  runApp(NotesApp(themeProvider: themeProvider));
}

class NotesApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const NotesApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Created once, shared by every screen for the app's lifetime.
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => NotesProvider()..loadNotes()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Notes',
            debugShowCheckedModeBanner: false,
            themeMode: theme.themeMode,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            home: const NotesScreen(),
          );
        },
      ),
    );
  }
}

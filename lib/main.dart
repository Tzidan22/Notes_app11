import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/notes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initialize();
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
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => NotesProvider()..loadNotes()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Notes',
          debugShowCheckedModeBanner: false,
          themeMode: theme.themeMode,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          home: const NotesScreen(),
        ),
      ),
    );
  }
}

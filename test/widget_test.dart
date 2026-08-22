// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes_app/main.dart';
import 'package:flutter_notes_app/providers/theme_provider.dart';

void main() {
  testWidgets('renders the notes app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      NotesApp(themeProvider: ThemeProvider()),
    );

    expect(find.text('My Notes'), findsOneWidget);
    expect(find.byTooltip('New note'), findsOneWidget);
  });
}

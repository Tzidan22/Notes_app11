import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes_app/models/note.dart';
import 'package:flutter_notes_app/screens/note_editor_screen.dart';

void main() {
  testWidgets('opens a new note editor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoteEditorScreen()),
    );

    expect(find.text('New Note'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('opens an existing plain text note', (WidgetTester tester) async {
    final note = Note(
      id: 1,
      title: 'Plain text note',
      content: 'Important\nTask',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(note: note)),
    );

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Plain text note'), findsOneWidget);
  });

  testWidgets('keeps Markdown characters as plain text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoteEditorScreen()),
    );

    final editor = find.byType(EditableText).last;
    await tester.tap(editor);
    await tester.enterText(editor, '# Title\n- Task');
    await tester.pump();

    expect(find.text('New Note'), findsOneWidget);
    expect((editor.evaluate().single.widget as EditableText).controller.text,
        '# Title\n- Task');
  });

  testWidgets('keeps inline Markdown characters as plain text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoteEditorScreen()),
    );

    final editor = find.byType(EditableText).last;
    await tester.tap(editor);
    await tester.enterText(editor, 'First line\n**bold**');
    await tester.pump();

    expect(find.text('New Note'), findsOneWidget);
    expect((editor.evaluate().single.widget as EditableText).controller.text,
        'First line\n**bold**');
  });
}

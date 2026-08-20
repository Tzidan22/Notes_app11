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

  testWidgets('opens an existing Markdown note', (WidgetTester tester) async {
    final note = Note(
      id: 1,
      title: 'Markdown note',
      content: '# Heading\n\n**Important**\n\n- Task',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(note: note)),
    );

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Markdown note'), findsOneWidget);
  });

  testWidgets('formats Markdown shortcuts without range errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoteEditorScreen()),
    );

    final editor = find.byType(EditableText).last;
    await tester.tap(editor);
    await tester.enterText(editor, '# ');
    await tester.enterText(editor, 'Title');
    await tester.enterText(editor, '\n- ');
    await tester.enterText(editor, 'Task');
    await tester.pump();

    expect(find.text('New Note'), findsOneWidget);
  });
}

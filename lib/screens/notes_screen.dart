import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/empty_notes.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  Future<void> _openEditor(BuildContext context, {Note? note}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, Note note) async {
    final notesProvider = context.read<NotesProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          'This will permanently delete "${note.title.trim().isEmpty ? 'Untitled' : note.title}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || note.id == null) return;
    await notesProvider.deleteNote(note.id!);
    if (!context.mounted) return;

    if (notesProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notesProvider.errorMessage!)),
      );
      notesProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) =>
            _buildBody(context, notesProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotesProvider notesProvider) {
    final notes = notesProvider.notes;

    if (notesProvider.status == NotesStatus.loading && notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notesProvider.status == NotesStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(notesProvider.errorMessage ?? 'Something went wrong.'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: notesProvider.loadNotes, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (notes.isEmpty) {
      return EmptyNotes(onCreateNote: () => _openEditor(context));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => _openEditor(context, note: note),
          onDelete: () => _confirmAndDelete(context, note),
        );
      },
    );
  }
}

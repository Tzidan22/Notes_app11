import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/empty_notes.dart';
import '../widgets/note_card.dart';
import '../widgets/notes_search_bar.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

/// The home screen: app bar, search field, and the scrollable list of
/// notes. This screen owns no note data itself — it reads everything from
/// [NotesProvider] via `Consumer`/`context.watch`, so whenever the provider
/// calls `notifyListeners()` (after any create/update/delete/search), this
/// screen rebuilds automatically with the fresh data.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Always dispose controllers to avoid leaking resources.
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor({Note? note}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    // No manual refresh call needed here: NotesProvider already reloaded
    // its own state as part of add/updateNote before this screen is popped
    // back to, and this screen is listening to that provider.
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

    final deleted = await notesProvider.deleteNote(note.id!);

    if (!context.mounted) return;

    if (deleted != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notesProvider.addNote(deleted),
          ),
        ),
      );
    } else if (notesProvider.errorMessage != null) {
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: NotesSearchBar(
                  controller: _searchController,
                  onChanged: notesProvider.searchNotes,
                  onClear: notesProvider.clearSearch,
                ),
              ),
              Expanded(
                child: _buildBody(context, notesProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotesProvider notesProvider) {
    if (notesProvider.status == NotesStatus.loading && notesProvider.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notesProvider.status == NotesStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                notesProvider.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => notesProvider.loadNotes(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (notesProvider.notes.isEmpty) {
      return EmptyNotes(
        isSearchResult: notesProvider.isSearching,
        onCreateNote: notesProvider.isSearching ? null : () => _openEditor(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: notesProvider.notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final note = notesProvider.notes[index];
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) async {
            // We intercept the dismiss so we can show a confirmation dialog
            // first; the actual delete happens inside _confirmAndDelete via
            // the provider, and we always return false here so Dismissible
            // never removes the tile itself — the list rebuilds naturally
            // once the provider's state changes.
            await _confirmAndDelete(context, note);
            return false;
          },
          child: NoteCard(
            note: note,
            onTap: () => _openEditor(note: note),
          ),
        );
      },
    );
  }
}

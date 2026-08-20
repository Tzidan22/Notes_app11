import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

/// Whether the last database operation succeeded, failed, or hasn't
/// finished yet. The UI uses this to show loading/error states.
enum NotesStatus { loading, loaded, error }

/// Holds the app's note data in memory and keeps the UI in sync with it.
///
/// This is the single source of truth for "what notes exist right now".
/// Screens never talk to the database directly — they call methods on this
/// provider, and the provider talks to [DatabaseHelper]. After every
/// successful write, the provider re-reads its full note list and calls
/// [notifyListeners], which makes every widget listening via `Consumer` or
/// `context.watch` rebuild automatically. That's the mechanism behind
/// "no manual refresh needed" — the UI is just a reflection of this state.
class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Note> _notes = []; // the full, unfiltered list loaded from SQLite
  List<Note> _filteredNotes = []; // what the UI actually displays
  String _searchQuery = '';
  NotesStatus _status = NotesStatus.loading;
  String? _errorMessage;

  /// The notes the UI should display — either all notes, or the ones
  /// matching the current search query.
  List<Note> get notes => _filteredNotes;

  NotesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;

  /// Loads (or reloads) all notes from the database.
  /// Call this once on app start; every other CRUD method calls it
  /// internally afterward so callers never need to call it manually again.
  Future<void> loadNotes() async {
    _status = NotesStatus.loading;
    notifyListeners();
    try {
      _notes = await _db.getNotes();
      _applySearch();
      _status = NotesStatus.loaded;
    } catch (e) {
      _errorMessage = 'Could not load notes. Please try again.';
      _status = NotesStatus.error;
    }
    notifyListeners();
  }

  /// Creates a new note in the database, then refreshes state.
  Future<bool> addNote(Note note) async {
    try {
      await _db.insertNote(note);
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Could not save the note. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing note in the database, then refreshes state.
  Future<bool> updateNote(Note note) async {
    if (note.id == null) {
      _errorMessage = 'Cannot update a note that was never saved.';
      notifyListeners();
      return false;
    }
    try {
      await _db.updateNote(note);
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Could not update the note. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a note by id, then refreshes state.
  /// Returns the deleted Note (so the UI can offer "Undo"), or null if the
  /// delete failed.
  Future<Note?> deleteNote(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return null;
    final removed = _notes[index];
    try {
      await _db.deleteNote(id);
      await loadNotes();
      return removed;
    } catch (e) {
      _errorMessage = 'Could not delete the note. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Filters the currently loaded notes by [query], matching against either
  /// the title or the content, case-insensitively. This does NOT touch the
  /// database — it only changes what `notes` returns to the UI.
  void searchNotes(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Clears the active search and restores the full note list.
  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredNotes = List.of(_notes);
      return;
    }
    final query = _searchQuery.trim().toLowerCase();
    _filteredNotes = _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  /// Clears any stored error message (e.g. after the UI has shown it).
  void clearError() {
    _errorMessage = null;
  }
}

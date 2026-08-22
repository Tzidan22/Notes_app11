import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

enum NotesStatus { loading, loaded, error }

class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Note> _notes = [];
  NotesStatus _status = NotesStatus.loading;
  String? _errorMessage;

  List<Note> get notes => _notes;
  NotesStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotes() async {
    _status = NotesStatus.loading;
    notifyListeners();
    try {
      _notes = await _db.getNotes();
      _status = NotesStatus.loaded;
    } catch (e) {
      _errorMessage = 'Could not load notes. Please try again.';
      _status = NotesStatus.error;
    }
    notifyListeners();
  }

  Future<bool> addNote(Note note) =>
      _save(_db.insertNote(note), 'Could not save the note. Please try again.');

  Future<bool> updateNote(Note note) async {
    if (note.id == null) {
      _errorMessage = 'Cannot update a note that was never saved.';
      notifyListeners();
      return false;
    }
    return _save(
      _db.updateNote(note),
      'Could not update the note. Please try again.',
    );
  }

  Future<bool> deleteNote(int id) async {
    try {
      await _db.deleteNote(id);
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = 'Could not delete the note. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _save(Future<dynamic> operation, String errorMessage) async {
    try {
      await operation;
      await loadNotes();
      return true;
    } catch (e) {
      _errorMessage = errorMessage;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
  }
}

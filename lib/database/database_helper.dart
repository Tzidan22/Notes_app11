import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';

/// Singleton wrapper around the app's Hive database.
///
/// Why a singleton? Opening a database connection is relatively expensive
/// and wrapping it in a singleton class keeps all storage details in one
/// place. Every part of the app uses the same box through this helper.
class DatabaseHelper {
  static const String _boxName = 'notes';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// Initializes Hive and opens the notes box.
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      await Hive.openBox<Map>(_boxName);
    }
  }

  Future<Box<Map>> get _box async {
    await initialize();
    return Hive.box<Map>(_boxName);
  }

  // ---------------------------------------------------------------------
  // CRUD operations
  // ---------------------------------------------------------------------

  /// Inserts a new note and returns the Hive key assigned to it.
  Future<int> insertNote(Note note) async {
    final box = await _box;
    final id = await box.add(note.toMap());
    await box.put(id, note.copyWith(id: id).toMap());
    return id;
  }

  /// Returns all notes, most-recently-updated first.
  Future<List<Note>> getNotes() async {
    final box = await _box;
    final notes = box.values
        .map((value) => Note.fromMap(Map<String, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  /// Updates an existing note matched by its Hive key.
  Future<int> updateNote(Note note) async {
    final box = await _box;
    if (!box.containsKey(note.id)) return 0;
    await box.put(note.id, note.toMap());
    return 1;
  }

  /// Deletes a note by id. Returns 1 when a note was deleted.
  Future<int> deleteNote(int id) async {
    final box = await _box;
    if (!box.containsKey(id)) return 0;
    await box.delete(id);
    return 1;
  }
}

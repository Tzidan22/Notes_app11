import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

/// Singleton wrapper around the app's SQLite database.
///
/// Why a singleton? Opening a database connection is relatively expensive
/// and sqflite already caches connections internally, but wrapping it in a
/// singleton class keeps ALL SQL in one place, guarantees we never
/// accidentally open the database twice with different configuration, and
/// gives every part of the app (just the NotesProvider, in this project) a
/// single, simple API: `DatabaseHelper.instance`.
class DatabaseHelper {
  static const String _databaseName = 'notes.db';
  static const int _databaseVersion = 2;
  static const String tableNotes = 'notes';

  // Private constructor — nobody outside this file can create a new
  // DatabaseHelper. The only way to get one is via `DatabaseHelper.instance`.
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // The actual sqflite Database object. It's lazily opened the first time
  // it's needed and then reused for the lifetime of the app.
  static Database? _database;

  /// Returns the open database, opening it first if this is the first call.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        color INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableNotes ADD COLUMN color INTEGER');
    }
  }

  // ---------------------------------------------------------------------
  // CRUD operations
  // ---------------------------------------------------------------------

  /// Inserts a new note and returns the id SQLite assigned to it.
  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert(
      tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all notes, most-recently-updated first.
  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Updates an existing note (matched by id). Returns the number of rows
  /// affected (1 on success, 0 if the id didn't exist).
  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Deletes a note by id. Returns the number of rows affected.
  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete(
      tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Represents a single note stored in the SQLite database.
///
/// This is a plain, immutable data class (no business logic). It knows how
/// to turn itself into a `Map` for SQLite (`toMap`) and how to build itself
/// back up from a database row (`fromMap`). Dates are stored as ISO-8601
/// strings because SQLite has no native DateTime type.
class Note {
  final int? id; // null until the row has been inserted and SQLite assigns one
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? color; // stored as an ARGB int (Color.value); null = no color tag

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  /// Converts this note into a Map so it can be written to SQLite.
  /// `id` is intentionally omitted when null so AUTOINCREMENT can assign it.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
    };
  }

  /// Builds a Note from a raw SQLite row (a Map<String, Object?>).
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      color: map['color'] as int?,
    );
  }

  /// Returns a copy of this note with the given fields replaced.
  /// Useful for updating a note without mutating the original instance.
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? color,
    bool clearColor = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: clearColor ? null : (color ?? this.color),
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title)';
}

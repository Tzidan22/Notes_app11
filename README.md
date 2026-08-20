# Flutter Notes App

A simple, modern, fully offline notes app built with Flutter. Create, edit,
delete, search, and format notes with Markdown — everything is stored
locally in a SQLite database, so it works with no internet connection and
no backend server.

---

## Features

**Core**
- Create, view, edit, and delete notes
- Notes persist in a local SQLite database (survive app restarts)
- Notes list shows title, content preview, and last-updated time
- Swipe-to-delete with a confirmation dialog and an Undo snackbar
- Friendly empty states (no notes yet / no search results)
- Instant UI updates after every create/update/delete — no manual refresh

**Bonus**
- **Search** — filters notes by title or content, case-insensitive, updates as you type
- **Markdown formatting** — Write/Preview tabs in the editor, rendered with `flutter_markdown_plus`
- **Multiple themes** — System/Light/Dark appearance, plus 4 accent colors (Blue, Green, Purple, Orange), all persisted across restarts

**Extras beyond the minimum**
- Optional per-note color tag
- Unsaved-changes confirmation when leaving the editor

---

## Technologies & Packages

| Package | Purpose |
|---|---|
| `sqflite` | Local SQLite database for storing notes |
| `path` | Building the database file path |
| `provider` | State management (`NotesProvider`, `ThemeProvider`) |
| `flutter_markdown_plus` | Rendering Markdown in the note preview |
| `shared_preferences` | Persisting the chosen theme mode & accent color |

> **A note on `flutter_markdown_plus`:** the spec originally called for
> `flutter_markdown`. That package has since been **discontinued** by
> Google. `flutter_markdown_plus` is the actively maintained continuation
> with an identical API (same `Markdown` / `MarkdownBody` widgets), so it
> was used as a drop-in replacement.
>
> **A note on `shared_preferences`:** this wasn't in the original
> dependency list, but it's the standard, simplest way to satisfy "persist
> the selected theme locally" — it's used only for the two small settings
> values (theme mode, accent color), never for note data. All notes remain
> in SQLite.

---

## Project Structure

```
lib/
│
├── main.dart                     # App entry point, provider wiring, MaterialApp
│
├── models/
│   └── note.dart                 # Note data class (fromMap/toMap/copyWith)
│
├── database/
│   └── database_helper.dart      # Singleton SQLite helper — all SQL lives here
│
├── providers/
│   ├── notes_provider.dart       # App state: notes list, CRUD, search
│   └── theme_provider.dart       # App state: theme mode & accent color
│
├── screens/
│   ├── notes_screen.dart         # Home screen: list, search, FAB, swipe-to-delete
│   ├── note_editor_screen.dart   # Create/Edit screen with Write/Preview tabs
│   └── settings_screen.dart      # Appearance, accent color, About
│
├── widgets/
│   ├── note_card.dart            # A single note's card in the list
│   ├── empty_notes.dart          # Empty state (no notes / no results)
│   └── notes_search_bar.dart     # The search text field
│
└── theme/
    └── app_theme.dart            # Centralized ThemeData + accent color palette
```

This mirrors the structure in the project spec, with one small rename:
`widgets/search_bar.dart` → `widgets/notes_search_bar.dart`, to avoid any
naming ambiguity with Flutter's own widgets.

---

## How to Install & Run

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app** (with a device/emulator connected, or a desktop target):
   ```bash
   flutter run
   ```

That's it — no API keys, no backend setup, no environment configuration.
The app works fully offline from the first launch.

---

## How the SQLite Database Works

- `DatabaseHelper` (`database/database_helper.dart`) is a **singleton** —
  there is only ever one instance (`DatabaseHelper.instance`), and it opens
  the database connection lazily the first time it's needed, then reuses
  that same connection for the rest of the app's life. This avoids
  repeatedly opening/closing the database.
- The database file is `notes.db`, with a single table:
  ```sql
  CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      color INTEGER
  );
  ```
- Dates are stored as ISO-8601 strings (`DateTime.toIso8601String()`),
  since SQLite has no native date type.
- `DatabaseHelper` exposes exactly four operations —
  `insertNote`, `getNotes`, `updateNote`, `deleteNote` — and it's the
  **only** file in the app that contains SQL.

---

## How Provider Manages State

- `NotesProvider` (extends `ChangeNotifier`) holds the in-memory list of
  notes and is the single source of truth for "what notes exist right
  now."
- Every write method (`addNote`, `updateNote`, `deleteNote`) follows the
  same pattern:
  1. Write to the database via `DatabaseHelper`
  2. Reload the full note list from the database
  3. Call `notifyListeners()`
- Screens never touch the database directly — they call
  `context.read<NotesProvider>().addNote(...)` etc., and read the current
  list with `context.watch<NotesProvider>()` / `Consumer<NotesProvider>`.
- `ThemeProvider` works the same way for the app's appearance settings.
- Both providers are created once in `main.dart` via `MultiProvider` and
  are available to every screen in the widget tree.

---

## How CRUD Synchronization Works

Because every screen reads notes from `NotesProvider` (never from a local
copy), the "no manual refresh" requirement falls out naturally:

```
User action (create/edit/delete)
        ↓
NotesProvider method runs the DB operation
        ↓
NotesProvider reloads its full note list from SQLite
        ↓
notifyListeners() fires
        ↓
Every widget watching NotesProvider rebuilds automatically
        ↓
The notes list reflects the change immediately
```

No screen ever needs to call `setState` on the list itself, and no
navigation triggers a manual reload — it's all driven by the provider.

---

## How Search Works

- `NotesProvider.searchNotes(query)` filters the **already-loaded** list
  of notes in memory — it does not re-query the database.
- A note matches if its title **or** its content contains the query,
  case-insensitively (`.toLowerCase().contains(...)`).
- The filtered list is what `NotesProvider.notes` returns to the UI, so
  results update on every keystroke.
- Clearing the search (`clearSearch()`) restores the full list. The
  original notes and the database are never modified by searching.

---

## How Markdown Works

- Note content is always stored as **raw Markdown text** in the `content`
  column — never converted to HTML or anything else.
- The editor (`NoteEditorScreen`) has two tabs:
  - **Write** — a plain multi-line text field for typing Markdown
  - **Preview** — renders the current text live using `MarkdownBody`
    from `flutter_markdown_plus`
- Supported syntax includes headings, bold, italic, strikethrough,
  bullet/numbered lists, links, blockquotes, inline code, code blocks,
  and horizontal rules (all handled by the underlying `markdown` package
  that `flutter_markdown_plus` is built on).
- The notes list preview strips Markdown syntax characters (via regex)
  so cards show clean, readable text instead of raw `#`/`**`/`- `
  characters — this is purely a display transformation; the stored
  content is untouched.

---

## How the Theme System Works

- `AppTheme` (`theme/app_theme.dart`) is the **only** place `ThemeData`
  is constructed. Every screen and widget reads colors from
  `Theme.of(context).colorScheme` — no widget hardcodes a `Color` value.
- Four accent colors (Blue, Green, Purple, Orange) are defined as seed
  colors. `ColorScheme.fromSeed()` (Material 3) expands each seed into a
  full, harmonious color palette for both light and dark brightness.
- `ThemeProvider` holds the current `ThemeMode` (system/light/dark) and
  accent color, and persists both to `SharedPreferences` so they survive
  an app restart.
- `MaterialApp` in `main.dart` watches `ThemeProvider` via a `Consumer`,
  so picking a new theme mode or accent color on the Settings screen
  instantly restyles the entire app — no restart or navigation needed.

---

## Final Requirements Checklist

### Database
- [x] Can create note
- [x] Can read notes
- [x] Can update note
- [x] Can delete note
- [x] Notes remain after restarting app (SQLite-backed, singleton connection)

### UI
- [x] Notes list loads correctly
- [x] Empty state works (no notes / no search results)
- [x] Create screen works
- [x] Edit screen works (pre-fills existing title/content)
- [x] Delete works (swipe + confirmation dialog + Undo)
- [x] Navigation works (Notes ↔ Editor ↔ Settings)

### Synchronization
- [x] New note immediately appears in list
- [x] Edited note immediately updates in list
- [x] Deleted note immediately disappears
- [x] No manual refresh required

### Search
- [x] Searches title
- [x] Searches content
- [x] Case insensitive
- [x] Empty results handled ("No notes found")
- [x] Search can be cleared

### Markdown
- [x] Headings work
- [x] Bold works
- [x] Italic works
- [x] Strikethrough works
- [x] Lists (bullet & numbered) work
- [x] Links work (tap shows the target; no external launch dependency)
- [x] Blockquotes work
- [x] Inline code & code blocks work
- [x] Horizontal rules work
- [x] Write/Preview toggle works

### Theme
- [x] Light mode
- [x] Dark mode
- [x] System mode
- [x] 4 accent colors (Blue, Green, Purple, Orange)
- [x] Theme changes update the whole UI instantly
- [x] Theme choice persists across restarts

### Code quality
- [x] Null safety throughout
- [x] Controllers and tab controllers disposed correctly
- [x] Async database operations awaited correctly
- [x] Provider connected correctly (MultiProvider in main.dart)
- [x] No SQL or business logic duplicated across files
- [x] Validation before saving (title or content required)
- [x] User-friendly error messages (no raw exceptions shown)
- [x] No known UI overflow issues (scrollable editor, ellipsis on card text)

---

## Version

**1.0.0** — Built with Flutter.

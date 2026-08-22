# Flutter Notes App

A small offline notes app built with Flutter. Notes are stored locally in Hive.

## Features

- Create, edit, and delete notes
- Plain text title and multiline content
- Notes persist across app restarts
- Notes sorted by last update
- Swipe-to-delete with confirmation and undo
- Unsaved-changes confirmation when leaving the editor

The app intentionally has no search, Markdown formatting, rich-text editor,
link launching, themes, settings, or per-note formatting controls.

## Run

```bash
flutter pub get
flutter run
```

## Structure

- `lib/models` contains the note data model.
- `lib/database` contains the Hive storage helper.
- `lib/providers` contains the note state provider.
- `lib/screens` contains the notes list and plain text editor.
- `lib/widgets` contains the note card and empty state.

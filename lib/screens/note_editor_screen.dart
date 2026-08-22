import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final String _initialTitle;
  late final String _initialContent;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _initialTitle = _titleController.text;
    _initialContent = _contentController.text;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _titleController.text != _initialTitle ||
      _contentController.text != _initialContent;

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title or some content.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<NotesProvider>();
    final now = DateTime.now();
    final success = _isEditing
        ? await provider.updateNote(widget.note!.copyWith(
            title: title,
            content: content,
            updatedAt: now,
          ))
        : await provider.addNote(Note(
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
          ));

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Could not save the note.')),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _confirmDiscardIfNeeded() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : TextButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  maxLines: 1,
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: 'Write your note...', border: InputBorder.none),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

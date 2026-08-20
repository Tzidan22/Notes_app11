import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';

/// A single screen used for BOTH creating and editing a note.
///
/// The mode is decided purely by whether [note] is null:
/// - `note == null`  -> "New Note" (create mode)
/// - `note != null`  -> "Edit Note" (edit mode, pre-fills the fields)
///
/// This avoids having two nearly-identical screens (no duplicated UI
/// logic), which is one of the code-quality requirements in the spec.
class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final QuillController _contentController;
  bool _formattingShortcut = false;

  int? _selectedColor; // null = no color tag
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  // Snapshot of the original values, used to detect unsaved changes.
  late final String _initialTitle;
  late final String _initialContent;
  late final int? _initialColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    final markdownDocument = md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
    final markdownToDelta = MarkdownToDelta(
      markdownDocument: markdownDocument,
      softLineBreak: true,
    );
    final content = widget.note?.content ?? '';
    final document = _documentFromMarkdown(content, markdownToDelta);
    _contentController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleEditorChanged);
    _selectedColor = widget.note?.color;

    _initialTitle = _titleController.text;
    _initialContent = _markdownContent;
    _initialColor = _selectedColor;
  }

  Document _documentFromMarkdown(String content, MarkdownToDelta converter) {
    if (content.trim().isEmpty) return Document();
    try {
      return Document.fromDelta(converter.convert(content));
    } catch (_) {
      // Keep legacy or partially-written content editable instead of allowing
      // one malformed Markdown document to crash the editor screen.
      return Document.fromDelta(
        Delta()
          ..insert(content)
          ..insert('\n'),
      );
    }
  }

  @override
  void dispose() {
    // Always dispose controllers/tickers to avoid memory leaks.
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _titleController.text != _initialTitle ||
        _markdownContent != _initialContent ||
        _selectedColor != _initialColor;
  }

  String get _markdownContent =>
      DeltaToMarkdown().convert(_contentController.document.toDelta()).trim();

  void _handleEditorChanged() {
    if (_formattingShortcut) return;
    _applyBlockShortcut();
    _applyInlineShortcut();
  }

 void _applyBlockShortcut() {
  final selection = _contentController.selection;

  // Only apply shortcuts when there is no selected text.
  if (!selection.isCollapsed) return;

  final text = _contentController.document.toPlainText();
  final cursor = selection.baseOffset;

  if (cursor < 0 || cursor > text.length) return;

  // ------------------------------------------------------------
  // Code block shortcut: ``` + Enter
  // ------------------------------------------------------------
  if (cursor > 0 && text[cursor - 1] == '\n') {
    final previousLineStart =
        text.lastIndexOf('\n', cursor - 2) + 1;

    if (previousLineStart >= 0 &&
        previousLineStart <= cursor - 1) {
      final previousLine =
          text.substring(previousLineStart, cursor - 1);

      if (RegExp(r'^```[\w-]*$').hasMatch(previousLine)) {
        _formattingShortcut = true;

        _contentController.replaceText(
          previousLineStart,
          previousLine.length,
          '',
          TextSelection.collapsed(
            offset: previousLineStart,
          ),
        );

        _contentController.formatText(
          previousLineStart,
          1,
          Attribute.codeBlock,
        );

        _contentController.updateSelection(
          TextSelection.collapsed(
            offset: previousLineStart + 1,
          ),
          ChangeSource.local,
        );

        _formattingShortcut = false;
        return;
      }
    }
  }

  // ------------------------------------------------------------
  // Find current line start safely
  // ------------------------------------------------------------
  final searchIndex = cursor > 0 ? cursor - 1 : 0;

  final previousNewLine = text.lastIndexOf(
    '\n',
    searchIndex,
  );

  final lineStart = previousNewLine == -1
      ? 0
      : previousNewLine + 1;

  if (lineStart > cursor) return;

  final prefix = text.substring(lineStart, cursor);

  // ------------------------------------------------------------
  // Determine block formatting
  // ------------------------------------------------------------
  Attribute? attribute;

  // # Heading
  final headingMatch =
      RegExp(r'^(#{1,6}) $').firstMatch(prefix);

  if (headingMatch != null) {
    final hashes = headingMatch.group(1);

    if (hashes == null || hashes.isEmpty) return;

    final headingLevel = hashes.length;

    const headingAttributes = [
      Attribute.h1,
      Attribute.h2,
      Attribute.h3,
      Attribute.h4,
      Attribute.h5,
      Attribute.h6,
    ];

    // Extra safety against RangeError.
    if (headingLevel < 1 ||
        headingLevel > headingAttributes.length) {
      return;
    }

    attribute = headingAttributes[headingLevel - 1];
  }

  // - Unordered list
  else if (prefix == '- ' ||
      prefix == '* ' ||
      prefix == '+ ') {
    attribute = Attribute.ul;
  }

  // 1. Ordered list
  else if (RegExp(r'^\d+\. $').hasMatch(prefix)) {
    attribute = Attribute.ol;
  }

  // > Quote
  else if (prefix == '> ') {
    attribute = Attribute.blockQuote;
  }

  // Nothing to format
  else {
    return;
  }

  // ------------------------------------------------------------
  // Apply formatting
  // ------------------------------------------------------------
  _formattingShortcut = true;

  try {
    _contentController.replaceText(
      lineStart,
      prefix.length,
      '',
      TextSelection.collapsed(
        offset: lineStart,
      ),
    );

    _contentController.formatText(
      lineStart,
      1,
      attribute,
    );
  } finally {
    _formattingShortcut = false;
  }
}

  void _applyInlineShortcut() {
    final text = _contentController.document.toPlainText();
    final selection = _contentController.selection;
    if (!selection.isCollapsed) return;
    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > text.length) return;
    final lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    final line = text.substring(lineStart, cursor);
    final patterns = <RegExp, Attribute>{
      RegExp(r'\*\*([^*\n]+)\*\*'): Attribute.bold,
      RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'): Attribute.italic,
      RegExp(r'__([^_\n]+)__'): Attribute.bold,
      RegExp(r'(?<!_)_([^_\n]+)_(?!_)'): Attribute.italic,
      RegExp(r'~~([^~\n]+)~~'): Attribute.strikeThrough,
      RegExp(r'`([^`\n]+)`'): Attribute.inlineCode,
    };
    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(line);
      if (match == null || match.end != line.length) continue;
      final start = lineStart + match.start;
      final value = match.group(1)!;
      _formattingShortcut = true;
      _contentController.replaceText(
        start,
        match.end - start,
        value,
        TextSelection.collapsed(offset: start + value.length),
      );
      _contentController.formatText(start, value.length, entry.value);
      _formattingShortcut = false;
      break;
    }
    final link =
        RegExp(r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)').firstMatch(line);
    if (link != null && link.end == line.length) {
      final start = lineStart + link.start;
      final label = link.group(1)!;
      final url = link.group(2)!;
      _formattingShortcut = true;
      _contentController.replaceText(
        start,
        link.end - link.start,
        label,
        TextSelection.collapsed(offset: start + label.length),
      );
      _contentController.formatText(start, label.length, LinkAttribute(url));
      _formattingShortcut = false;
    }
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _markdownContent;

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title or some content.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notesProvider = context.read<NotesProvider>();
    final now = DateTime.now();
    bool success;

    if (_isEditing) {
      final updated = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        color: _selectedColor,
        clearColor: _selectedColor == null,
      );
      success = await notesProvider.updateNote(updated);
    } else {
      final newNote = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        color: _selectedColor,
      );
      success = await notesProvider.addNote(newNote);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(notesProvider.errorMessage ?? 'Could not save the note.'),
        ),
      );
      notesProvider.clearError();
    }
  }

  void _pickColor() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note color',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _colorSwatch(null),
                    ...AppTheme.noteColors
                        .map((c) => _colorSwatch(c.toARGB32())),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorSwatch(int? colorValue) {
    final isSelected = _selectedColor == colorValue;
    return InkWell(
      onTap: () {
        setState(() => _selectedColor = colorValue);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorValue != null ? Color(colorValue) : null,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: colorValue == null
            ? const Icon(Icons.not_interested_rounded, size: 20)
            : (isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardIfNeeded();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.palette_outlined,
                color: _selectedColor != null ? Color(_selectedColor!) : null,
              ),
              tooltip: 'Note color',
              onPressed: _pickColor,
            ),
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(child: _buildEditor(context)),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 1,
          ),
        ),
        Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: QuillEditor.basic(
              controller: _contentController,
              config: QuillEditorConfig(
                placeholder: 'Write your note...',
                padding: const EdgeInsets.all(4),
                expands: false,
                autoFocus: false,
                onLaunchUrl: _openUrl,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

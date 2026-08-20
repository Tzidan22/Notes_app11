import 'package:flutter/material.dart';

import '../models/note.dart';

/// Renders a single [Note] as a tappable card in the notes list.
/// Shows the title, a one-line content preview (with Markdown syntax
/// characters stripped so the preview reads cleanly), the relative
/// "updated" time, and an optional color indicator strip.
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  /// Removes common Markdown syntax so the list preview shows readable
  /// plain text instead of raw "# " / "**" / "- " characters.
  ///
  /// Note: `String.replaceAll(RegExp, String)` treats the replacement as a
  /// literal string — it does NOT substitute `$1` with a capture group.
  /// `replaceAllMapped` is required whenever the replacement needs to keep
  /// part of what was matched (e.g. turning "**bold**" into "bold").
  String _plainPreview(String markdown) {
    var text = markdown
      .replaceAllMapped(RegExp(r'```(?:\w+)?\s*([\s\S]*?)```'),
        (m) => m[1] ?? '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m[1] ?? '')
      .replaceAllMapped(RegExp(r'__(.*?)__'), (m) => m[1] ?? '')
      .replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)(.*?)\*(?!\*)'),
        (m) => m[1] ?? '')
      .replaceAllMapped(RegExp(r'(?<!_)_(?!_)(.*?)_(?!_)'),
        (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m[1] ?? '')
        .replaceAllMapped(RegExp(r'`(.*?)`'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'^>\s?', multiLine: true), '')
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    return text;
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    // Fall back to a plain date for anything older than a week.
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _plainPreview(note.content);
    final hasTitle = note.title.trim().isNotEmpty;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.color != null) ...[
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Color(note.color!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTitle ? note.title : 'Untitled',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasTitle
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Updated ${_relativeTime(note.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

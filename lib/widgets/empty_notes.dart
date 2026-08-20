import 'package:flutter/material.dart';

/// Friendly empty state shown when there are no notes yet (no notes at all)
/// or when a search returns zero results. The two cases are visually
/// distinguished via [isSearchResult].
class EmptyNotes extends StatelessWidget {
  final bool isSearchResult;
  final VoidCallback? onCreateNote;

  const EmptyNotes({
    super.key,
    this.isSearchResult = false,
    this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearchResult ? Icons.search_off_rounded : Icons.note_add_rounded,
              size: 72,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchResult ? 'No notes found' : 'No notes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                  ? 'Try a different search term.'
                  : 'Create your first note to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
            ),
            if (!isSearchResult && onCreateNote != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateNote,
                icon: const Icon(Icons.add),
                label: const Text('New Note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

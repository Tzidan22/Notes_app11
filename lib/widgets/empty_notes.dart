import 'package:flutter/material.dart';

class EmptyNotes extends StatelessWidget {
  final VoidCallback? onCreateNote;

  const EmptyNotes({super.key, this.onCreateNote});

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
              Icons.note_add_rounded,
              size: 72,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
            ),
            if (onCreateNote != null) ...[
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

import 'package:flutter/material.dart';

/// A search field styled to match the app's rounded, filled input theme.
/// Purely presentational — it just forwards text changes and a "clear" tap
/// to its callbacks; the NotesScreen owns the actual controller and query
/// state.
class NotesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const NotesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search notes...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear search',
              onPressed: () {
                controller.clear();
                onClear();
              },
            );
          },
        ),
      ),
    );
  }
}

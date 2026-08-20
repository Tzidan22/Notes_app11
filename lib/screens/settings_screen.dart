import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Lets the user choose the app's appearance (System/Light/Dark) and
/// accent color, and shows a short About section.
///
/// Every control here writes straight through to [ThemeProvider], which
/// persists the choice and calls `notifyListeners()` — that's what makes
/// the whole app restyle immediately, without needing to pop back to the
/// notes screen first.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Appearance'),
          _ThemeModeOption(
            label: 'System',
            icon: Icons.brightness_auto_rounded,
            mode: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: themeProvider.setThemeMode,
          ),
          _ThemeModeOption(
            label: 'Light',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: themeProvider.setThemeMode,
          ),
          _ThemeModeOption(
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: themeProvider.setThemeMode,
          ),
          const Divider(height: 32),
          _SectionHeader('Accent Color'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppAccentColor.values.map((accent) {
                final isSelected = themeProvider.accentColor == accent;
                return _AccentSwatch(
                  accent: accent,
                  isSelected: isSelected,
                  onTap: () => themeProvider.setAccentColor(accent),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 32),
          _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.notes_rounded),
            title: Text('Notes App'),
            subtitle: Text('Version 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.flutter_dash_rounded),
            title: Text('Built with Flutter'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// A single "System / Light / Dark" choice, rendered as a plain selectable
/// ListTile rather than a `RadioListTile`. `RadioListTile.groupValue` /
/// `.onChanged` were deprecated in newer Flutter releases in favor of a
/// `RadioGroup` ancestor widget — but a ListTile with a manually-drawn
/// selection icon is simpler to read for a student project and avoids
/// depending on a very recent Flutter API that older installs may not have.
class _ThemeModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
      selected: isSelected,
      onTap: () => onChanged(mode),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AppAccentColor accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.seedColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(accent.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioGroup<ThemeMode>(
            groupValue: themeProvider.themeMode,
            onChanged: (mode) {
              if (mode != null) themeProvider.setThemeMode(mode);
            },
            child: const Column(
              children: [
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text('System default'),
                ),
                RadioListTile(value: ThemeMode.light, title: Text('Light')),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Accent color', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppAccent.values.map((accent) {
              final selected = accent == themeProvider.accent;
              return ChoiceChip(
                label: Text(accent.label),
                selected: selected,
                avatar: CircleAvatar(backgroundColor: accent.color),
                onSelected: (_) => themeProvider.setAccent(accent),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

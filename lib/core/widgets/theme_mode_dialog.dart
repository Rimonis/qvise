// lib/core/widgets/theme_mode_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';

// Helper functions
IconData _getThemeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
    ThemeMode.system => Icons.brightness_auto,
  };
}

String _getThemeName(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
}

/// A dialog for selecting the application's theme mode.
class ThemeModeDialog extends ConsumerWidget {
  const ThemeModeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: themeModeAsync.when(
        data: (currentMode) => Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeName(mode)),
              secondary: Icon(_getThemeIcon(mode)),
              value: mode,
              groupValue: currentMode,
              // Directly call the notifier and close the dialog.
              onChanged: (ThemeMode? value) {
                if (value != null && value != currentMode) {
                  ref.read(themeModeNotifierProvider.notifier).setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Text('Error: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
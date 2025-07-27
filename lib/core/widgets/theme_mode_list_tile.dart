// lib/core/widgets/theme_mode_list_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';
import 'package:qvise/core/widgets/theme_mode_dialog.dart';

// Helper functions (can be placed at the top level).
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

// Widget for theme mode selection
class ThemeModeListTile extends ConsumerWidget {
  const ThemeModeListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => ListTile(
        leading: Icon(_getThemeIcon(themeMode)),
        title: const Text('Theme'),
        subtitle: Text(_getThemeName(themeMode)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => showDialog(
          context: context,
          builder: (context) => const ThemeModeDialog(),
        ),
      ),
      loading: () => const ListTile(
        leading: Icon(Icons.brightness_auto),
        title: Text('Theme'),
        subtitle: Text('Loading...'),
        trailing: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Theme'),
        subtitle: const Text('Error loading theme'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(themeModeNotifierProvider.notifier).refreshTheme(),
        ),
      ),
    );
  }
}
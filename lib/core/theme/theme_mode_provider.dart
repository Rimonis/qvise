// lib/core/theme/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

// Provider for the theme mode notifier
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const String _themeModeKey = 'theme_mode';
  SharedPreferences? _prefs;

  @override
  Future<ThemeMode> build() async {
    _prefs = await SharedPreferences.getInstance();
    final savedThemeIndex = _prefs?.getInt(_themeModeKey);
    
    if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
      return ThemeMode.values[savedThemeIndex];
    }
    
    // Default to system theme
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _prefs?.setInt(_themeModeKey, themeMode.index);
    state = AsyncValue.data(themeMode);
  }

  Future<void> toggleTheme() async {
    final currentTheme = state.valueOrNull ?? ThemeMode.system;
    final newTheme = switch (currentTheme) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(newTheme);
  }

  Future<void> refreshTheme() async {
    ref.invalidateSelf();
  }
}

// Utility functions
IconData _getThemeIcon(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.brightness_high,
    ThemeMode.dark => Icons.brightness_2,
  };
}

String _getThemeName(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

// Theme picker dialog
class ThemePickerDialog extends ConsumerWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeMode.values.map((themeMode) {
          return themeModeAsync.when(
            data: (currentTheme) => RadioListTile<ThemeMode>(
              title: Row(
                children: [
                  Icon(_getThemeIcon(themeMode)),
                  const SizedBox(width: 12),
                  Text(_getThemeName(themeMode)),
                ],
              ),
              value: themeMode,
              groupValue: currentTheme,
              onChanged: (value) async {
                if (value != null) {
                  await ref.read(themeModeNotifierProvider.notifier).setThemeMode(value);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
            loading: () => const ListTile(
              title: Text('Loading...'),
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const ListTile(
              title: Text('Error loading theme'),
              leading: Icon(Icons.error),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: context.mounted
              ? () => Navigator.of(context).pop()
              : null,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Quick theme toggle button
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => IconButton(
        icon: Icon(_getThemeIcon(themeMode)),
        onPressed: () async {
          // Clear any existing snackbars before toggling theme
          ScaffoldMessenger.of(context).clearSnackBars();
          
          // Schedule the theme change for the next frame to avoid conflicts
          SchedulerBinding.instance.scheduleFrameCallback((_) {
            if (context.mounted) {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            }
          });
        },
        tooltip: 'Toggle theme (${_getThemeName(themeMode)})',
      ),
      loading: () => const IconButton(
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        onPressed: null,
        tooltip: 'Loading theme...',
      ),
      error: (error, _) => IconButton(
        icon: const Icon(Icons.error_outline),
        onPressed: () {
          ref.read(themeModeNotifierProvider.notifier).refreshTheme();
        },
        tooltip: 'Theme error - tap to retry',
      ),
    );
  }
}
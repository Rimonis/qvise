import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'theme_mode_provider.g.dart';

/// An AsyncNotifier that manages and persists the application's theme mode.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const String _key = 'theme_mode';

  /// The build method is called when the provider is first read.
  /// It asynchronously loads the theme mode from SharedPreferences.
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);

    if (savedMode != null) {
      // Find the ThemeMode that matches the saved string.
      return ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedMode,
        orElse: () => ThemeMode.system, // Fallback to system default
      );
    }
    // If no theme is saved, default to system.
    return ThemeMode.system;
  }

  /// Sets the new theme mode, updates the state, and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    // Update the state optimistically.
    state = AsyncValue.data(mode);
    // Persist the new value.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.toString());
  }

  /// Cycles through the available theme modes: Light -> Dark -> System -> Light ...
  void toggleTheme() {
    // Ensure we have a valid current state before toggling.
    if (!state.hasValue) return;

    final currentMode = state.value!;
    final nextMode = switch (currentMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    setThemeMode(nextMode);
  }
}

/// A derived provider that returns a simple boolean indicating if dark mode is active.
/// It correctly handles the 'system' theme by checking the platform's brightness.
@riverpod
bool isDarkMode(Ref ref) {
  final themeMode = ref.watch(themeModeNotifierProvider).value;

  switch (themeMode) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
    case null: // During loading, default to system brightness.
      // Check the actual system brightness.
      return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
  }
}

// Helper functions moved outside the class to be pure functions.
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
    // Use .value to get the data, with a fallback for the initial loading state.
    final themeMode =
        ref.watch(themeModeNotifierProvider).value ?? ThemeMode.system;

    return ListTile(
      leading: Icon(_getThemeIcon(themeMode)),
      title: const Text('Theme'),
      subtitle: Text(_getThemeName(themeMode)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => showDialog(
        context: context,
        builder: (context) => const ThemeModeDialog(),
      ),
    );
  }
}

// Dialog for selecting theme mode
class ThemeModeDialog extends ConsumerWidget {
  const ThemeModeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode =
        ref.watch(themeModeNotifierProvider).value ?? ThemeMode.system;

    return AlertDialog(
      title: const Text('Choose Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeMode.values.map((mode) {
          return RadioListTile<ThemeMode>(
            title: Text(_getThemeName(mode)),
            secondary: Icon(_getThemeIcon(mode)),
            value: mode,
            groupValue: currentMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeModeNotifierProvider.notifier).setThemeMode(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
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

// Quick theme toggle button
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider. It will rebuild the button when the theme changes.
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => IconButton(
        icon: Icon(_getThemeIcon(themeMode)),
        onPressed: () {
          ref.read(themeModeNotifierProvider.notifier).toggleTheme();
        },
        tooltip: 'Toggle theme',
      ),
      // Show a placeholder or disabled button while loading.
      loading: () => const IconButton(
        icon: Icon(Icons.hourglass_empty),
        onPressed: null,
      ),
      error: (err, stack) => const IconButton(
        icon: Icon(Icons.error),
        onPressed: null,
      ),
    );
  }
}
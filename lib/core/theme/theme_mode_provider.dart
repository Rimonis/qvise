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
    try {
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
    } catch (e, stack) {
      // If SharedPreferences fails, emit an error but default to system theme.
      state = AsyncValue.error('Could not load theme', stack);
      return ThemeMode.system;
    }
  }

  /// Sets the new theme mode with proper error handling and persistence.
  Future<void> setThemeMode(ThemeMode mode) async {
    // Update the state optimistically for immediate UI feedback.
    state = AsyncValue.data(mode);
    try {
      // Attempt to persist the new value.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
    } catch (e, stack) {
      // If persistence fails, set the state to an error.
      state = AsyncValue.error('Failed to save theme preference: $e', stack);
    }
  }

  /// Cycles through the available theme modes with improved UX logic.
  void toggleTheme() {
    // Ensure we have a valid current state before toggling.
    if (!state.hasValue) return;

    final currentMode = state.value!;
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    // FIX: The switch expression syntax is corrected for clarity and correctness.
    final nextMode = switch (currentMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      // When in system mode, toggle to the opposite of the current system theme.
      ThemeMode.system =>
        (platformBrightness == Brightness.dark) ? ThemeMode.light : ThemeMode.dark,
    };

    setThemeMode(nextMode);
  }

  /// Force refresh theme from SharedPreferences (useful for error recovery).
  Future<void> refreshTheme() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

/// A derived provider that returns a simple boolean indicating if dark mode is active.
/// It correctly handles the 'system' theme by checking the platform's brightness.
@riverpod
bool isDarkMode(Ref ref) {
  final themeModeAsync = ref.watch(themeModeNotifierProvider);

  // Handle the async state properly.
  return themeModeAsync.when(
    data: (themeMode) {
      return switch (themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        // If system, check the actual platform brightness.
        ThemeMode.system =>
          SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
      };
    },
    // Define fallbacks for loading and error states.
    loading: () =>
        SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
    error: (_, __) =>
        SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
  );
}

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

// Dialog for selecting theme mode
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
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  ref
                      .read(themeModeNotifierProvider.notifier)
                      .setThemeMode(value);
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
        error: (error, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(themeModeNotifierProvider.notifier).refreshTheme();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
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
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => IconButton(
        icon: Icon(_getThemeIcon(themeMode)),
        onPressed: () {
          ref.read(themeModeNotifierProvider.notifier).toggleTheme();
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
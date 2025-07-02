import 'package:flutter/foundation.dart';
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
    // Don't change if already changing or if same mode
    final currentMode = state.valueOrNull;
    if (currentMode == mode) return;
    
    // FIX: Use AsyncValue.guard to prevent setState during build
    state = await AsyncValue.guard(() async {
      // Add a small delay to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Persist the new value first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
      
      // Return the new theme mode
      return mode;
    });
  }

  /// Cycles through the available theme modes with improved UX logic.
  Future<void> toggleTheme() async {
    // Ensure we have a valid current state before toggling
    final currentMode = state.valueOrNull;
    if (currentMode == null) return;

    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    // Determine next mode
    final nextMode = switch (currentMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      // When in system mode, toggle to the opposite of the current system theme.
      ThemeMode.system =>
        (platformBrightness == Brightness.dark) ? ThemeMode.light : ThemeMode.dark,
    };

    // FIX: Use the safer setThemeMode method with a small delay
    await Future.delayed(const Duration(milliseconds: 50));
    await setThemeMode(nextMode);
  }

  /// Force refresh theme from SharedPreferences (useful for error recovery).
  Future<void> refreshTheme() async {
    // FIX: Use ref.invalidateSelf() instead of manually setting state
    ref.invalidateSelf();
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
class ThemeModeDialog extends ConsumerStatefulWidget {
  const ThemeModeDialog({super.key});

  @override
  ConsumerState<ThemeModeDialog> createState() => _ThemeModeDialogState();
}

class _ThemeModeDialogState extends ConsumerState<ThemeModeDialog> {
  bool _isChangingTheme = false;

  Future<void> _changeTheme(ThemeMode value) async {
    if (_isChangingTheme) return;
    
    setState(() {
      _isChangingTheme = true;
    });
    
    // Clear any open snackbars before changing theme
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Close the dialog first
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    // Wait a frame to ensure dialog is closed and UI is stable
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Change the theme
    if (mounted) {
      try {
        await ref.read(themeModeNotifierProvider.notifier).setThemeMode(value);
      } catch (e) {
        // Handle any errors silently
        if (kDebugMode) {
          print('Error changing theme: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return WillPopScope(
      onWillPop: () async => !_isChangingTheme,
      child: AlertDialog(
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
                onChanged: _isChangingTheme 
                  ? null 
                  : (ThemeMode? value) {
                      if (value != null) {
                        _changeTheme(value);
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
            onPressed: _isChangingTheme 
              ? null 
              : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
          
          // Add a small delay to ensure UI is stable
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Toggle theme
          if (context.mounted) {
            ref.read(themeModeNotifierProvider.notifier).toggleTheme();
          }
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
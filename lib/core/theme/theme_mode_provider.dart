// lib/core/theme/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const String _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_key);
    if (savedMode != null) {
      return ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
    return ThemeMode.system;
  }

  /// Sets the new theme mode simply and directly.
  Future<void> setThemeMode(ThemeMode mode) async {
    // Set the state to loading to give feedback in the UI
    state = const AsyncValue.loading();
    
    // Use AsyncValue.guard to handle potential errors during persistence
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.toString());
      return mode;
    });
  }

  /// Cycles through the available theme modes.
  Future<void> toggleTheme() async {
    final currentMode = state.valueOrNull ?? ThemeMode.system;
    final platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    final nextMode = switch (currentMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system =>
        (platformBrightness == Brightness.dark) ? ThemeMode.light : ThemeMode.dark,
    };

    await setThemeMode(nextMode);
  }

  /// Invalidates the provider to force a reload from storage.
  void refreshTheme() {
    ref.invalidateSelf();
  }
}

@riverpod
bool isDarkMode(Ref ref) {
  final themeModeAsync = ref.watch(themeModeNotifierProvider);
  return themeModeAsync.when(
    data: (themeMode) {
      return switch (themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
      };
    },
    loading: () =>
        SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
    error: (_, __) =>
        SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
  );
}

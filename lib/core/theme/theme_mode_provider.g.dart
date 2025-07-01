// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isDarkModeHash() => r'08fe29ad64734017b79e73f1bbd3791115e10045';

/// A derived provider that returns a simple boolean indicating if dark mode is active.
/// It correctly handles the 'system' theme by checking the platform's brightness.
///
/// Copied from [isDarkMode].
@ProviderFor(isDarkMode)
final isDarkModeProvider = AutoDisposeProvider<bool>.internal(
  isDarkMode,
  name: r'isDarkModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isDarkModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDarkModeRef = AutoDisposeProviderRef<bool>;
String _$themeModeNotifierHash() => r'6e9625829ecd8fc22480e35616fae6082a698811';

/// An AsyncNotifier that manages and persists the application's theme mode.
///
/// Copied from [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
  ThemeModeNotifier.new,
  name: r'themeModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeModeNotifier = AsyncNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

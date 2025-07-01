import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qvise/core/routes/app_router.dart';
import 'package:qvise/core/widgets/error_boundary.dart';
import 'package:qvise/core/theme/app_theme.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';
import 'package:qvise/firebase_options.dart';

void main() async {
  // Set up error handling for async errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, print to console
        FlutterError.presentError(details);
      } else {
        // In release mode, log to crash reporting service
        // TODO: Add crash reporting (Firebase Crashlytics, Sentry, etc.)
        if (kDebugMode) {
          print('Flutter error: ${details.exception}');
        }
      }
    };

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization error: $e');
      }
      // Continue running the app even if Firebase fails to initialize
      // The app should handle this gracefully
    }

    runApp(
      ProviderScope(
        child: ErrorBoundary(
          onError: (details) {
            // Log errors to crash reporting in production
            if (!kDebugMode) {
              // TODO: Log to crash reporting service
            }
          },
          child: const MyApp(),
        ),
      ),
    );
  }, (error, stack) {
    // Catch any errors that occur outside of Flutter
    if (kDebugMode) {
      print('Dart error: $error');
      print(stack);
    } else {
      // TODO: Log to crash reporting service
    }
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Properly handle AsyncValue loading states instead of extracting .value
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      // Theme loaded successfully
      data: (themeMode) => MaterialApp.router(
        routerConfig: ref.watch(routerProvider),
        debugShowCheckedModeBanner: false,
        title: 'Qvise',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          // Add any global wrapping widgets here
          return GestureDetector(
            // Dismiss keyboard when tapping outside text fields
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child!,
          );
        },
      ),
      // Loading state - show app with system theme while loading preferences
      loading: () => MaterialApp.router(
        routerConfig: ref.watch(routerProvider),
        debugShowCheckedModeBanner: false,
        title: 'Qvise',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Use system default while loading
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child!,
          );
        },
      ),
      // Error state - fallback to system theme
      error: (error, stackTrace) {
        // Log the error in debug mode
        if (kDebugMode) {
          print('Theme loading error: $error');
          print(stackTrace);
        }
        
        return MaterialApp.router(
          routerConfig: ref.watch(routerProvider),
          debugShowCheckedModeBanner: false,
          title: 'Qvise',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Fallback to system theme
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child!,
            );
          },
        );
      },
    );
  }
}
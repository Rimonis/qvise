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
        options: DefaultFirebaseOptions.currentPlatform
      );
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
    // Watch theme mode from provider
    final themeMode = ref.watch(themeModeNotifierProvider);
    
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
      title: 'Qvise',
      // Use our custom theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Use theme mode from provider
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
    );
  }
}
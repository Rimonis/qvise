import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
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

// Main app widget that handles theme loading
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => _AppMaterialRouter(themeMode: themeMode),
      loading: () => _AppMaterialRouter(themeMode: ThemeMode.system),
      error: (error, stackTrace) {
        if (kDebugMode) {
          print('Theme loading error: $error');
          print(stackTrace);
        }
        return _AppMaterialRouter(themeMode: ThemeMode.system);
      },
    );
  }
}

// Separated MaterialApp widget to prevent unnecessary rebuilds
class _AppMaterialRouter extends ConsumerStatefulWidget {
  final ThemeMode themeMode;

  const _AppMaterialRouter({
    required this.themeMode,
  });

  @override
  ConsumerState<_AppMaterialRouter> createState() => _AppMaterialRouterState();
}

class _AppMaterialRouterState extends ConsumerState<_AppMaterialRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Cache the router to prevent rebuilds
    _router = ref.read(routerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Qvise',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeMode,
      builder: (context, child) {
        // Wrap with error boundary for each route
        return ErrorBoundary(
          errorBuilder: (details) => _ErrorScreen(details: details),
          child: GestureDetector(
            // Dismiss keyboard when tapping outside text fields
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child!,
          ),
        );
      },
    );
  }
}

// Custom error screen for production
class _ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode
                      ? details.exception.toString()
                      : 'An unexpected error occurred. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Text(
                          details.stack.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: () {
                    // In a real app, you might want to restart or navigate to home
                    // For now, we'll just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please restart the app'),
                      ),
                    );
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
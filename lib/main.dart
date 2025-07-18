// lib/main.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/application/sync_coordinator.dart';
import 'package:qvise/core/data/migrations/database_migration.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import 'package:qvise/core/routes/app_router.dart';
import 'package:qvise/core/widgets/error_boundary.dart';
import 'package:qvise/core/theme/app_theme.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';
import 'package:qvise/firebase_options.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (await DatabaseMigration.needsMigration()) {
      print('Migrating to unified database...');
      await DatabaseMigration.migrateToUnifiedDatabase();
      print('Migration complete!');
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization error: $e');
      }
    }

    runApp(
      const ProviderScope(
        child: ErrorBoundary(
          child: MyApp(),
        ),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      print('Dart error: $error');
      print(stack);
    }
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSyncListeners();
      _performInitialSync();
    });
  }

  void _setupSyncListeners() {
    ref.read(networkCallbacksProvider.notifier).addOnlineCallback(() {
      ref.read(syncCoordinatorProvider.notifier).syncAll();
    });
  }

  void _performInitialSync() {
    final isOnline = ref.read(networkStatusProvider).valueOrNull ?? false;
    if (isOnline) {
      ref.read(syncCoordinatorProvider.notifier).syncAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    return themeModeAsync.when(
      data: (themeMode) => _AppMaterialRouter(themeMode: themeMode),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (error, stackTrace) {
        if (kDebugMode) {
          print('Theme loading error: $error');
          print(stackTrace);
        }
        return const _AppMaterialRouter(themeMode: ThemeMode.system);
      },
    );
  }
}

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
    _router = ref.read(routerProvider);
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.ensureVisualUpdate();
    
    return MaterialApp.router(
      key: ValueKey(widget.themeMode),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Qvise',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      builder: (context, child) {
        return ErrorBoundary(
          errorBuilder: (details) => _ErrorScreen(details: details),
          child: GestureDetector(
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
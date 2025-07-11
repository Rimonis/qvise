// lib/main.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/config/app_config.dart';
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/routes/app_router.dart';
import 'package:qvise/core/theme/app_theme.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';
import 'package:qvise/core/widgets/error_boundary.dart';
import 'package:qvise/features/flashcards/application/lesson_event_handler.dart';
import 'package:qvise/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Load environment configuration
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final appConfig = await AppConfig.forEnvironment(env);

    // Initialize services
    await DatabaseHelper.instance.database; // Initializes DB and runs migrations

    // Setup top-level providers and observers
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
      ],
      observers:,
    );

    // Initialize the event handler that listens for cross-feature events
    container.read(lessonEventHandlerProvider).initialize();

    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // This top-level error handler catches errors that might be missed
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      title: ref.watch(appConfigProvider).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.asData?.value?? ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => ErrorBoundary(child: child!),
    );
  }
}

// Simple observer for logging provider changes in debug mode
class AppObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('''
{
  "provider": "${provider.name?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint('Provider ${provider.name?? provider.runtimeType} threw $error at $stackTrace');
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
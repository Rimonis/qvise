import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/shell%20and%20tabs/main_shell_screen.dart';
import 'package:qvise/features/auth/presentation/application/auth_providers.dart';
import 'package:qvise/features/auth/presentation/application/auth_state.dart';
import 'package:qvise/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:qvise/features/auth/presentation/screens/splash_screen.dart';
import 'package:qvise/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:qvise/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_guard.dart';
import 'route_names.dart';

part 'app_router.g.dart';

class GoRouterNotifier extends ChangeNotifier {
  GoRouterNotifier(this._ref) {
    _authSubscription = _ref.listen<AuthState>(
      authProvider,
      (previous, current) {
        if (kDebugMode) {
          print('🟡 Router: Auth state changed from $previous to $current');
        }
        // Notify immediately for navigation
        notifyListeners();
      },
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSubscription;

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouterNotifier goRouterNotifier(Ref ref) {
  return GoRouterNotifier(ref);
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(goRouterNotifierProvider);
  
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) {
      final result = authGuard(ref, state.matchedLocation);
      if (kDebugMode) {
        print('🟡 Router: Location: ${state.matchedLocation} → Redirect: ${result ?? "null (stay)"}');
      }
      return result;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DebugSplashScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EmailVerificationScreen(),
        ),
      ),
      
      // Main app shell (replaces individual content routes)
      GoRoute(
        path: RouteNames.app,
        name: 'app',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MainShellScreen(),
        ),
      ),
      
      // Legacy route redirects for backward compatibility
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        redirect: (context, state) => RouteNames.app,
      ),
      GoRoute(
        path: RouteNames.subjects,
        name: 'subjects',
        redirect: (context, state) => RouteNames.app,
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        redirect: (context, state) => RouteNames.app,
      ),
      
      // Individual lesson detail route (opened from main app)
      GoRoute(
        path: '${RouteNames.lessonDetail}/:lessonId',
        name: 'lesson-detail',
        pageBuilder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          return MaterialPage(
            key: state.pageKey,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Lesson Detail'),
                centerTitle: true,
              ),
              body: Center(
                child: Text('Lesson Detail Screen - ID: $lessonId\nComing Soon'),
              ),
            ),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.app),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
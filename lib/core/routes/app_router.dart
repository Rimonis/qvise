// lib/core/routes/app_router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/shell_and_tabs/main_shell_screen.dart';
import 'package:qvise/features/auth/presentation/application/auth_providers.dart';
import 'package:qvise/features/auth/presentation/application/auth_state.dart';
import 'package:qvise/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:qvise/features/auth/presentation/screens/splash_screen.dart';
import 'package:qvise/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:qvise/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:qvise/features/content/presentation/screens/create_lesson_screen.dart';
import 'package:qvise/features/content/presentation/screens/subject_selection_screen.dart';
import 'package:qvise/features/content/presentation/screens/unlocked_lesson_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_guard.dart';
import 'route_names.dart';

part 'app_router.g.dart';

class GoRouterNotifier extends ChangeNotifier {
  GoRouterNotifier(this._ref) {
    _init();
  }

  final Ref _ref;
  ProviderSubscription<AuthState>? _authSubscription;
  bool _disposed = false;

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _authSubscription = _ref.listen<AuthState>(
          authProvider,
          (previous, current) {
            if (kDebugMode) {
              print('🟡 Router: Auth state changed from $previous to $current');
            }
            if (!_disposed) {
              notifyListeners();
            }
          },
          fireImmediately: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.close();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

@Riverpod(keepAlive: true)
GoRouterNotifier goRouterNotifier(Ref ref) {
  final notifier = GoRouterNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = ref.watch(goRouterNotifierProvider);

  String? lastRedirect;
  int redirectCount = 0;
  const maxRedirects = 5;
  DateTime? lastRedirectTime;

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;
      final now = DateTime.now();

      if (lastRedirectTime != null &&
          now.difference(lastRedirectTime!).inSeconds > 1) {
        redirectCount = 0;
      }
      lastRedirectTime = now;

      if (lastRedirect != currentLocation) {
        redirectCount = 0;
        lastRedirect = currentLocation;
      }

      if (redirectCount >= maxRedirects) {
        if (kDebugMode) {
          print('🔴 Router: Max redirects reached, staying at $currentLocation');
        }
        return null;
      }

      try {
        final result = authGuard(ref, currentLocation);

        if (result != null) {
          redirectCount++;
        }

        if (kDebugMode) {
          print(
              '🟡 Router: Location: $currentLocation → Redirect: ${result ?? "null (stay)"}');
        }

        return result;
      } catch (e, stack) {
        if (kDebugMode) {
          print('🔴 Router: Error in redirect: $e');
          print(stack);
        }
        return null;
      }
    },
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const DebugSplashScreen(),
          name: 'splash',
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const SignInScreen(),
          name: 'login',
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          name: 'forgot-password',
        ),
      ),
      GoRoute(
        path: RouteNames.emailVerification,
        name: 'email-verification',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const EmailVerificationScreen(),
          name: 'email-verification',
        ),
      ),
      GoRoute(
        path: RouteNames.app,
        name: 'app',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const MainShellScreen(),
          name: 'app',
        ),
        routes: [
          GoRoute(
            path: 'lesson/:lessonId',
            name: 'unlocked-lesson',
            pageBuilder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              return _buildPage(
                key: state.pageKey,
                child: UnlockedLessonScreen(lessonId: lessonId),
                name: 'unlocked-lesson-$lessonId',
              );
            },
          ),
          GoRoute(
            path: 'preview/:lessonId',
            name: 'flashcard-preview',
            pageBuilder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final allowEditing = (state.extra as bool?) ?? false;
              return _buildPage(
                key: state.pageKey,
                child: FlashcardPreviewScreen(
                  lessonId: lessonId,
                  allowEditing: allowEditing,
                ),
                name: 'flashcard-preview-$lessonId',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        redirect: (_, __) => RouteNames.app,
      ),
      GoRoute(
        path: RouteNames.subjects,
        name: 'subjects',
        redirect: (_, __) => RouteNames.app,
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        redirect: (_, __) => RouteNames.app,
      ),
      GoRoute(
        path: RouteNames.subjectSelection,
        name: 'subject-selection',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const SubjectSelectionScreen(),
          name: 'subject-selection',
        ),
      ),
      GoRoute(
        path: RouteNames.createLesson,
        name: 'create-lesson',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return _buildPage(
            key: state.pageKey,
            child: CreateLessonScreen(
              initialSubjectName: extra?['subjectName'],
              initialTopicName: extra?['topicName'],
            ),
            name: 'create-lesson',
          );
        },
      ),
    ],
  );
}

Page<dynamic> _buildPage({
  required LocalKey key,
  required Widget child,
  required String name,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    name: name,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

class _RouterErrorPage extends StatelessWidget {
  final Exception? error;

  const _RouterErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Navigation Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode
                    ? error?.toString() ?? 'Unknown navigation error'
                    : 'Unable to navigate to the requested page',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.app),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
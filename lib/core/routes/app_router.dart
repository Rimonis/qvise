// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:qvise/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:qvise/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:qvise/features/content/presentation/screens/unlocked_lesson_screen.dart';
import 'package:qvise/features/flashcards/presentation/screens/flashcard_preview_screen.dart';
import 'package:qvise/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart';
import 'package:qvise/core/shell%20and%20tabs/main_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/sign-in',
    routes: [
      // Authentication routes
      GoRoute(
        path: '/auth/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: 'sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          // Home tab routes
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const SizedBox(), // Home tab content
          ),

          // Browse tab routes
          GoRoute(
            path: '/browse',
            name: 'browse',
            builder: (context, state) => const SizedBox(), // Browse tab content
          ),

          // Study tab routes
          GoRoute(
            path: '/study',
            name: 'study', 
            builder: (context, state) => const SizedBox(), // Study tab content
          ),

          // Profile tab routes
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const SizedBox(), // Profile tab content
          ),

          // Lesson routes
          GoRoute(
            path: '/lesson/:lessonId',
            name: 'lesson-details',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final lesson = state.extra as Lesson?; // Pass lesson object if available
              
              return UnlockedLessonScreen(
                lessonId: lessonId,
                lesson: lesson, // This satisfies the required parameter
              );
            },
          ),

          // Flashcard routes
          GoRoute(
            path: '/lesson/:lessonId/flashcards',
            name: 'flashcard-preview',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final allowEditing = state.uri.queryParameters['edit'] == 'true';
              
              return FlashcardPreviewScreen(
                lessonId: lessonId,
                allowEditing: allowEditing,
              );
            },
          ),

          GoRoute(
            path: '/lesson/:lessonId/flashcards/create',
            name: 'flashcard-creation',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              
              return FlashcardCreationScreen(
                lessonId: lessonId,
              );
            },
          ),

          GoRoute(
            path: '/lesson/:lessonId/flashcards/:flashcardId/edit',
            name: 'flashcard-edit',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final flashcardId = state.pathParameters['flashcardId']!;
              final flashcard = state.extra as Flashcard?;
              
              return FlashcardCreationScreen(
                lessonId: lessonId,
                editingFlashcard: flashcard,
              );
            },
          ),

          // Study session routes
          GoRoute(
            path: '/study-session',
            name: 'study-session',
            builder: (context, state) {
              // Future: Study session screen
              return const Scaffold(
                body: Center(
                  child: Text('Study Session - Coming Soon'),
                ),
              );
            },
          ),

          // Settings routes
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) {
              // Future: Settings screen
              return const Scaffold(
                body: Center(
                  child: Text('Settings - Coming Soon'),
                ),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation extension for easy usage
extension AppNavigation on GoRouter {
  void goToLesson(String lessonId, {Lesson? lesson}) {
    go('/lesson/$lessonId', extra: lesson);
  }

  void goToFlashcardPreview(String lessonId, {bool allowEditing = false}) {
    go('/lesson/$lessonId/flashcards?edit=$allowEditing');
  }

  void goToFlashcardCreation(String lessonId) {
    go('/lesson/$lessonId/flashcards/create');
  }

  void goToFlashcardEdit(String lessonId, String flashcardId, {Flashcard? flashcard}) {
    go('/lesson/$lessonId/flashcards/$flashcardId/edit', extra: flashcard);
  }

  void goToHome() => go('/home');
  void goToBrowse() => go('/browse');
  void goToStudy() => go('/study');
  void goToProfile() => go('/profile');
  void goToSettings() => go('/settings');
  void goToStudySession() => go('/study-session');
}

// Navigation helper widget
class AppNavigationHelper extends ConsumerWidget {
  final Widget child;

  const AppNavigationHelper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }

  static void navigateToLesson(BuildContext context, String lessonId, {Lesson? lesson}) {
    GoRouter.of(context).goToLesson(lessonId, lesson: lesson);
  }

  static void navigateToFlashcards(BuildContext context, String lessonId, {bool allowEditing = false}) {
    GoRouter.of(context).goToFlashcardPreview(lessonId, allowEditing: allowEditing);
  }

  static void navigateToCreateFlashcard(BuildContext context, String lessonId) {
    GoRouter.of(context).goToFlashcardCreation(lessonId);
  }

  static void navigateToEditFlashcard(BuildContext context, String lessonId, String flashcardId, {Flashcard? flashcard}) {
    GoRouter.of(context).goToFlashcardEdit(lessonId, flashcardId, flashcard: flashcard);
  }

  static void navigateBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).goToHome();
    }
  }
}

// Route parameters helper
class RouteParams {
  static String? getLessonId(GoRouterState state) {
    return state.pathParameters['lessonId'];
  }

  static String? getFlashcardId(GoRouterState state) {
    return state.pathParameters['flashcardId'];
  }

  static bool getEditMode(GoRouterState state) {
    return state.uri.queryParameters['edit'] == 'true';
  }

  static T? getExtra<T>(GoRouterState state) {
    return state.extra as T?;
  }
}

// Missing import fix - add these imports
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';

// lib/core/routes/route_names.dart

abstract class RouteNames {
  // Auth routes
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const emailVerification = '/email-verification';

  // Main app route (replaces individual screens)
  static const app = '/app';

  // Lesson creation flow
  static const createLesson = '/create-lesson';
  static const subjectSelection = '/create-lesson-select-subject'; // New

  // Legacy routes (for backward compatibility - all redirect to /app)
  static const home = '/home';
  static const profile = '/profile';
  static const subjects = '/subjects';

  // Individual content routes (accessible from main app)
  static const lessonDetail = '/lesson'; // For individual lesson view
}
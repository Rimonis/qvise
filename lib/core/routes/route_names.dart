abstract class RouteNames {
  // Auth routes
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const emailVerification = '/email-verification';
  
  // Main app route (replaces individual screens)
  static const app = '/app';
  
  // Legacy routes (for backward compatibility - all redirect to /app)
  static const home = '/home';
  static const profile = '/profile';
  static const subjects = '/subjects';
  static const createLesson = '/create-lesson';
  
  // Individual content routes (accessible from main app)
  static const lessonDetail = '/lesson'; // For individual lesson view
}
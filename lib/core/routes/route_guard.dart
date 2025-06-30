import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/application/auth_providers.dart';
import 'route_names.dart';

String? authGuard(Ref ref, String currentLocation) {
  final authState = ref.read(authProvider);
  
  if (kDebugMode) {
    print('Auth Guard - Current: $currentLocation, State: $authState');
  }
  
  // Only stay on splash during initial or loading states
  if (currentLocation == RouteNames.splash) {
    final shouldStayOnSplash = authState.maybeWhen(
      initial: () => true,
      loading: () => true,
      orElse: () => false,
    );
    
    if (shouldStayOnSplash) {
      return null; // Stay on splash
    }
    // Otherwise, let the normal flow handle the redirect
  }
  
  // Define route types
  final isOnAuthPage = currentLocation == RouteNames.login;
  final isOnSplash = currentLocation == RouteNames.splash;
  final isOnEmailVerification = currentLocation == RouteNames.emailVerification;
  final isOnForgotPassword = currentLocation == RouteNames.forgotPassword;
  final isOnMainApp = currentLocation == RouteNames.app;
  
  // Legacy routes (home, subjects, profile) redirect to main app
  final isOnLegacyRoute = currentLocation == RouteNames.home ||
                          currentLocation == RouteNames.subjects ||
                          currentLocation == RouteNames.profile ||
                          currentLocation == RouteNames.createLesson;
  
  // Individual content routes (like lesson detail)
  final isOnContentRoute = currentLocation.startsWith(RouteNames.lessonDetail);
  
  return authState.when(
    initial: () {
      // Stay on splash while initializing
      if (kDebugMode) print('Auth Guard - Initial state');
      return isOnSplash ? null : RouteNames.splash;
    },
    loading: () {
      // During loading, stay on current page
      if (kDebugMode) print('Auth Guard - Loading state');
      return null; // Don't redirect during loading
    },
    unauthenticated: () {
      // Allow access to login and forgot password when unauthenticated
      if (kDebugMode) print('Auth Guard - Unauthenticated');
      
      // Redirect to login from any protected route or splash
      if (isOnMainApp || isOnLegacyRoute || isOnContentRoute || isOnEmailVerification || isOnSplash) {
        return RouteNames.login;
      }
      
      // Stay on login or forgot password pages
      return (isOnAuthPage || isOnForgotPassword) ? null : RouteNames.login;
    },
    emailNotVerified: (user) {
      // Redirect to email verification if email not verified
      if (kDebugMode) print('Auth Guard - Email not verified for ${user.email}');
      
      // Allow access to email verification page only
      if (isOnEmailVerification) return null;
      
      // Redirect from any other page to email verification
      return RouteNames.emailVerification;
    },
    authenticated: (user) {
      // Allow access to all app pages when authenticated
      if (kDebugMode) print('Auth Guard - Authenticated as ${user.email}');
      
      // Redirect to main app if on auth pages or splash
      if (isOnAuthPage || isOnSplash || isOnEmailVerification || isOnForgotPassword) {
        return RouteNames.app;
      }
      
      // Redirect legacy routes to main app
      if (isOnLegacyRoute) {
        return RouteNames.app;
      }
      
      // Allow access to main app and individual content routes
      return null;
    },
    error: (message) {
      // Allow access to login and forgot password on error
      if (kDebugMode) print('Auth Guard - Error: $message');
      
      // Redirect to login if trying to access protected routes
      if (isOnMainApp || isOnLegacyRoute || isOnContentRoute) {
        return RouteNames.login;
      }
      
      return (isOnAuthPage || isOnForgotPassword || isOnSplash) ? null : RouteNames.login;
    },
  );
}
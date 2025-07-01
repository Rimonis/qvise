import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/application/auth_providers.dart';
import 'route_names.dart';

String? authGuard(Ref ref, String currentLocation) {
  try {
    final authState = ref.read(authProvider);
    
    if (kDebugMode) {
      print('Auth Guard - Current: $currentLocation, State: $authState');
    }
    
    // Prevent navigation during build phase
    if (authState == null) {
      return null;
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
        
        // If on splash, stay there
        if (isOnSplash) return null;
        
        // If on auth pages, allow staying there
        if (isOnAuthPage || isOnForgotPassword) return null;
        
        // If authenticated route, allow staying
        if (isOnMainApp || isOnContentRoute || isOnEmailVerification) return null;
        
        // Legacy routes redirect to app
        if (isOnLegacyRoute) return RouteNames.app;
        
        // Default: stay on current page
        return null;
      },
      unauthenticated: () {
        // Allow access to login and forgot password when unauthenticated
        if (kDebugMode) print('Auth Guard - Unauthenticated');
        
        // Auth pages are allowed
        if (isOnAuthPage || isOnForgotPassword) return null;
        
        // Everything else redirects to login
        return RouteNames.login;
      },
      emailNotVerified: (user) {
        // Redirect to email verification if email not verified
        if (kDebugMode) print('Auth Guard - Email not verified for ${user.email}');
        
        // Allow access to email verification page only
        if (isOnEmailVerification) return null;
        
        // Allow sign out from auth pages
        if (isOnAuthPage || isOnForgotPassword) return null;
        
        // Redirect from any other page to email verification
        return RouteNames.emailVerification;
      },
      authenticated: (user) {
        // Allow access to all app pages when authenticated
        if (kDebugMode) print('Auth Guard - Authenticated as ${user.email}');
        
        // Redirect auth pages to main app
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
        // On error, behave like unauthenticated
        if (kDebugMode) print('Auth Guard - Error: $message');
        
        // Auth pages are allowed
        if (isOnAuthPage || isOnForgotPassword || isOnSplash) return null;
        
        // Everything else redirects to login
        return RouteNames.login;
      },
    );
  } catch (e) {
    // If any error occurs in the guard, log it and allow current navigation
    if (kDebugMode) {
      print('Auth Guard - Exception: $e');
    }
    
    // In case of error, default to safe behavior
    // If on auth pages, stay there
    if ([RouteNames.login, RouteNames.forgotPassword, RouteNames.splash].contains(currentLocation)) {
      return null;
    }
    
    // Otherwise redirect to login for safety
    return RouteNames.login;
  }
}
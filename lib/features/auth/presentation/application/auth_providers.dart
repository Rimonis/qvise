// lib/features/auth/presentation/application/auth_providers.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'auth_state.dart';
import '../../domain/entities/user.dart';
import '../../../../core/providers/providers.dart';

part 'auth_providers.g.dart';

// Rate limiting for auth attempts
class AuthRateLimiter {
  static final Map<String, List<DateTime>> _attempts = {};
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration attemptWindow = Duration(minutes: 5);
  
  static bool canAttempt(String identifier) {
    final now = DateTime.now();
    final attempts = _attempts[identifier] ?? [];
    
    attempts.removeWhere((attempt) => 
      now.difference(attempt) > attemptWindow
    );
    
    _attempts[identifier] = attempts;
    
    if (attempts.length >= maxAttempts) {
      final oldestAttempt = attempts.first;
      if (now.difference(oldestAttempt) < lockoutDuration) {
        return false;
      }
      _attempts[identifier] = [];
    }
    
    return true;
  }
  
  static void recordAttempt(String identifier) {
    final attempts = _attempts[identifier] ?? [];
    attempts.add(DateTime.now());
    _attempts[identifier] = attempts;
  }
  
  static int getRemainingAttempts(String identifier) {
    final attempts = _attempts[identifier] ?? [];
    return maxAttempts - attempts.length;
  }
  
  static Duration? getLockoutTimeRemaining(String identifier) {
    final attempts = _attempts[identifier] ?? [];
    if (attempts.length >= maxAttempts) {
      final oldestAttempt = attempts.first;
      final lockoutEnd = oldestAttempt.add(lockoutDuration);
      final remaining = lockoutEnd.difference(DateTime.now());
      if (remaining.isNegative) return null;
      return remaining;
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  Timer? _debounceTimer;
  
  @override
  AuthState build() {
    if (kDebugMode) print('🔵 Auth: Initial state');
    
    ref.listen(authStateChangesProvider, (previous, current) {
      current.when(
        data: (user) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (user != null) {
              if (kDebugMode) print('🟢 Auth: Firebase user detected - ${user.email}');
              _setUserStateFromFirebaseUser(user);
            } else {
              if (kDebugMode) print('🔴 Auth: No Firebase user');
              state = const AuthState.unauthenticated();
            }
          });
        },
        error: (error, stack) {
          if (kDebugMode) print('🔴 Auth: Firebase auth error - $error');
          state = AuthState.error(AppFailure.fromException(error, stack));
        },
        loading: () {
          if (kDebugMode) print('🟡 Auth: Firebase auth loading');
        },
      );
    });
    
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    return const AuthState.initial();
  }

  void _setUserStateFromFirebaseUser(firebase_auth.User firebaseUser) {
    final user = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      subscriptionTier: 'free',
      isEmailVerified: firebaseUser.emailVerified,
    );
    
    if (!firebaseUser.emailVerified && _isEmailPasswordUser(firebaseUser)) {
      state = AuthState.emailNotVerified(user);
    } else {
      state = AuthState.authenticated(user);
    }
  }
  
  bool _isEmailPasswordUser(firebase_auth.User user) {
    return user.providerData.any((info) => 
        info.providerId == firebase_auth.EmailAuthProvider.PROVIDER_ID);
  }

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    try {
      final useCase = await ref.read(getCurrentUserProvider.future);
      final result = await useCase();
      result.fold(
        (failure) => state = const AuthState.unauthenticated(),
        (user) {
          final fbUser = ref.read(firebaseAuthProvider).currentUser;
          if (fbUser != null) {
            _setUserStateFromFirebaseUser(fbUser);
          } else {
            state = AuthState.authenticated(user);
          }
        }
      );
    } catch (e, s) {
      state = AuthState.error(AppFailure.fromException(e, s));
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    if (!AuthRateLimiter.canAttempt(email)) {
      final lockoutTime = AuthRateLimiter.getLockoutTimeRemaining(email);
      final minutes = lockoutTime?.inMinutes ?? 0;
      state = AuthState.error(
        AppFailure(message: 'Too many failed attempts. Please try again in $minutes minutes.')
      );
      return;
    }
    
    state = const AuthState.loading();
    final useCase = await ref.read(signInWithEmailPasswordProvider.future);
    final result = await useCase(email, password);
    
    result.fold(
      (failure) {
        AuthRateLimiter.recordAttempt(email);
        final remainingAttempts = AuthRateLimiter.getRemainingAttempts(email);
        String errorMessage = failure.userFriendlyMessage;
        
        if (remainingAttempts > 0 && remainingAttempts < AuthRateLimiter.maxAttempts) {
          errorMessage += ' ($remainingAttempts attempts remaining)';
        }
        state = AuthState.error(AppFailure(type: failure.type, message: errorMessage));
      },
      (user) {
        // Auth state listener will handle the success state
      }
    );
  }

  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
    state = const AuthState.loading();
    final useCase = await ref.read(signUpWithEmailPasswordProvider.future);
    final result = await useCase(email, password, displayName);
    result.fold(
      (failure) => state = AuthState.error(failure),
      (user) {
        // Auth state listener will handle this
      }
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final useCase = await ref.read(signInWithGoogleProvider.future);
    final result = await useCase();
    result.fold(
      (failure) => state = AuthState.error(failure),
      (user) {
        // Auth state listener will handle this
      }
    );
  }

  Future<void> sendEmailVerification() async {
    final useCase = await ref.read(sendEmailVerificationProvider.future);
    final result = await useCase();
    result.fold(
      (failure) => throw failure, // Let the caller handle UI feedback
      (_) {}
    );
  }

  Future<void> checkEmailVerification() async {
    final useCase = await ref.read(checkEmailVerificationProvider.future);
    await useCase();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final useCase = await ref.read(resetPasswordProvider.future);
    final result = await useCase(email);
    result.fold(
      (failure) => throw failure, // Let the caller handle UI feedback
      (_) {}
    );
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    final useCase = await ref.read(signOutProvider.future);
    await useCase();
    // Auth state listener will set to unauthenticated
  }
}
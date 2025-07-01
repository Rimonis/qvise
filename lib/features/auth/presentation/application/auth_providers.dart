import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    
    // Remove old attempts outside the window
    attempts.removeWhere((attempt) => 
      now.difference(attempt) > attemptWindow
    );
    
    // Update the attempts list
    _attempts[identifier] = attempts;
    
    // Check if user is locked out
    if (attempts.length >= maxAttempts) {
      final oldestAttempt = attempts.first;
      if (now.difference(oldestAttempt) < lockoutDuration) {
        return false;
      }
      // Clear attempts if lockout period has passed
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
    
    // Listen to Firebase auth state changes directly
    ref.listen(authStateChangesProvider, (previous, current) {
      current.when(
        data: (user) {
          // Debounce auth state changes to prevent rapid updates
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (user != null) {
              if (kDebugMode) print('🟢 Auth: Firebase user detected - ${user.email}');
              _setUserStateFromFirebaseUser(user);
            } else {
              if (kDebugMode) print('🔴 Auth: No Firebase user');
              // Only update to unauthenticated if we're not already in that state
              final isNotUnauthenticated = state.maybeWhen(
                unauthenticated: () => false,
                orElse: () => true,
              );
              if (isNotUnauthenticated) {
                state = const AuthState.unauthenticated();
              }
            }
          });
        },
        error: (error, stack) {
          if (kDebugMode) print('🔴 Auth: Firebase auth error - $error');
          state = AuthState.error(error.toString());
        },
        loading: () {
          if (kDebugMode) print('🟡 Auth: Firebase auth loading');
        },
      );
    });
    
    // Clean up timer on dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    return const AuthState.initial();
  }

  void _setUserStateFromFirebaseUser(firebase_auth.User firebaseUser) {
    // Create user entity directly from Firebase user
    final user = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      subscriptionTier: 'free',
      isEmailVerified: firebaseUser.emailVerified,
    );
    
    // Check if email verification is required
    if (!firebaseUser.emailVerified && _isEmailPasswordUser(firebaseUser)) {
      if (kDebugMode) print('🟡 Auth: User needs email verification - ${user.email}');
      state = AuthState.emailNotVerified(user);
    } else {
      if (kDebugMode) print('🟢 Auth: Setting authenticated state for ${user.email}');
      state = AuthState.authenticated(user);
    }
  }
  
  bool _isEmailPasswordUser(firebase_auth.User user) {
    // Check if user signed up with email/password (not Google)
    return user.providerData.any((info) => 
        info.providerId == firebase_auth.EmailAuthProvider.PROVIDER_ID);
  }

  Future<void> checkAuthStatus() async {
    if (kDebugMode) print('🔵 Auth: Checking auth status...');
    
    // Don't set loading state if we're already checking
    final isAlreadyChecking = state.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
    
    if (isAlreadyChecking) {
      if (kDebugMode) print('🟡 Auth: Already checking, skipping...');
      return;
    }
    
    state = const AuthState.loading();
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final currentUser = firebaseAuth.currentUser;
      
      if (currentUser != null) {
        // Reload user to get fresh email verification status
        await currentUser.reload();
        final refreshedUser = firebaseAuth.currentUser!;
        
        if (kDebugMode) print('🟢 Auth: Current user found - ${refreshedUser.email}');
        _setUserStateFromFirebaseUser(refreshedUser);
      } else {
        if (kDebugMode) print('🔴 Auth: No current user');
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Check error - $e');
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    if (kDebugMode) print('🔵 Auth: Starting email sign in for $email');
    
    // Check rate limiting
    if (!AuthRateLimiter.canAttempt(email)) {
      final lockoutTime = AuthRateLimiter.getLockoutTimeRemaining(email);
      final minutes = lockoutTime?.inMinutes ?? 0;
      state = AuthState.error(
        'Too many failed attempts. Please try again in $minutes minutes.'
      );
      return;
    }
    
    state = const AuthState.loading();
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) print('🟢 Auth: Firebase sign in call completed');
      // The auth state listener will handle setting the authenticated state
      
    } catch (e) {
      // Record failed attempt
      AuthRateLimiter.recordAttempt(email);
      
      if (kDebugMode) print('🔴 Auth: Sign in error - $e');
      
      final remainingAttempts = AuthRateLimiter.getRemainingAttempts(email);
      String errorMessage = _parseFirebaseError(e);
      
      if (remainingAttempts > 0 && remainingAttempts < AuthRateLimiter.maxAttempts) {
        errorMessage += ' ($remainingAttempts attempts remaining)';
      }
      
      state = AuthState.error(errorMessage);
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
    if (kDebugMode) print('🔵 Auth: Starting email sign up for $email');
    state = const AuthState.loading();
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      
      // Create user account
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name and send verification email
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.sendEmailVerification();
        await userCredential.user!.reload();
        
        if (kDebugMode) print('🟢 Auth: Sign up completed, verification email sent');
      }
      
      // The auth state listener will handle setting the emailNotVerified state
      
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Sign up error - $e');
      state = AuthState.error(_parseFirebaseError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    if (kDebugMode) print('🔵 Auth: Starting Google sign in');
    state = const AuthState.loading();
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final googleSignIn = ref.read(googleSignInProvider);
      
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) print('🔴 Auth: Google sign in cancelled');
        state = const AuthState.unauthenticated();
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await firebaseAuth.signInWithCredential(credential);
      
      if (kDebugMode) print('🟢 Auth: Google sign in completed');
      // Google accounts are automatically verified, auth state listener will handle this
      
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Google sign in error - $e');
      state = AuthState.error(_parseFirebaseError(e));
    }
  }

  Future<void> sendEmailVerification() async {
    if (kDebugMode) print('🔵 Auth: Sending email verification');
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final currentUser = firebaseAuth.currentUser;
      
      if (currentUser != null && !currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        if (kDebugMode) print('🟢 Auth: Verification email sent');
      } else {
        throw Exception('No user logged in or email already verified');
      }
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Send verification error - $e');
      throw e;
    }
  }

  Future<void> checkEmailVerification() async {
    if (kDebugMode) print('🔵 Auth: Checking email verification');
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final currentUser = firebaseAuth.currentUser;
      
      if (currentUser != null) {
        await currentUser.reload();
        final refreshedUser = firebaseAuth.currentUser!;
        
        if (kDebugMode) print('🔵 Auth: Email verified: ${refreshedUser.emailVerified}');
        _setUserStateFromFirebaseUser(refreshedUser);
      }
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Check verification error - $e');
      state = AuthState.error(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (kDebugMode) print('🔵 Auth: Sending password reset email to $email');
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      await firebaseAuth.sendPasswordResetEmail(email: email);
      
      if (kDebugMode) print('🟢 Auth: Password reset email sent');
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Password reset error - $e');
      throw Exception(_parseFirebaseError(e));
    }
  }

  Future<void> signOut() async {
    if (kDebugMode) print('🔵 Auth: Starting sign out');
    state = const AuthState.loading();
    
    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final googleSignIn = ref.read(googleSignInProvider);
      
      await googleSignIn.signOut();
      await firebaseAuth.signOut();
      
      if (kDebugMode) print('🟢 Auth: Sign out completed');
      
    } catch (e) {
      if (kDebugMode) print('🔴 Auth: Sign out error - $e');
      state = AuthState.error(e.toString());
    }
  }

  String _parseFirebaseError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'operation-not-allowed':
          return 'This sign in method is not enabled.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'requires-recent-login':
          return 'Please sign in again to complete this action.';
        default:
          return error.message ?? 'An unexpected error occurred. Please try again.';
      }
    }
    return error.toString();
  }
}
// lib/features/auth/data/datasources/auth_remote_data_source.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Authentication state
  Stream<firebase_auth.User?> authStateChanges();
  Future<firebase_auth.User?> getCurrentUser();
  
  /// Sign in methods
  Future<UserModel> signInWithEmailPassword(String email, String password);
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  
  /// Sign up methods
  Future<UserModel> signUpWithEmailPassword(String email, String password, String displayName);
  
  /// Sign out
  Future<void> signOut();
  
  /// Password management
  Future<void> sendPasswordResetEmail(String email);
  Future<void> changePassword(String currentPassword, String newPassword);
  
  /// Email verification
  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerification();
  Future<void> reloadUser();
  
  /// Profile management
  Future<void> updateProfile({String? displayName, String? photoUrl});
  Future<void> updateEmail(String newEmail);
  
  /// Account management
  Future<void> deleteAccount();
  Future<void> reauthenticate(String password);
  Future<void> signOutFromAllDevices();
}

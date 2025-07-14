// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Authentication state
  Stream<User?> authStateChanges();
  Future<Either<AppError, User?>> getCurrentUser();
  
  /// Sign in methods
  Future<Either<AppError, User>> signInWithEmailPassword(String email, String password);
  Future<Either<AppError, User>> signInWithGoogle();
  Future<Either<AppError, User>> signInWithApple(); // For iOS
  
  /// Sign up methods
  Future<Either<AppError, User>> signUpWithEmailPassword(String email, String password, String displayName);
  
  /// Sign out
  Future<Either<AppError, void>> signOut();
  
  /// Password management
  Future<Either<AppError, void>> sendPasswordResetEmail(String email);
  Future<Either<AppError, void>> changePassword(String currentPassword, String newPassword);
  
  /// Email verification
  Future<Either<AppError, void>> sendEmailVerification();
  Future<Either<AppError, bool>> checkEmailVerification();
  Future<Either<AppError, void>> reloadUser();
  
  /// Profile management
  Future<Either<AppError, void>> updateProfile({String? displayName, String? photoUrl});
  Future<Either<AppError, void>> updateEmail(String newEmail);
  
  /// Account management
  Future<Either<AppError, void>> deleteAccount();
  Future<Either<AppError, void>> reauthenticate(String password);
  
  /// Device management
  Future<Either<AppError, void>> signOutFromAllDevices();
}

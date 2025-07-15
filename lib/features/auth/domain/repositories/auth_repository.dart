// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<AppFailure, User>> getCurrentUser();
  Future<Either<AppFailure, User>> signInWithEmailPassword(String email, String password);
  Future<Either<AppFailure, User>> signUpWithEmailPassword(String email, String password, String displayName);
  Future<Either<AppFailure, User>> signInWithGoogle();
  Future<Either<AppFailure, void>> signOut();
  
  // Email verification methods
  Future<Either<AppFailure, void>> sendEmailVerification();
  Future<Either<AppFailure, bool>> checkEmailVerification();
  
  // Password reset method
  Future<Either<AppFailure, void>> sendPasswordResetEmail(String email);
}
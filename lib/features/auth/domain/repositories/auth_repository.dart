// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Future<Either<AppError, User>> signInWithEmailPassword(String email, String password);
  Future<Either<AppError, User>> signUpWithEmailPassword(String email, String password, String displayName);
  Future<Either<AppError, User>> signInWithGoogle();
  Future<Either<AppError, void>> signOut();
  Future<Either<AppError, void>> sendPasswordResetEmail(String email);
  Future<Either<AppError, void>> sendEmailVerification();
}
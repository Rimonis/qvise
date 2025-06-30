import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, User>> signInWithEmailPassword(String email, String password);
  Future<Either<Failure, User>> signUpWithEmailPassword(String email, String password, String displayName);
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  
  // Email verification methods
  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, bool>> checkEmailVerification();
  
  // Password reset method
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
}
// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/features/auth/domain/entities/user.dart';
import 'package:qvise/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<User?> authStateChanges() {
    return remoteDataSource.authStateChanges().map((firebaseUser) {
      return firebaseUser!= null? UserModel.fromFirebase(firebaseUser).toEntity() : null;
    });
  }

  @override
  Future<Either<AppError, User>> signInWithEmailPassword(String email, String password) async {
    try {
      final userModel = await remoteDataSource.signInWithEmailPassword(email, password);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AppError.auth(message: e.message?? 'Sign in failed.'));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, User>> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      final userModel = await remoteDataSource.signUpWithEmailPassword(email, password, displayName);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AppError.auth(message: e.message?? 'Sign up failed.'));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }
  
  @override
  Future<Either<AppError, User>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AppError.auth(message: e.message?? 'Google sign in failed.'));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AppError.auth(message: e.message?? 'Password reset failed.'));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AppError.auth(message: e.message?? 'Failed to send verification email.'));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }
}

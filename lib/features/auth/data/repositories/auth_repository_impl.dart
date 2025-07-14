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
      return firebaseUser != null ? UserModel.fromFirebase(firebaseUser).toEntity() : null;
    });
  }

  @override
  Future<Either<AppError, User?>> getCurrentUser() async {
    try {
      final firebaseUser = await remoteDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Right(null);
      }
      final userModel = UserModel.fromFirebase(firebaseUser);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, User>> signInWithEmailPassword(String email, String password) async {
    try {
      final userModel = await remoteDataSource.signInWithEmailPassword(email, password);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
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
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, User>> signInWithApple() async {
    try {
      final userModel = await remoteDataSource.signInWithApple();
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
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
      return Left(_mapFirebaseAuthException(e));
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
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
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
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, bool>> checkEmailVerification() async {
    try {
      final isVerified = await remoteDataSource.checkEmailVerification();
      return Right(isVerified);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> reloadUser() async {
    try {
      await remoteDataSource.reloadUser();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      await remoteDataSource.updateProfile(displayName: displayName, photoUrl: photoUrl);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateEmail(String newEmail) async {
    try {
      await remoteDataSource.updateEmail(newEmail);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> reauthenticate(String password) async {
    try {
      await remoteDataSource.reauthenticate(password);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> signOutFromAllDevices() async {
    try {
      await remoteDataSource.signOutFromAllDevices();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  /// Maps Firebase Auth exceptions to AppError
  AppError _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AppError.auth(message: 'No user found with this email address.');
      case 'wrong-password':
        return const AppError.auth(message: 'Incorrect password.');
      case 'email-already-in-use':
        return const AppError.auth(message: 'An account already exists with this email.');
      case 'weak-password':
        return const AppError.validation(message: 'Password is too weak.');
      case 'invalid-email':
        return const AppError.validation(message: 'Invalid email address.');
      case 'user-disabled':
        return const AppError.auth(message: 'This account has been disabled.');
      case 'too-many-requests':
        return const AppError.auth(message: 'Too many unsuccessful attempts. Please try again later.');
      case 'network-request-failed':
        return const AppError.network(message: 'Network error. Please check your connection.');
      case 'requires-recent-login':
        return const AppError.auth(message: 'Please sign in again to complete this action.');
      case 'email-not-verified':
        return const AppError.auth(message: 'Please verify your email address first.');
      default:
        return AppError.auth(message: e.message ?? 'Authentication failed.');
    }
  }
}

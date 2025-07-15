// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final InternetConnectionChecker connectionChecker;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<AppFailure, User>> getCurrentUser() async {
    return guard(() async {
      try {
        final remoteUser = await remoteDataSource.getCurrentUser();
        await localDataSource.cacheUser(remoteUser);
        return remoteUser.toEntity();
      } catch (e) {
        final localUser = await localDataSource.getCachedUser();
        if (localUser != null) {
          return localUser.toEntity();
        } else {
          throw const AppFailure(type: FailureType.auth, message: 'No user logged in.');
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, User>> signInWithEmailPassword(String email, String password) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      final user = await remoteDataSource.signInWithEmailPassword(email, password);
      await localDataSource.cacheUser(user);
      return user.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, User>> signUpWithEmailPassword(String email, String password, String displayName) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      final user = await remoteDataSource.signUpWithEmailPassword(email, password, displayName);
      await localDataSource.cacheUser(user);
      return user.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, User>> signInWithGoogle() async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      final user = await remoteDataSource.signInWithGoogle();
      await localDataSource.cacheUser(user);
      return user.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, void>> signOut() async {
    return guard(() async {
      await remoteDataSource.signOut();
      await localDataSource.clearCachedUser();
    });
  }

  @override
  Future<Either<AppFailure, void>> sendEmailVerification() async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      await remoteDataSource.sendEmailVerification();
    });
  }

  @override
  Future<Either<AppFailure, bool>> checkEmailVerification() async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      await remoteDataSource.checkEmailVerification();
      final isVerified = await remoteDataSource.isEmailVerified();
      
      if (isVerified) {
        final user = await remoteDataSource.getCurrentUser();
        await localDataSource.cacheUser(user);
      }
      
      return isVerified;
    });
  }

  @override
  Future<Either<AppFailure, void>> sendPasswordResetEmail(String email) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(type: FailureType.network, message: 'No internet connection.');
      }
      await remoteDataSource.sendPasswordResetEmail(email);
    });
  }
}
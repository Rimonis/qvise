import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final InternetConnectionChecker connectionChecker;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(remoteUser);
      return Right(remoteUser.toEntity());
    } catch (e) {
      try {
        final localUser = await localDataSource.getCachedUser();
        if (localUser != null) {
          return Right(localUser.toEntity());
        } else {
          return const Left(AuthFailure('No user logged in'));
        }
      } catch (e) {
        return const Left(AuthFailure('No user logged in'));
      }
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailPassword(String email, String password) async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      final user = await remoteDataSource.signInWithEmailPassword(email, password);
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailPassword(String email, String password, String displayName) async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      final user = await remoteDataSource.signUpWithEmailPassword(email, password, displayName);
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      final user = await remoteDataSource.signInWithGoogle();
      await localDataSource.cacheUser(user);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearCachedUser();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerification() async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      await remoteDataSource.checkEmailVerification();
      final isVerified = await remoteDataSource.isEmailVerified();
      
      // Update cached user if verified
      if (isVerified) {
        final user = await remoteDataSource.getCurrentUser();
        await localDataSource.cacheUser(user);
      }
      
      return Right(isVerified);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    if (!await connectionChecker.hasConnection) {
      return const Left(NetworkFailure('No internet connection'));
    }
    
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
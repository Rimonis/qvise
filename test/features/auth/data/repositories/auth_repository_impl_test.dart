// test/features/auth/data/repositories/auth_repository_impl_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/auth/data/models/user_model.dart';
import 'package:qvise/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qvise/features/auth/domain/entities/user.dart';
import 'package:qvise/core/error/app_failure.dart';

import '../../../../mocks.mocks.dart';
import '../../../../test_helpers.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockInternetConnectionChecker mockConnectionChecker;

  setUp(() {
    mockLocalDataSource = MockAuthLocalDataSource();
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockConnectionChecker = MockInternetConnectionChecker();

    repository = AuthRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectionChecker: mockConnectionChecker,
    );
  });

  group('getCurrentUser', () {
    final tUser = User(id: '1', email: 'test@test.com');
    final tUserModel = UserModel(id: '1', email: 'test@test.com');

    test('should return user from remote data source when online', () async {
      // arrange
      when(mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => tUserModel);
      when(mockLocalDataSource.cacheUser(any))
          .thenAnswer((_) async => Future.value());
      // act
      final result = await repository.getCurrentUser();
      // assert
      expect(result, isRight<AppFailure, User>());
      expect(getRight(result), tUser);
      verify(mockRemoteDataSource.getCurrentUser());
      verify(mockLocalDataSource.cacheUser(tUserModel));
    });

    test('should return user from local data source when remote call fails', () async {
      // arrange
      when(mockRemoteDataSource.getCurrentUser())
          .thenThrow(const SocketException("No connection"));
      when(mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => tUserModel);
      // act
      final result = await repository.getCurrentUser();
      // assert
      expect(result, isRight<AppFailure, User>());
      expect(getRight(result), tUser);
      verify(mockRemoteDataSource.getCurrentUser());
      verify(mockLocalDataSource.getCachedUser());
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return AppFailure when offline and no cached user', () async {
      // arrange
      when(mockRemoteDataSource.getCurrentUser())
          .thenThrow(const SocketException("No connection"));
      when(mockLocalDataSource.getCachedUser()).thenAnswer((_) async => null);
      // act
      final result = await repository.getCurrentUser();
      // assert
      expect(result, isLeft<AppFailure, User>(
        isAppFailure(type: FailureType.auth, message: 'No user logged in')
      ));
    });
  });

  group('signInWithEmailPassword', () {
    final tUser = User(id: '1', email: 'test@test.com');
    final tUserModel = UserModel(id: '1', email: 'test@test.com');
    const tEmail = 'test@test.com';
    const tPassword = 'password123';

    test('should sign in successfully and cache user', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockRemoteDataSource.signInWithEmailPassword(any, any))
          .thenAnswer((_) async => tUserModel);
      when(mockLocalDataSource.cacheUser(any))
          .thenAnswer((_) async => Future.value());
      // act
      final result = await repository.signInWithEmailPassword(tEmail, tPassword);
      // assert
      expect(result, isRight<AppFailure, User>());
      expect(getRight(result), tUser);
      verify(mockRemoteDataSource.signInWithEmailPassword(tEmail, tPassword));
      verify(mockLocalDataSource.cacheUser(tUserModel));
    });

    test('should return AppFailure when sign in fails', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockRemoteDataSource.signInWithEmailPassword(any, any))
          .thenThrow(Exception('Invalid credentials'));
      // act
      final result = await repository.signInWithEmailPassword(tEmail, tPassword);
      // assert
      expect(result, isLeft<AppFailure, User>());
      final failure = getLeft(result);
      expect(failure?.message, contains('Invalid credentials'));
    });
  });
}
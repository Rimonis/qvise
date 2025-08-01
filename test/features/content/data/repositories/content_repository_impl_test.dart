// test/features/content/data/repositories/content_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/data/models/lesson_model.dart';
import 'package:qvise/features/content/data/repositories/content_repository_impl.dart';

import '../../../../helpers/test_helper.mocks.dart';

void main() {
  late MockContentLocalDataSource mockLocalDataSource;
  late MockContentRemoteDataSource mockRemoteDataSource;
  late MockUnitOfWork mockUnitOfWork;
  late MockInternetConnectionChecker mockConnectionChecker;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseUser mockFirebaseUser;
  late ContentRepositoryImpl repository;

  const testUserId = 'test_user_id';
  final testLessonModel = LessonModel(
    id: '1',
    userId: testUserId,
    subjectName: 'Math',
    topicName: 'Algebra',
    createdAt: DateTime.now(),
    nextReviewDate: DateTime.now(),
    reviewStage: 1,
    proficiency: 0.5,
    updatedAt: DateTime.now(),
  );
  final testLessonEntity = testLessonModel.toEntity();

  setUp(() {
    mockLocalDataSource = MockContentLocalDataSource();
    mockRemoteDataSource = MockContentRemoteDataSource();
    mockUnitOfWork = MockUnitOfWork();
    mockConnectionChecker = MockInternetConnectionChecker();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseUser = MockFirebaseUser();

    when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockFirebaseUser.uid).thenReturn(testUserId);
    when(mockUnitOfWork.content).thenReturn(mockLocalDataSource);
    when(mockUnitOfWork.flashcard).thenReturn(MockFlashcardLocalDataSource());
    when(mockUnitOfWork.file).thenReturn(MockFileLocalDataSource());
    when(mockUnitOfWork.transaction(any)).thenAnswer((realInvocation) async {
      final function = realInvocation.positionalArguments.first;
      return await function();
    });

    repository = ContentRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      unitOfWork: mockUnitOfWork,
      connectionChecker: mockConnectionChecker,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  group('deleteLesson', () {
    test(
        'should delete from local and remote when online and local lesson exists',
        () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockLocalDataSource.getLesson(any))
          .thenAnswer((_) async => testLessonModel);
      when(mockRemoteDataSource.deleteLesson(any, any))
          .thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteLesson(any))
          .thenAnswer((_) async => {});
      when(mockUnitOfWork.file.getFilesByLessonId(any))
          .thenAnswer((_) async => []);

      // act
      final result = await repository.deleteLesson('1');

      // assert
      expect(result.isRight(), isTrue);
      verify(mockConnectionChecker.hasConnection);
      verify(mockLocalDataSource.getLesson('1'));
      verify(mockRemoteDataSource.deleteLesson('1', testUserId));
      verify(mockUnitOfWork.flashcard.deleteFlashcardsByLesson('1'));
      verify(mockUnitOfWork.content.deleteLesson('1'));
    });

    test('should return failure when lesson not found locally', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockLocalDataSource.getLesson(any)).thenAnswer((_) async => null);

      // act
      final result = await repository.deleteLesson('1');

      // assert
      expect(result.isLeft(), isTrue);
      expect(
          result.fold((l) => l, (r) => null), isA<AppFailure>());
      verify(mockLocalDataSource.getLesson('1'));
      verifyNever(mockRemoteDataSource.deleteLesson(any, any));
      verifyNever(mockLocalDataSource.deleteLesson(any));
    });

    test('should return failure when offline', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => false);

      // act
      final result = await repository.deleteLesson('1');

      // assert
      expect(result.isLeft(), isTrue);
      expect(
          result.fold((l) => l, (r) => null), isA<AppFailure>());
      verify(mockConnectionChecker.hasConnection);
      verifyNever(mockLocalDataSource.getLesson(any));
      verifyNever(mockRemoteDataSource.deleteLesson(any, any));
    });

    test(
        'should not fail if remote delete fails, but still delete locally (non-critical)',
        () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockLocalDataSource.getLesson(any))
          .thenAnswer((_) async => testLessonModel);
      when(mockRemoteDataSource.deleteLesson(any, any))
          .thenThrow(Exception('Remote delete failed'));
      when(mockLocalDataSource.deleteLesson(any))
          .thenAnswer((_) async => {});
      when(mockUnitOfWork.file.getFilesByLessonId(any))
          .thenAnswer((_) async => []);

      // act
      final result = await repository.deleteLesson('1');

      // assert
      expect(result.isRight(), isTrue); // Should still succeed
      verify(mockRemoteDataSource.deleteLesson('1', testUserId));
      verify(mockLocalDataSource.deleteLesson('1'));
    });

    test(
        'should return failure when user is not authenticated',
        () async {
      // arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);

       // Re-initialize repository with mocked unauthenticated user
      repository = ContentRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        unitOfWork: mockUnitOfWork,
        connectionChecker: mockConnectionChecker,
        firebaseAuth: mockFirebaseAuth,
      );

      // act
      final result = await repository.deleteLesson('1');

      // assert
      expect(result.isLeft(), isTrue);
      expect(
          result.fold((l) => l, (r) => null), isA<AppFailure>());
      verifyNever(mockLocalDataSource.getLesson(any));
    });
  });
}
// test/features/flashcards/shared/data/repositories/flashcard_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:qvise/features/flashcards/shared/data/models/flashcard_model.dart';
import 'package:qvise/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/core/error/app_failure.dart';

import '../../../../../mocks.mocks.dart';

void main() {
  late FlashcardRepositoryImpl repository;
  late MockFlashcardLocalDataSource mockLocalDataSource;
  late MockFlashcardRemoteDataSource mockRemoteDataSource;
  late MockIUnitOfWork mockUnitOfWork;
  late MockInternetConnectionChecker mockConnectionChecker;
  late MockFirebaseAuth mockFirebaseAuth;

  setUp(() {
    mockLocalDataSource = MockFlashcardLocalDataSource();
    mockRemoteDataSource = MockFlashcardRemoteDataSource();
    mockUnitOfWork = MockIUnitOfWork();
    mockConnectionChecker = MockInternetConnectionChecker();
    mockFirebaseAuth = MockFirebaseAuth();

    repository = FlashcardRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      unitOfWork: mockUnitOfWork,
      connectionChecker: mockConnectionChecker,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  group('getFlashcardsByLesson', () {
    final tFlashcard = Flashcard(
      id: '1',
      lessonId: '1',
      userId: 'test_user_id',
      frontContent: 'front',
      backContent: 'back',
      tag: FlashcardTag.definition,
      createdAt: DateTime.now(),
    );
    final tFlashcardModel = FlashcardModel.fromEntity(tFlashcard);

    test('should return list of flashcards from local data source', () async {
      // arrange
      when(mockLocalDataSource.getFlashcardsByLesson(any))
          .thenAnswer((_) async => [tFlashcardModel]);
      // act
      final result = await repository.getFlashcardsByLesson('1');
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (flashcards) => expect(flashcards, [tFlashcard]),
      );
      verify(mockLocalDataSource.getFlashcardsByLesson('1'));
    });

    test('should return empty list when no flashcards found', () async {
      // arrange
      when(mockLocalDataSource.getFlashcardsByLesson(any))
          .thenAnswer((_) async => []);
      // act
      final result = await repository.getFlashcardsByLesson('1');
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (flashcards) => expect(flashcards, isEmpty),
      );
    });

    test('should return AppFailure when exception occurs', () async {
      // arrange
      when(mockLocalDataSource.getFlashcardsByLesson(any))
          .thenThrow(Exception('Test error'));
      // act
      final result = await repository.getFlashcardsByLesson('1');
      // assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure.type, FailureType.local);
          expect(failure.message, contains('Failed to get flashcards'));
        },
        (flashcards) => fail('Should not return flashcards'),
      );
    });
  });

  group('createFlashcard', () {
    final tFlashcard = Flashcard(
      id: '1',
      lessonId: '1',
      userId: 'test_user_id',
      frontContent: 'front',
      backContent: 'back',
      tag: FlashcardTag.definition,
      createdAt: DateTime.now(),
    );
    final tFlashcardModel = FlashcardModel.fromEntity(tFlashcard);

    test('should create flashcard successfully when online', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => true);
      when(mockRemoteDataSource.createFlashcard(any))
          .thenAnswer((_) async => tFlashcardModel);
      when(mockLocalDataSource.createFlashcard(any))
          .thenAnswer((_) async => tFlashcardModel);
      when(mockLocalDataSource.countFlashcardsByLesson(any))
          .thenAnswer((_) async => 1);
      when(mockUnitOfWork.transaction(any)).thenAnswer((invocation) async {
        final action = invocation.positionalArguments[0];
        return await action();
      });
      
      // act
      final result = await repository.createFlashcard(tFlashcard);
      
      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (flashcard) => expect(flashcard, tFlashcard),
      );
    });

    test('should create flashcard locally when offline', () async {
      // arrange
      when(mockConnectionChecker.hasConnection).thenAnswer((_) async => false);
      when(mockLocalDataSource.createFlashcard(any))
          .thenAnswer((_) async => tFlashcardModel);
      when(mockLocalDataSource.countFlashcardsByLesson(any))
          .thenAnswer((_) async => 1);
      when(mockUnitOfWork.transaction(any)).thenAnswer((invocation) async {
        final action = invocation.positionalArguments[0];
        return await action();
      });
      
      // act
      final result = await repository.createFlashcard(tFlashcard);
      
      // assert
      expect(result.isRight(), isTrue);
    });
  });
}
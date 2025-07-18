// test/features/flashcards/creation/domain/usecases/create_flashcard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/flashcards/creation/domain/usecases/create_flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';
import 'package:qvise/features/flashcards/creation/domain/entities/flashcard_difficulty.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../../../../../mocks.mocks.dart';

void main() {
  late CreateFlashcard usecase;
  late MockFlashcardRepository mockFlashcardRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockFlashcardRepository = MockFlashcardRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    usecase = CreateFlashcard(mockFlashcardRepository, mockFirebaseAuth);
  });

  final tFlashcard = Flashcard(
    id: '1',
    lessonId: '1',
    userId: 'test_user_id',
    frontContent: 'front',
    backContent: 'back',
    tag: FlashcardTag.definition,
    createdAt: DateTime.now(),
  );

  test('should create a flashcard from the repository', () async {
    // arrange
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockFlashcardRepository.createFlashcard(any))
        .thenAnswer((_) async => Right(tFlashcard));
    // act
    final result = await usecase(
      lessonId: '1',
      frontContent: 'front',
      backContent: 'back',
      tagId: 'definition',
      difficulty: FlashcardDifficulty.easy,
    );
    // assert
    expect(result.isRight(), isTrue);
    verify(mockFlashcardRepository.createFlashcard(any));
    verifyNoMoreInteractions(mockFlashcardRepository);
  });
}

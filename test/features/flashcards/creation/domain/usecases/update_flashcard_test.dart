// test/features/flashcards/creation/domain/usecases/update_flashcard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:qvise/features/flashcards/creation/domain/usecases/update_flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard_tag.dart';

import '../../../../../mocks.mocks.dart';

void main() {
  late UpdateFlashcard usecase;
  late MockFlashcardRepository mockFlashcardRepository;

  setUp(() {
    mockFlashcardRepository = MockFlashcardRepository();
    usecase = UpdateFlashcard(mockFlashcardRepository);
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

  test('should update a flashcard from the repository', () async {
    // arrange
    when(mockFlashcardRepository.updateFlashcard(any))
        .thenAnswer((_) async => Right(tFlashcard));
    // act
    final result = await usecase(tFlashcard);
    // assert
    expect(result, Right(tFlashcard));
    verify(mockFlashcardRepository.updateFlashcard(tFlashcard));
    verifyNoMoreInteractions(mockFlashcardRepository);
  });
}

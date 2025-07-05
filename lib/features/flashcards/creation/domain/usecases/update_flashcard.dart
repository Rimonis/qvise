// lib/features/flashcards/creation/domain/usecases/update_flashcard.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/failures.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';

class UpdateFlashcard {
  final FlashcardRepository repository;

  UpdateFlashcard(this.repository);

  Future<Either<Failure, Flashcard>> call(Flashcard flashcard) async {
    // Validation
    if (flashcard.frontContent.trim().isEmpty) {
      return const Left(CacheFailure('Front content cannot be empty'));
    }
    
    if (flashcard.backContent.trim().isEmpty) {
      return const Left(CacheFailure('Back content cannot be empty'));
    }

    return await repository.updateFlashcard(flashcard);
  }
}
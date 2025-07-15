// lib/features/flashcards/creation/domain/usecases/update_flashcard.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';

class UpdateFlashcard {
  final FlashcardRepository repository;

  UpdateFlashcard(this.repository);

  Future<Either<AppFailure, Flashcard>> call(Flashcard flashcard) async {
    // Validation
    if (flashcard.frontContent.trim().isEmpty) {
      return Left(AppFailure(type: FailureType.validation, message: 'Front content cannot be empty'));
    }
    
    if (flashcard.backContent.trim().isEmpty) {
      return Left(AppFailure(type: FailureType.validation, message: 'Back content cannot be empty'));
    }

    return await repository.updateFlashcard(flashcard);
  }
}
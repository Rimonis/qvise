// lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  Future<Either<AppError, Flashcard>> createFlashcard(Flashcard flashcard);
  Future<Either<AppError, Flashcard>> updateFlashcard(Flashcard flashcard);
  Future<Either<AppError, void>> deleteFlashcard(String id);
  Future<Either<AppError, List<Flashcard>>> getFlashcardsByLesson(String lessonId);
  Future<Either<AppError, void>> syncFlashcardsToRemote(List<Flashcard> flashcards);
}
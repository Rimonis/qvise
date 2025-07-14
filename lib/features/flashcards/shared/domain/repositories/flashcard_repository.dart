// lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  /// Basic CRUD operations
  Future<Either<AppError, Flashcard>> createFlashcard(Flashcard flashcard);
  Future<Either<AppError, Flashcard>> updateFlashcard(Flashcard flashcard);
  Future<Either<AppError, void>> deleteFlashcard(String id);
  Future<Either<AppError, List<Flashcard>>> getFlashcardsByLesson(String lessonId);
  Future<Either<AppError, Flashcard?>> getFlashcard(String id);
  
  /// Sync operations
  Future<Either<AppError, void>> syncFlashcardsToRemote(List<Flashcard> flashcards);
  Future<Either<AppError, List<Flashcard>>> getPendingSyncFlashcards();
  Future<Either<AppError, void>> markFlashcardsAsSynced(List<String> flashcardIds);
  
  /// Batch operations
  Future<Either<AppError, List<Flashcard>>> createFlashcardsBatch(List<Flashcard> flashcards);
  Future<Either<AppError, void>> deleteFlashcardsByLesson(String lessonId);
  
  /// Study operations
  Future<Either<AppError, List<Flashcard>>> getDueFlashcards(String userId);
  Future<Either<AppError, List<Flashcard>>> getRecentFlashcards(String userId, {int limit = 20});
  Future<Either<AppError, void>> updateFlashcardProgress(String flashcardId, {
    required bool wasCorrect,
    required DateTime reviewedAt,
  });
  
  /// Statistics
  Future<Either<AppError, int>> getFlashcardCountByLesson(String lessonId);
  Future<Either<AppError, Map<String, int>>> getFlashcardStatsByUser(String userId);
}

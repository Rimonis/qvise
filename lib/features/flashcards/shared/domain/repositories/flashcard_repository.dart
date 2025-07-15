// lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  Future<Either<AppFailure, Flashcard>> createFlashcard(Flashcard flashcard);
  Future<Either<AppFailure, Flashcard>> updateFlashcard(Flashcard flashcard);
  Future<Either<AppFailure, void>> deleteFlashcard(String id);
  Future<Either<AppFailure, Flashcard?>> getFlashcard(String id);
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsByLesson(String lessonId);
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsByLessonAndTag(
    String lessonId,
    String tagId,
  );
  Future<Either<AppFailure, List<Flashcard>>> getFavoriteFlashcards(String userId);
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsNeedingAttention(
      String userId);
  Future<Either<AppFailure, int>> countFlashcardsByLesson(String lessonId);
  Future<Either<AppFailure, List<Flashcard>>> searchFlashcards(
    String userId,
    String query,
  );
  Future<Either<AppFailure, void>> syncFlashcardsToRemote(
      List<String> flashcardIds);
  Future<Either<AppFailure, void>> syncFlashcardsFromRemote(String lessonId);
  Future<Either<AppFailure, List<Flashcard>>> getPendingSyncFlashcards();
  Future<Either<AppFailure, void>> toggleFavorite(String flashcardId);
}

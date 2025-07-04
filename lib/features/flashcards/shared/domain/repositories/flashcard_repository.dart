// lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart

import 'package:dartz/dartz.dart';
import '/../../../core/error/failures.dart';
import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  Future<Either<Failure, Flashcard>> createFlashcard(Flashcard flashcard);
  Future<Either<Failure, Flashcard>> updateFlashcard(Flashcard flashcard);
  Future<Either<Failure, void>> deleteFlashcard(String id);
  Future<Either<Failure, Flashcard?>> getFlashcard(String id);
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLesson(String lessonId);
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLessonAndTag(
    String lessonId,
    String tagId,
  );
  Future<Either<Failure, List<Flashcard>>> getFavoriteFlashcards(String userId);
  Future<Either<Failure, List<Flashcard>>> getFlashcardsNeedingAttention(
      String userId);
  Future<Either<Failure, int>> countFlashcardsByLesson(String lessonId);
  Future<Either<Failure, List<Flashcard>>> searchFlashcards(
    String userId,
    String query,
  );
  Future<Either<Failure, void>> syncFlashcardsToRemote(
      List<String> flashcardIds);
  Future<Either<Failure, void>> syncFlashcardsFromRemote(String lessonId);
  Future<Either<Failure, List<Flashcard>>> getPendingSyncFlashcards();
  Future<Either<Failure, void>> toggleFavorite(String flashcardId);
}

// lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart

import 'package:dartz/dartz.dart';
import '/../../../core/error/failures.dart';
import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  // Create flashcard (local-first)
  Future<Either<Failure, Flashcard>> createFlashcard(Flashcard flashcard);
  
  // Update flashcard
  Future<Either<Failure, Flashcard>> updateFlashcard(Flashcard flashcard);
  
  // Delete flashcard
  Future<Either<Failure, void>> deleteFlashcard(String id);
  
  // Get flashcard by ID
  Future<Either<Failure, Flashcard?>> getFlashcard(String id);
  
  // Get all flashcards for a lesson
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLesson(String lessonId);
  
  // Get flashcards by tag for a lesson
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLessonAndTag(
    String lessonId, 
    String tagId,
  );
  
  // Get user's favorite flashcards across all lessons
  Future<Either<Failure, List<Flashcard>>> getFavoriteFlashcards(String userId);
  
  // Get flashcards that need attention (low success rate)
  Future<Either<Failure, List<Flashcard>>> getFlashcardsNeedingAttention(String userId);
  
  // Count flashcards in a lesson
  Future<Either<Failure, int>> countFlashcardsByLesson(String lessonId);
  
  // Search flashcards by content
  Future<Either<Failure, List<Flashcard>>> searchFlashcards(
    String userId,
    String query,
  );
  
  // Sync operations (for when lesson is locked)
  Future<Either<Failure, void>> syncFlashcardsToRemote(List<String> flashcardIds);
  Future<Either<Failure, void>> syncFlashcardsFromRemote(String lessonId);
  
  // Get pending sync flashcards
  Future<Either<Failure, List<Flashcard>>> getPendingSyncFlashcards();
}
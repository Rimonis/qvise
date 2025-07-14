// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart

import '../models/flashcard_model.dart';
import '../../domain/entities/sync_status.dart';

abstract class FlashcardLocalDataSource {
  /// Basic CRUD operations
  Future<void> upsertFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
  Future<FlashcardModel?> getFlashcard(String id);
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId);
  
  /// Bulk operations
  Future<void> insertFlashcardsBatch(List<FlashcardModel> flashcards);
  Future<void> deleteFlashcardsByLesson(String lessonId);
  Future<void> deleteFlashcardsByTopic({
    required String userId,
    required String subjectName,
    required String topicName,
  });
  
  /// Sync operations
  Future<List<FlashcardModel>> getPendingSyncFlashcards(String userId);
  Future<void> updateFlashcardSyncStatus(String flashcardId, SyncStatus status);
  Future<void> markFlashcardsAsSynced(List<String> flashcardIds);
  
  /// Study operations
  Future<List<FlashcardModel>> getDueFlashcards(String userId);
  Future<List<FlashcardModel>> getRecentFlashcards(String userId, {int limit = 20});
  Future<List<FlashcardModel>> getFlashcardsByDifficulty(String userId, double minDifficulty, double maxDifficulty);
  
  /// Statistics
  Future<int> countFlashcardsByLesson(String lessonId);
  Future<Map<String, int>> getFlashcardStatsByUser(String userId);
  Future<double> getAverageScoreByLesson(String lessonId);
}

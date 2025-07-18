// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart

import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardLocalDataSource {
  Future<void> initDatabase();
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard);
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
  Future<void> deleteFlashcardsByLesson(String lessonId);
  Future<FlashcardModel?> getFlashcard(String id);
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId);
  Future<List<FlashcardModel>> getFlashcardsByLessonAndTag(
      String lessonId, String tagId);
  Future<List<FlashcardModel>> getFavoriteFlashcards(String userId);
  Future<List<FlashcardModel>> getFlashcardsNeedingAttention(String userId);
  Future<int> countFlashcardsByLesson(String lessonId);
  Future<List<FlashcardModel>> searchFlashcards(String userId, String query);
  Future<List<FlashcardModel>> getPendingSyncFlashcards();
  Future<void> toggleFavorite(String flashcardId, bool isFavorite);

  // New methods for sync service
  Future<List<FlashcardModel>> getModifiedSince(DateTime since);
  Future<List<FlashcardModel>> getUnpushedChanges();
  Future<void> markAsSynced(String id);
}

class FlashcardLocalDataSourceImpl extends TransactionalDataSource
    implements FlashcardLocalDataSource {
  @override
  Future<void> initDatabase() async {
    await database;
  }

  @override
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard) async {
    final db = await database;
    await db.insert('flashcards', flashcard.toMap());
    return flashcard;
  }

  @override
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard) async {
    final db = await database;
    final flashcardMap = flashcard.toMap();
    flashcardMap['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'flashcards',
      flashcardMap,
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
    return flashcard.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFlashcardsByLesson(String lessonId) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'is_deleted': 1},
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return FlashcardModel.fromMap(result.first);
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'lesson_id = ? AND is_active = 1 AND is_deleted = 0',
      whereArgs: [lessonId],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLessonAndTag(
      String lessonId, String tagId) async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'lesson_id = ? AND tag_id = ? AND is_active = 1 AND is_deleted = 0',
      whereArgs: [lessonId, tagId],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFavoriteFlashcards(String userId) async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'user_id = ? AND is_favorite = 1 AND is_active = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsNeedingAttention(
      String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM flashcards 
      WHERE user_id = ? 
        AND review_count >= 3 
        AND CAST(correct_count AS REAL) / review_count < 0.6
        AND is_active = 1
        AND is_deleted = 0
      ORDER BY CAST(correct_count AS REAL) / review_count ASC
    ''', [userId]);
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<int> countFlashcardsByLesson(String lessonId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM flashcards 
      WHERE lesson_id = ? AND is_active = 1 AND is_deleted = 0
    ''', [lessonId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<FlashcardModel>> searchFlashcards(
      String userId, String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    final result = await db.query(
      'flashcards',
      where: '''
        user_id = ? AND is_active = 1 AND is_deleted = 0 AND (
          front_content LIKE ? OR 
          back_content LIKE ? OR
          notes LIKE ?
        )
      ''',
      whereArgs: [userId, searchTerm, searchTerm, searchTerm],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getPendingSyncFlashcards() async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'sync_status = ? AND is_deleted = 0',
      whereArgs: ['pending'],
      orderBy: 'updated_at ASC',
    );
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<void> toggleFavorite(String flashcardId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [flashcardId],
    );
  }

  @override
  Future<List<FlashcardModel>> getModifiedSince(DateTime since) async {
    final db = await database;
    final results = await db.query(
      'flashcards',
      where: 'updated_at > ? AND is_deleted = 0',
      whereArgs: [since.toIso8601String()],
    );
    return results.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getUnpushedChanges() async {
    final db = await database;
    final results = await db.query(
      'flashcards',
      where: 'sync_status = ? AND is_deleted = 0',
      whereArgs: ['pending'],
    );
    return results.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
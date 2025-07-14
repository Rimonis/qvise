// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source_impl.dart

import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/security/field_encryption.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard_model.dart';
import '../../domain/entities/sync_status.dart';
import 'flashcard_local_data_source.dart';

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  final DatabaseHelper databaseHelper;
  final FieldEncryption fieldEncryption;

  FlashcardLocalDataSourceImpl(this.databaseHelper, this.fieldEncryption);

  Database get database => databaseHelper.database;

  @override
  Future<void> upsertFlashcard(FlashcardModel flashcard) async {
    final db = await database;
    await db.insert(
      'flashcards',
      flashcard.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    final db = await database;
    await db.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return FlashcardModel.fromDatabase(maps.first);
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'lessonId = ? AND isActive = 1',
      whereArgs: [lessonId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> insertFlashcardsBatch(List<FlashcardModel> flashcards) async {
    final db = await database;
    final batch = db.batch();

    for (final flashcard in flashcards) {
      batch.insert(
        'flashcards',
        flashcard.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteFlashcardsByLesson(String lessonId) async {
    final db = await database;
    await db.delete(
      'flashcards',
      where: 'lessonId = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<void> deleteFlashcardsByTopic({
    required String userId,
    required String subjectName,
    required String topicName,
  }) async {
    final db = await database;
    
    // First get all lesson IDs for the topic
    final lessonMaps = await db.query(
      'lessons',
      columns: ['id'],
      where: 'userId = ? AND subjectName = ? AND topicName = ?',
      whereArgs: [userId, subjectName, topicName],
    );

    final lessonIds = lessonMaps.map((map) => map['id'] as String).toList();

    if (lessonIds.isNotEmpty) {
      final placeholders = List.filled(lessonIds.length, '?').join(', ');
      await db.delete(
        'flashcards',
        where: 'lessonId IN ($placeholders)',
        whereArgs: lessonIds,
      );
    }
  }

  @override
  Future<List<FlashcardModel>> getPendingSyncFlashcards(String userId) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'userId = ? AND syncStatus = ?',
      whereArgs: [userId, SyncStatus.pending.name],
      orderBy: 'updatedAt ASC',
    );

    return maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> updateFlashcardSyncStatus(String flashcardId, SyncStatus status) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'syncStatus': status.name},
      where: 'id = ?',
      whereArgs: [flashcardId],
    );
  }

  @override
  Future<void> markFlashcardsAsSynced(List<String> flashcardIds) async {
    if (flashcardIds.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (final id in flashcardIds) {
      batch.update(
        'flashcards',
        {'syncStatus': SyncStatus.synced.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<List<FlashcardModel>> getDueFlashcards(String userId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final maps = await db.query(
      'flashcards',
      where: 'userId = ? AND isActive = 1 AND (lastReviewedAt IS NULL OR lastReviewedAt <= ?)',
      whereArgs: [userId, now - (24 * 60 * 60 * 1000)], // Due if not reviewed in 24h
      orderBy: 'lastReviewedAt ASC',
    );

    return maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getRecentFlashcards(String userId, {int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'userId = ? AND isActive = 1',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
      limit: limit,
    );

    return maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByDifficulty(
    String userId,
    double minDifficulty,
    double maxDifficulty,
  ) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'userId = ? AND isActive = 1 AND difficulty >= ? AND difficulty <= ?',
      whereArgs: [userId, minDifficulty, maxDifficulty],
      orderBy: 'difficulty ASC',
    );

    return maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
  }

  @override
  Future<int> countFlashcardsByLesson(String lessonId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE lessonId = ? AND isActive = 1',
      [lessonId],
    );

    return result.first['count'] as int;
  }

  @override
  Future<Map<String, int>> getFlashcardStatsByUser(String userId) async {
    final db = await database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE userId = ? AND isActive = 1',
      [userId],
    );
    
    final dueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE userId = ? AND isActive = 1 AND (lastReviewedAt IS NULL OR lastReviewedAt <= ?)',
      [userId, DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000)],
    );
    
    final masteredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE userId = ? AND isActive = 1 AND masteryLevel >= 0.8',
      [userId],
    );

    return {
      'total': totalResult.first['count'] as int,
      'due': dueResult.first['count'] as int,
      'mastered': masteredResult.first['count'] as int,
    };
  }

  @override
  Future<double> getAverageScoreByLesson(String lessonId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(CASE WHEN reviewCount > 0 THEN CAST(correctCount AS REAL) / reviewCount ELSE 0 END) as avg_score FROM flashcards WHERE lessonId = ? AND isActive = 1',
      [lessonId],
    );

    return (result.first['avg_score'] as double?) ?? 0.0;
  }
}

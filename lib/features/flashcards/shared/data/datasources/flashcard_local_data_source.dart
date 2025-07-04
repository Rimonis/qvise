// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart

import 'package:sqflite/sqflite.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardLocalDataSource {
  Future<void> initDatabase();
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard);
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
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
}

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  Database? _database;

  @override
  Future<void> initDatabase() async {
    if (_database != null) return;

    _database = await openDatabase(
      'qvise_flashcards.db',
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        
        front_content TEXT NOT NULL,
        back_content TEXT NOT NULL,
        
        tag_id TEXT NOT NULL,
        tag_name TEXT NOT NULL,
        tag_emoji TEXT NOT NULL,
        tag_color TEXT NOT NULL,
        tag_category TEXT NOT NULL,
        
        difficulty REAL DEFAULT 0.5 CHECK (difficulty >= 0.0 AND difficulty <= 1.0),
        mastery_level REAL DEFAULT 0.0 CHECK (mastery_level >= 0.0 AND mastery_level <= 1.0),
        review_count INTEGER DEFAULT 0,
        correct_count INTEGER DEFAULT 0,
        
        is_favorite INTEGER DEFAULT 0 CHECK (is_favorite IN (0, 1)),
        is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
        notes TEXT,
        hints TEXT,
        
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_reviewed_at TEXT,
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('synced', 'pending', 'conflict'))
      )
    ''');

    await db.execute('CREATE INDEX idx_flashcards_lesson ON flashcards(lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_user_lesson ON flashcards(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_tag ON flashcards(tag_id)');
    await db.execute('CREATE INDEX idx_flashcards_sync ON flashcards(sync_status)');
  }

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initDatabase() first.');
    }
    return _database!;
  }

  @override
  Future<FlashcardModel> createFlashcard(FlashcardModel flashcard) async {
    await initDatabase();

    final flashcardMap = flashcard.toMap();
    await database.insert('flashcards', flashcardMap);

    return flashcard;
  }

  @override
  Future<FlashcardModel> updateFlashcard(FlashcardModel flashcard) async {
    await initDatabase();

    final flashcardMap = flashcard.toMap();
    flashcardMap['updated_at'] = DateTime.now().toIso8601String();

    await database.update(
      'flashcards',
      flashcardMap,
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );

    return flashcard.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    await initDatabase();

    await database.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    await initDatabase();

    final result = await database.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return FlashcardModel.fromMap(result.first);
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    await initDatabase();

    final result = await database.query(
      'flashcards',
      where: 'lesson_id = ? AND is_active = 1',
      whereArgs: [lessonId],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLessonAndTag(
    String lessonId,
    String tagId,
  ) async {
    await initDatabase();

    final result = await database.query(
      'flashcards',
      where: 'lesson_id = ? AND tag_id = ? AND is_active = 1',
      whereArgs: [lessonId, tagId],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFavoriteFlashcards(String userId) async {
    await initDatabase();

    final result = await database.query(
      'flashcards',
      where: 'user_id = ? AND is_favorite = 1 AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsNeedingAttention(
      String userId) async {
    await initDatabase();

    final result = await database.rawQuery('''
      SELECT * FROM flashcards 
      WHERE user_id = ? 
        AND review_count >= 3 
        AND CAST(correct_count AS REAL) / review_count < 0.6
        AND is_active = 1
      ORDER BY CAST(correct_count AS REAL) / review_count ASC
    ''', [userId]);

    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<int> countFlashcardsByLesson(String lessonId) async {
    await initDatabase();

    final result = await database.rawQuery('''
      SELECT COUNT(*) as count FROM flashcards 
      WHERE lesson_id = ? AND is_active = 1
    ''', [lessonId]);

    return result.first['count'] as int;
  }

  @override
  Future<List<FlashcardModel>> searchFlashcards(
      String userId, String query) async {
    await initDatabase();

    final searchTerm = '%$query%';
    final result = await database.query(
      'flashcards',
      where: '''
        user_id = ? AND is_active = 1 AND (
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
    await initDatabase();

    final result = await database.query(
      'flashcards',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'updated_at ASC',
    );

    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<void> toggleFavorite(String flashcardId, bool isFavorite) async {
    await initDatabase();
    await database.update(
      'flashcards',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [flashcardId],
    );
  }
}

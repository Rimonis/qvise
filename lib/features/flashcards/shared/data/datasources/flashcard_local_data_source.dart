// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
}

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'qvise_flashcards.db');

    return await openDatabase(
      path,
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
    await db.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFlashcardsByLesson(String lessonId) async {
    final db = await database;
    await db.delete(
      'flashcards',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<FlashcardModel?> getFlashcard(String id) async {
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'id = ?',
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
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'lesson_id = ? AND tag_id = ? AND is_active = 1',
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
      where: 'user_id = ? AND is_favorite = 1 AND is_active = 1',
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
      ORDER BY CAST(correct_count AS REAL) / review_count ASC
    ''', [userId]);
    return result.map((map) => FlashcardModel.fromMap(map)).toList();
  }

  @override
  Future<int> countFlashcardsByLesson(String lessonId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM flashcards 
      WHERE lesson_id = ? AND is_active = 1
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
    final db = await database;
    final result = await db.query(
      'flashcards',
      where: 'sync_status = ?',
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
}
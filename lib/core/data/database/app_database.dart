// lib/core/data/database/app_database.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'qvise.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createAllTables,
    );
  }

  static Future<void> _createAllTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects(
        name TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL,
        lessonCount INTEGER NOT NULL,
        topicCount INTEGER NOT NULL,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (userId, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE topics(
        name TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL,
        lessonCount INTEGER NOT NULL,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (userId, subjectName, name)
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        topicName TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        lockedAt INTEGER,
        nextReviewDate INTEGER NOT NULL,
        lastReviewedAt INTEGER,
        reviewStage INTEGER NOT NULL,
        proficiency REAL NOT NULL,
        isLocked INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0,
        flashcardCount INTEGER NOT NULL DEFAULT 0,
        fileCount INTEGER NOT NULL DEFAULT 0,
        noteCount INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

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
        sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('synced', 'pending', 'conflict')),
        version INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_lessons_user ON lessons(userId)');
    await db.execute('CREATE INDEX idx_lessons_subject_topic ON lessons(userId, subjectName, topicName)');
    await db.execute('CREATE INDEX idx_lessons_sync ON lessons(isSynced)');
    await db.execute('CREATE INDEX idx_lessons_review ON lessons(nextReviewDate)');
    await db.execute('CREATE INDEX idx_lessons_locked ON lessons(isLocked)');
    await db.execute('CREATE INDEX idx_flashcards_lesson ON flashcards(lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_user_lesson ON flashcards(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_tag ON flashcards(tag_id)');
    await db.execute('CREATE INDEX idx_flashcards_sync ON flashcards(sync_status)');
  }
}

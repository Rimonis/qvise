// lib/core/database/database_helper.dart

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'qvise.db';
  static const int _databaseVersion = 3; // Incremented for sync_queue table

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }

    // Handle migrations based on version
    if (oldVersion < 2) {
      // Add sync_queue table in version 2
      await _createSyncQueueTable(db);
    }

    if (oldVersion < 3) {
      // Add any new fields or tables for version 3
      await _addSyncStatusToFlashcards(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        name TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL DEFAULT 0.0,
        lessonCount INTEGER NOT NULL DEFAULT 0,
        topicCount INTEGER NOT NULL DEFAULT 0,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        PRIMARY KEY (name, userId)
      )
    ''');

    // Topics table
    await db.execute('''
      CREATE TABLE topics (
        name TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL DEFAULT 0.0,
        lessonCount INTEGER NOT NULL DEFAULT 0,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        PRIMARY KEY (name, subjectName, userId),
        FOREIGN KEY (subjectName, userId) REFERENCES subjects (name, userId) ON DELETE CASCADE
      )
    ''');

    // Lessons table
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        topicName TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        lockedAt INTEGER,
        nextReviewDate INTEGER NOT NULL,
        lastReviewedAt INTEGER,
        reviewStage INTEGER NOT NULL DEFAULT 0,
        proficiency REAL NOT NULL DEFAULT 0.0,
        isLocked INTEGER NOT NULL DEFAULT 0,
        flashcardCount INTEGER NOT NULL DEFAULT 0,
        fileCount INTEGER NOT NULL DEFAULT 0,
        noteCount INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subjectName, userId) REFERENCES subjects (name, userId) ON DELETE CASCADE,
        FOREIGN KEY (topicName, subjectName, userId) REFERENCES topics (name, subjectName, userId) ON DELETE CASCADE
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        userId TEXT NOT NULL,
        frontContent TEXT NOT NULL,
        backContent TEXT NOT NULL,
        tag TEXT NOT NULL,
        hints TEXT,
        difficulty REAL NOT NULL DEFAULT 0.5,
        masteryLevel REAL NOT NULL DEFAULT 0.0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        lastReviewedAt INTEGER,
        reviewCount INTEGER NOT NULL DEFAULT 0,
        correctCount INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (lessonId) REFERENCES lessons (id) ON DELETE CASCADE
      )
    ''');

    // Sync queue table
    await _createSyncQueueTable(db);

    // Files table (for lesson attachments)
    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        userId TEXT NOT NULL,
        filename TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        mimeType TEXT NOT NULL,
        localPath TEXT,
        remotePath TEXT,
        uploadedAt INTEGER,
        createdAt INTEGER NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (lessonId) REFERENCES lessons (id) ON DELETE CASCADE
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        userId TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (lessonId) REFERENCES lessons (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entityId TEXT NOT NULL,
        entityType TEXT NOT NULL,
        operationType TEXT NOT NULL,
        payload TEXT,
        createdAt INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _addSyncStatusToFlashcards(Database db) async {
    try {
      // Check if column already exists
      final tableInfo = await db.rawQuery('PRAGMA table_info(flashcards)');
      final hasColumn = tableInfo.any((row) => row['name'] == 'syncStatus');
      
      if (!hasColumn) {
        await db.execute('ALTER TABLE flashcards ADD COLUMN syncStatus TEXT NOT NULL DEFAULT \'pending\'');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding syncStatus column: $e');
      }
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Subjects indexes
    await db.execute('CREATE INDEX idx_subjects_userId ON subjects (userId)');

    // Topics indexes
    await db.execute('CREATE INDEX idx_topics_userId ON topics (userId)');
    await db.execute('CREATE INDEX idx_topics_subject ON topics (subjectName, userId)');

    // Lessons indexes
    await db.execute('CREATE INDEX idx_lessons_userId ON lessons (userId)');
    await db.execute('CREATE INDEX idx_lessons_topic ON lessons (topicName, subjectName, userId)');
    await db.execute('CREATE INDEX idx_lessons_nextReview ON lessons (nextReviewDate)');
    await db.execute('CREATE INDEX idx_lessons_isLocked ON lessons (isLocked)');
    await db.execute('CREATE INDEX idx_lessons_sync ON lessons (isSynced)');

    // Flashcards indexes
    await db.execute('CREATE INDEX idx_flashcards_lessonId ON flashcards (lessonId)');
    await db.execute('CREATE INDEX idx_flashcards_userId ON flashcards (userId)');
    await db.execute('CREATE INDEX idx_flashcards_lastReviewed ON flashcards (lastReviewedAt)');
    await db.execute('CREATE INDEX idx_flashcards_difficulty ON flashcards (difficulty)');
    await db.execute('CREATE INDEX idx_flashcards_mastery ON flashcards (masteryLevel)');
    await db.execute('CREATE INDEX idx_flashcards_sync ON flashcards (syncStatus)');
    await db.execute('CREATE INDEX idx_flashcards_active ON flashcards (isActive)');

    // Sync queue indexes
    await db.execute('CREATE INDEX idx_sync_queue_createdAt ON sync_queue (createdAt)');
    await db.execute('CREATE INDEX idx_sync_queue_entityType ON sync_queue (entityType)');
    await db.execute('CREATE INDEX idx_sync_queue_attempts ON sync_queue (attempts)');

    // Files indexes
    await db.execute('CREATE INDEX idx_files_lessonId ON files (lessonId)');
    await db.execute('CREATE INDEX idx_files_userId ON files (userId)');
    await db.execute('CREATE INDEX idx_files_sync ON files (syncStatus)');

    // Notes indexes
    await db.execute('CREATE INDEX idx_notes_lessonId ON notes (lessonId)');
    await db.execute('CREATE INDEX idx_notes_userId ON notes (userId)');
    await db.execute('CREATE INDEX idx_notes_sync ON notes (syncStatus)');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final subjects = await db.rawQuery('SELECT COUNT(*) as count FROM subjects');
    final topics = await db.rawQuery('SELECT COUNT(*) as count FROM topics');
    final lessons = await db.rawQuery('SELECT COUNT(*) as count FROM lessons');
    final flashcards = await db.rawQuery('SELECT COUNT(*) as count FROM flashcards');
    final syncQueue = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    
    return {
      'subjects': subjects.first['count'] as int,
      'topics': topics.first['count'] as int,
      'lessons': lessons.first['count'] as int,
      'flashcards': flashcards.first['count'] as int,
      'syncQueue': syncQueue.first['count'] as int,
    };
  }
}

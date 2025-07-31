// lib/core/data/database/app_database.dart

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:qvise/core/data/migrations/add_sync_fields_migration.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  /// A setter for overriding the database instance in tests.
  @visibleForTesting
  static void setDatabase(Database? db) {
    _database = db;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'qvise.db');

    return await openDatabase(
      path,
      version: 4, // Increment version for foreign key constraints
      onCreate: _createAllTables,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createConflictsTable(db);
      await AddSyncFieldsMigration.migrate(db);
    }
    if (oldVersion < 3) {
      await _createFilesTable(db);
    }
    if (oldVersion < 4) {
      // Enable foreign keys and recreate tables with constraints
      await db.execute('PRAGMA foreign_keys = OFF');
      await _addForeignKeyConstraints(db);
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  static Future<void> _addForeignKeyConstraints(Database db) async {
    // Since SQLite doesn't support adding foreign keys to existing tables,
    // we need to recreate the tables with constraints
    
    // Backup existing data
    await db.execute('CREATE TEMP TABLE flashcards_backup AS SELECT * FROM flashcards');
    await db.execute('CREATE TEMP TABLE files_backup AS SELECT * FROM files');
    await db.execute('CREATE TEMP TABLE topics_backup AS SELECT * FROM topics');
    await db.execute('CREATE TEMP TABLE lessons_backup AS SELECT * FROM lessons');
    
    // Drop existing tables
    await db.execute('DROP TABLE flashcards');
    await db.execute('DROP TABLE files');
    await db.execute('DROP TABLE topics');
    await db.execute('DROP TABLE lessons');
    
    // Recreate with foreign keys
    await _createTopicsTableWithFK(db);
    await _createLessonsTableWithFK(db);
    await _createFlashcardsTableWithFK(db);
    await _createFilesTableWithFK(db);
    
    // Restore data
    await db.execute('INSERT INTO topics SELECT * FROM topics_backup');
    await db.execute('INSERT INTO lessons SELECT * FROM lessons_backup');
    await db.execute('INSERT INTO flashcards SELECT * FROM flashcards_backup');
    await db.execute('INSERT INTO files SELECT * FROM files_backup');
    
    // Drop backup tables
    await db.execute('DROP TABLE flashcards_backup');
    await db.execute('DROP TABLE files_backup');
    await db.execute('DROP TABLE topics_backup');
    await db.execute('DROP TABLE lessons_backup');
  }

  static Future<void> _createConflictsTable(Database db) async {
    await db.execute('''
      CREATE TABLE conflicts (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        local_version INTEGER NOT NULL,
        remote_version INTEGER NOT NULL,
        local_updated_at TEXT NOT NULL,
        remote_updated_at TEXT NOT NULL,
        detected_at TEXT NOT NULL,
        resolved_at TEXT,
        status TEXT NOT NULL DEFAULT 'unresolved',
        resolution_type TEXT,
        resolved_by TEXT,
        metadata TEXT,
        CHECK (status IN ('unresolved', 'resolved'))
      )
    ''');
    await db.execute('CREATE INDEX idx_conflicts_status ON conflicts(status)');
    await db.execute(
        'CREATE INDEX idx_conflicts_entity ON conflicts(entity_type, entity_id)');
  }

  static Future<void> _createFilesTable(Database db) async {
    await _createFilesTableWithFK(db);
  }

  static Future<void> _createFilesTableWithFK(Database db) async {
    await db.execute('''
      CREATE TABLE files(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        remote_url TEXT,
        is_starred INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'local_only',
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for files table
    await db.execute('CREATE INDEX idx_files_lesson ON files(lesson_id)');
    await db.execute('CREATE INDEX idx_files_user_lesson ON files(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_files_starred ON files(is_starred)');
    await db.execute('CREATE INDEX idx_files_sync ON files(sync_status)');
  }

  static Future<void> _createTopicsTableWithFK(Database db) async {
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
        updated_at INTEGER,
        PRIMARY KEY (userId, subjectName, name),
        FOREIGN KEY (userId, subjectName) REFERENCES subjects(userId, name) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createLessonsTableWithFK(Database db) async {
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
        is_deleted INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER,
        FOREIGN KEY (userId, subjectName, topicName) REFERENCES topics(userId, subjectName, name) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createFlashcardsTableWithFK(Database db) async {
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
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
      )
    ''');
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
        updated_at INTEGER,
        PRIMARY KEY (userId, name)
      )
    ''');

    await _createTopicsTableWithFK(db);
    await _createLessonsTableWithFK(db);
    await _createFlashcardsTableWithFK(db);

    // Create files table
    await _createFilesTableWithFK(db);

    await _createConflictsTable(db);

    // Create indexes
    await db.execute('CREATE INDEX idx_lessons_user ON lessons(userId)');
    await db.execute(
        'CREATE INDEX idx_lessons_subject_topic ON lessons(userId, subjectName, topicName)');
    await db.execute('CREATE INDEX idx_lessons_sync ON lessons(isSynced)');
    await db.execute('CREATE INDEX idx_lessons_review ON lessons(nextReviewDate)');
    await db.execute('CREATE INDEX idx_lessons_locked ON lessons(isLocked)');
    await db.execute('CREATE INDEX idx_flashcards_lesson ON flashcards(lesson_id)');
    await db.execute(
        'CREATE INDEX idx_flashcards_user_lesson ON flashcards(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_tag ON flashcards(tag_id)');
    await db.execute('CREATE INDEX idx_flashcards_sync ON flashcards(sync_status)');
  }
}
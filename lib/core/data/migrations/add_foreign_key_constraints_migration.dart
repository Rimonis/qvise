// lib/core/data/migrations/add_foreign_key_constraints_migration.dart

import 'package:sqflite/sqflite.dart';

class AddForeignKeyConstraintsMigration {
  static Future<void> migrate(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = OFF');
    
    // Check if foreign key constraints already exist
    final hasConstraints = await _checkForExistingConstraints(db);
    if (hasConstraints) {
      await db.execute('PRAGMA foreign_keys = ON');
      return;
    }

    // Backup existing data
    await _backupTables(db);
    
    // Drop existing tables (in reverse dependency order)
    await db.execute('DROP TABLE IF EXISTS flashcards');
    await db.execute('DROP TABLE IF EXISTS files');
    await db.execute('DROP TABLE IF EXISTS lessons');
    await db.execute('DROP TABLE IF EXISTS topics');
    
    // Recreate tables with foreign key constraints
    await _createTopicsTableWithFK(db);
    await _createLessonsTableWithFK(db);
    await _createFlashcardsTableWithFK(db);
    await _createFilesTableWithFK(db);
    
    // Restore data
    await _restoreData(db);
    
    // Drop backup tables
    await _dropBackupTables(db);
    
    // Re-enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<bool> _checkForExistingConstraints(Database db) async {
    try {
      // Check if files table has foreign key constraint
      final result = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type='table' AND name='files'");
      if (result.isNotEmpty) {
        final sql = result.first['sql'] as String;
        return sql.contains('FOREIGN KEY');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _backupTables(Database db) async {
    // Check if tables exist before backing up
    final tableExists = await _tableExists(db, 'topics');
    if (!tableExists) return;

    await db.execute('CREATE TEMP TABLE topics_backup AS SELECT * FROM topics');
    await db.execute('CREATE TEMP TABLE lessons_backup AS SELECT * FROM lessons');
    await db.execute('CREATE TEMP TABLE flashcards_backup AS SELECT * FROM flashcards');
    
    // Only backup files if table exists
    final filesExists = await _tableExists(db, 'files');
    if (filesExists) {
      await db.execute('CREATE TEMP TABLE files_backup AS SELECT * FROM files');
    }
  }

  static Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
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
  }

  static Future<void> _restoreData(Database db) async {
    // Restore data in dependency order
    await db.execute('INSERT INTO topics SELECT * FROM topics_backup');
    await db.execute('INSERT INTO lessons SELECT * FROM lessons_backup');
    await db.execute('INSERT INTO flashcards SELECT * FROM flashcards_backup');
    
    // Only restore files if backup exists
    final filesBackupExists = await _tableExists(db, 'files_backup');
    if (filesBackupExists) {
      await db.execute('INSERT INTO files SELECT * FROM files_backup');
    }
    
    // Recreate indexes
    await _createIndexes(db);
  }

  static Future<void> _createIndexes(Database db) async {
    // Lesson indexes
    await db.execute('CREATE INDEX idx_lessons_user ON lessons(userId)');
    await db.execute('CREATE INDEX idx_lessons_subject_topic ON lessons(userId, subjectName, topicName)');
    await db.execute('CREATE INDEX idx_lessons_sync ON lessons(isSynced)');
    await db.execute('CREATE INDEX idx_lessons_review ON lessons(nextReviewDate)');
    await db.execute('CREATE INDEX idx_lessons_locked ON lessons(isLocked)');
    
    // Flashcard indexes
    await db.execute('CREATE INDEX idx_flashcards_lesson ON flashcards(lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_user_lesson ON flashcards(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_flashcards_tag ON flashcards(tag_id)');
    await db.execute('CREATE INDEX idx_flashcards_sync ON flashcards(sync_status)');
    
    // File indexes
    await db.execute('CREATE INDEX idx_files_lesson ON files(lesson_id)');
    await db.execute('CREATE INDEX idx_files_user_lesson ON files(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_files_starred ON files(is_starred)');
    await db.execute('CREATE INDEX idx_files_sync ON files(sync_status)');
  }

  static Future<void> _dropBackupTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS topics_backup');
    await db.execute('DROP TABLE IF EXISTS lessons_backup');
    await db.execute('DROP TABLE IF EXISTS flashcards_backup');
    await db.execute('DROP TABLE IF EXISTS files_backup');
  }
}
// lib/core/database/migration_manager.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class MigrationManager {
  static const List<Migration> _migrations = [
    Migration(version: 1, description: 'Initial database creation'),
    Migration(version: 2, description: 'Add sync_queue table'),
    Migration(version: 3, description: 'Add syncStatus to flashcards'),
    Migration(version: 4, description: 'Add files and notes tables'),
  ];

  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('🔄 Migrating database from v$oldVersion to v$newVersion');
    }

    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        if (kDebugMode) {
          print('📝 Applying migration v${migration.version}: ${migration.description}');
        }
        
        try {
          await _applyMigration(db, migration);
          if (kDebugMode) {
            print('✅ Migration v${migration.version} completed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Migration v${migration.version} failed: $e');
          }
          rethrow;
        }
      }
    }

    if (kDebugMode) {
      print('🎉 All migrations completed successfully');
    }
  }

  static Future<void> _applyMigration(Database db, Migration migration) async {
    switch (migration.version) {
      case 1:
        // Initial creation is handled by onCreate
        break;

      case 2:
        await _addSyncQueueTable(db);
        break;

      case 3:
        await _addSyncStatusToFlashcards(db);
        break;

      case 4:
        await _addFilesAndNotesTables(db);
        break;

      default:
        if (kDebugMode) {
          print('⚠️ Unknown migration version: ${migration.version}');
        }
    }
  }

  static Future<void> _addSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entityId TEXT NOT NULL,
        entityType TEXT NOT NULL,
        operationType TEXT NOT NULL,
        payload TEXT,
        createdAt INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_createdAt ON sync_queue (createdAt)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_entityType ON sync_queue (entityType)
    ''');
  }

  static Future<void> _addSyncStatusToFlashcards(Database db) async {
    try {
      // Check if column already exists
      final tableInfo = await db.rawQuery('PRAGMA table_info(flashcards)');
      final hasColumn = tableInfo.any((row) => row['name'] == 'syncStatus');

      if (!hasColumn) {
        await db.execute('''
          ALTER TABLE flashcards ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'pending'
        ''');

        // Create index for the new column
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_flashcards_sync ON flashcards (syncStatus)
        ''');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _addSyncStatusToFlashcards: $e');
      }
      // Don't rethrow - this is a non-critical migration
    }
  }

  static Future<void> _addFilesAndNotesTables(Database db) async {
    // Files table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS files (
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
      CREATE TABLE IF NOT EXISTS notes (
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

    // Create indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_files_lessonId ON files (lessonId)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_files_userId ON files (userId)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_lessonId ON notes (lessonId)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_userId ON notes (userId)
    ''');
  }

  /// Validates database schema integrity
  static Future<bool> validateSchema(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );

      const expectedTables = [
        'subjects',
        'topics', 
        'lessons',
        'flashcards',
        'sync_queue',
        'files',
        'notes'
      ];

      final existingTables = tables.map((t) => t['name'] as String).toSet();
      final missingTables = expectedTables.where((t) => !existingTables.contains(t)).toList();

      if (missingTables.isNotEmpty) {
        if (kDebugMode) {
          print('❌ Missing tables: $missingTables');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ Database schema validation passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Schema validation failed: $e');
      }
      return false;
    }
  }

  /// Gets current database version
  static Future<int> getCurrentVersion(Database db) async {
    final result = await db.rawQuery('PRAGMA user_version');
    return result.first['user_version'] as int;
  }

  /// Sets database version
  static Future<void> setVersion(Database db, int version) async {
    await db.rawUpdate('PRAGMA user_version = $version');
  }

  /// Gets migration history for debugging
  static List<Migration> get allMigrations => List.unmodifiable(_migrations);
}

class Migration {
  final int version;
  final String description;

  const Migration({
    required this.version,
    required this.description,
  });

  @override
  String toString() => 'Migration(v$version: $description)';
}

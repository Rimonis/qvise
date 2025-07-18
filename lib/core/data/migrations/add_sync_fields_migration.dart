// lib/core/data/migrations/add_sync_fields_migration.dart

import 'package:sqflite/sqflite.dart';

class AddSyncFieldsMigration {
  static Future<void> migrate(Database db) async {
    await _migrateTable(db, 'lessons', 'createdAt');
    await _migrateTable(db, 'flashcards', 'created_at');
    await _migrateTable(db, 'subjects', 'createdAt');
    await _migrateTable(db, 'topics', 'createdAt');
  }

  static Future<void> _migrateTable(
      Database db, String tableName, String createdAtColumn) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasVersion = columns.any((col) => col['name'] == 'version');
    final hasUpdatedAt = columns.any((col) => col['name'] == 'updated_at');

    if (!hasVersion) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN version INTEGER DEFAULT 1');
    }
    if (!hasUpdatedAt) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN updated_at INTEGER');
      await db.execute(
          'UPDATE $tableName SET updated_at = $createdAtColumn WHERE updated_at IS NULL');
    }
  }
}

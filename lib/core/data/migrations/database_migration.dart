// lib/core/data/migrations/database_migration.dart

import 'package:path/path.dart';
import 'package:qvise/core/data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseMigration {
  static Future<bool> needsMigration() async {
    final dbPath = await getDatabasesPath();
    final oldContentDbExists = await databaseExists(join(dbPath, 'qvise_content.db'));
    final oldFlashcardDbExists = await databaseExists(join(dbPath, 'qvise_flashcards.db'));
    final newDbExists = await databaseExists(join(dbPath, 'qvise.db'));

    return (oldContentDbExists || oldFlashcardDbExists) && !newDbExists;
  }

  static Future<Database> _openOldContentDb() async {
    final path = join(await getDatabasesPath(), 'qvise_content.db');
    return await openDatabase(path);
  }

  static Future<Database> _openOldFlashcardDb() async {
    final path = join(await getDatabasesPath(), 'qvise_flashcards.db');
    return await openDatabase(path);
  }

  static Future<void> migrateToUnifiedDatabase() async {
    final contentDb = await _openOldContentDb();
    final flashcardDb = await _openOldFlashcardDb();
    final unifiedDb = await AppDatabase.database;
    final dbPath = await getDatabasesPath();

    await unifiedDb.transaction((txn) async {
      final contentTables = ['subjects', 'topics', 'lessons'];
      for (final table in contentTables) {
        final data = await contentDb.query(table);
        for (final row in data) {
          final newRow = Map<String, dynamic>.from(row);
          newRow['version'] = 1;
          newRow['is_deleted'] = 0;
          await txn.insert(table, newRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      final flashcardData = await flashcardDb.query('flashcards');
      for (final row in flashcardData) {
        final newRow = Map<String, dynamic>.from(row);
        newRow['version'] = 1;
        newRow['is_deleted'] = 0;
        await txn.insert('flashcards', newRow, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    await contentDb.close();
    await flashcardDb.close();

    // await deleteDatabase(join(dbPath, 'qvise_content.db'));
    // await deleteDatabase(join(dbPath, 'qvise_flashcards.db'));
    print('Migration complete. Old databases preserved at:');
    print('- $dbPath/qvise_content.db');
    print('- $dbPath/qvise_flashcards.db');
    print('You can manually delete these after verifying the migration.');
  }
}

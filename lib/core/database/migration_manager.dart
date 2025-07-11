// lib/core/database/migration_manager.dart
import 'package:sqflite/sqflite.dart';

class MigrationManager {
  // A map of database versions to the list of migration scripts to run.
  static final Map<int, List<String>> migrations = {
    2:,
    3:,
  };

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      final scripts = migrations[i];
      if (scripts!= null) {
        for (final script in scripts) {
          await db.execute(script);
        }
      }
    }
  }
}
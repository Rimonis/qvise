// lib/core/sync/sync_queue.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:sqflite/sqflite.dart';
import 'sync_operation.dart';

final syncQueueProvider = Provider((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SyncQueue(dbHelper);
});

class SyncQueue {
  final DatabaseHelper _dbHelper;
  static const _tableName = 'sync_queue';

  SyncQueue(this._dbHelper);

  Future<void> enqueue(SyncOperation operation) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      operation.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncOperation>> getPendingOperations({int limit = 50}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      _tableName,
      orderBy: 'createdAt ASC',
      limit: limit,
    );
    return maps.map((map) => SyncOperation.fromDatabase(map)).toList();
  }

  Future<void> removeOperation(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_tableName, where: 'id =?', whereArgs: [id]);
  }

  Future<void> incrementAttempt(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE $_tableName SET attempts = attempts + 1 WHERE id =?',
      [id],
    );
  }
}
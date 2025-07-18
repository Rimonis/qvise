// lib/core/sync/data/datasources/conflict_local_datasource.dart

import 'dart:convert';
import 'package:qvise/core/data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/sync_conflict.dart';

abstract class ConflictLocalDataSource {
  Future<void> saveConflict(SyncConflict conflict);
  Future<List<SyncConflict>> getUnresolvedConflicts();
  Future<SyncConflict?> getConflict(String id);
  Future<void> resolveConflict(String id, String resolutionType);
  Future<int> getUnresolvedCount();
  Future<void> deleteResolvedConflicts({int daysOld = 30});
}

class ConflictLocalDataSourceImpl implements ConflictLocalDataSource {
  Future<Database> get database async => AppDatabase.database;

  @override
  Future<void> saveConflict(SyncConflict conflict) async {
    final db = await database;
    await db.insert(
      'conflicts',
      {
        'id': conflict.id,
        'entity_type': conflict.entityType,
        'entity_id': conflict.entityId,
        'local_data': jsonEncode(conflict.localData),
        'remote_data': jsonEncode(conflict.remoteData),
        'local_version': conflict.localVersion,
        'remote_version': conflict.remoteVersion,
        'local_updated_at': conflict.localUpdatedAt.toIso8601String(),
        'remote_updated_at': conflict.remoteUpdatedAt.toIso8601String(),
        'detected_at': conflict.detectedAt.toIso8601String(),
        'status': conflict.status,
        'metadata':
            conflict.metadata != null ? jsonEncode(conflict.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    final db = await database;
    final results = await db.query(
      'conflicts',
      where: 'status = ?',
      whereArgs: ['unresolved'],
      orderBy: 'detected_at DESC',
    );

    return results.map((map) => _mapToConflict(map)).toList();
  }

  @override
  Future<SyncConflict?> getConflict(String id) async {
    final db = await database;
    final results = await db.query(
      'conflicts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _mapToConflict(results.first);
  }

  @override
  Future<void> resolveConflict(String id, String resolutionType) async {
    final db = await database;
    await db.update(
      'conflicts',
      {
        'status': 'resolved',
        'resolution_type': resolutionType,
        'resolved_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> getUnresolvedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM conflicts WHERE status = ?',
      ['unresolved'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> deleteResolvedConflicts({int daysOld = 30}) async {
    final db = await database;
    final threshold =
        DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    await db.delete(
      'conflicts',
      where: 'status = ? AND resolved_at < ?',
      whereArgs: ['resolved', threshold],
    );
  }

  SyncConflict _mapToConflict(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      localData: jsonDecode(map['local_data'] as String),
      remoteData: jsonDecode(map['remote_data'] as String),
      localVersion: map['local_version'] as int,
      remoteVersion: map['remote_version'] as int,
      localUpdatedAt: DateTime.parse(map['local_updated_at'] as String),
      remoteUpdatedAt: DateTime.parse(map['remote_updated_at'] as String),
      detectedAt: DateTime.parse(map['detected_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
      status: map['status'] as String,
      resolutionType: map['resolution_type'] as String?,
      resolvedBy: map['resolved_by'] as String?,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String)
          : null,
    );
  }
}

// lib/features/files/data/datasources/file_local_data_source.dart
import 'package:sqflite/sqflite.dart';
import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import '../models/file_model.dart';

abstract class FileLocalDataSource {
  Future<void> createFile(FileModel file);
  Future<void> updateFile(FileModel file);
  Future<void> deleteFile(String fileId);
  Future<void> deleteFilesByLesson(String lessonId); // Added for cascade delete
  Future<List<FileModel>> getFilesByLessonIds(List<String> lessonIds); // Added for bulk operations
  Future<FileModel?> getFileById(String fileId);
  Future<List<FileModel>> getFilesByLessonId(String lessonId);
  Future<List<FileModel>> getStarredFiles();
  Future<List<FileModel>> getFilesForSync();
}

class FileLocalDataSourceImpl extends TransactionalDataSource implements FileLocalDataSource {
  static const _tableName = 'files';

  @override
  Future<void> createFile(FileModel file) async {
    final db = await database;
    await db.insert(_tableName, file.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateFile(FileModel file) async {
    final db = await database;
    await db.update(_tableName, file.toDb(), 
        where: 'id = ?', whereArgs: [file.id]);
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [fileId]);
  }

  @override
  Future<void> deleteFilesByLesson(String lessonId) async {
    final db = await database;
    await db.delete(_tableName, where: 'lesson_id = ?', whereArgs: [lessonId]);
  }

  @override
  Future<List<FileModel>> getFilesByLessonIds(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = lessonIds.map((_) => '?').join(',');
    final maps = await db.query(
      _tableName,
      where: 'lesson_id IN ($placeholders)',
      whereArgs: lessonIds,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FileModel.fromDb(map)).toList();
  }

  @override
  Future<FileModel?> getFileById(String fileId) async {
    final db = await database;
    final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [fileId]);
    if (maps.isNotEmpty) {
      return FileModel.fromDb(maps.first);
    }
    return null;
  }

  @override
  Future<List<FileModel>> getFilesByLessonId(String lessonId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FileModel.fromDb(map)).toList();
  }

  @override
  Future<List<FileModel>> getStarredFiles() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'is_starred = 1',
      orderBy: 'updated_at DESC NULLS LAST, created_at DESC',
    );
    return maps.map((map) => FileModel.fromDb(map)).toList();
  }

  @override
  Future<List<FileModel>> getFilesForSync() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: "sync_status IN ('queued', 'failed')",
    );
    return maps.map((map) => FileModel.fromDb(map)).toList();
  }
}
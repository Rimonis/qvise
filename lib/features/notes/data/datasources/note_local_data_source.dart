// lib/features/notes/data/datasources/note_local_data_source.dart

import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note_model.dart';
import '../../domain/entities/note.dart';

abstract class NoteLocalDataSource extends TransactionalDataSource {
  Future<void> insertNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String noteId);
  Future<NoteModel?> getNote(String noteId);
  Future<List<NoteModel>> getNotesByLesson(String lessonId);
  Future<List<NoteModel>> getAllNotes(String userId);
  Future<int> getNoteCount(String lessonId);
  Future<void> deleteNotesByLesson(String lessonId);
  Future<List<Note>> getPendingSync();
  Future<void> markAsSynced(String noteId);
  Future<void> upsert(Note note);
}

class NoteLocalDataSourceImpl extends TransactionalDataSource implements NoteLocalDataSource {
  @override
  Future<void> insertNote(NoteModel note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
      version: note.version + 1,
    );
    
    await db.update(
      'notes',
      updatedNote.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  @override
  Future<NoteModel?> getNote(String noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [noteId],
    );

    if (maps.isEmpty) return null;
    return NoteModel.fromMap(maps.first);
  }

  @override
  Future<List<NoteModel>> getNotesByLesson(String lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'lesson_id = ? AND is_deleted = 0',
      whereArgs: [lessonId],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
  }

  @override
  Future<List<NoteModel>> getAllNotes(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
  }

  @override
  Future<int> getNoteCount(String lessonId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE lesson_id = ? AND is_deleted = 0',
      [lessonId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> deleteNotesByLesson(String lessonId) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<List<Note>> getPendingSync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]).toEntity());
  }

  @override
  Future<void> markAsSynced(String noteId) async {
    final db = await database;
    await db.update(
      'notes',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  @override
  Future<void> upsert(Note note) async {
    final noteModel = NoteModel.fromEntity(note);
    final db = await database;
    await db.insert(
      'notes',
      noteModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
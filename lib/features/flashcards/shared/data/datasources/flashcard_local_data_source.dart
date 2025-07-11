// lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/security/field_encryption.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardLocalDataSource {
  Future<void> upsertFlashcard(FlashcardModel flashcard);
  Future<void> deleteFlashcard(String id);
  Future<void> deleteFlashcardsByLesson(String lessonId);
  Future<void> deleteFlashcardsByTopic({required String userId, required String subjectName, required String topicName});
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId);
}

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  final DatabaseHelper _dbHelper;
  final FieldEncryption _fieldEncryption;

  FlashcardLocalDataSourceImpl(this._dbHelper, this._fieldEncryption);

  Future<Database> get _db async => _dbHelper.database;

  Future<Map<String, dynamic>> _encryptNotes(Map<String, dynamic> data) async {
    if (data['notes']!= null) {
      final encryptedNotes = await _fieldEncryption.encryptField(data['notes']);
      data['notes'] = encryptedNotes;
    }
    return data;
  }

  Future<FlashcardModel> _decryptNotes(FlashcardModel model) async {
    if (model.notes!= null) {
      final decryptedNotes = await _fieldEncryption.decryptField(model.notes);
      return model.copyWith(notes: decryptedNotes);
    }
    return model;
  }

  @override
  Future<void> upsertFlashcard(FlashcardModel flashcard) async {
    final db = await _db;
    final data = await _encryptNotes(flashcard.toDatabase());
    await db.insert(
      DatabaseHelper.tableFlashcards,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableFlashcards, where: 'id =?', whereArgs: [id]);
  }

  @override
  Future<void> deleteFlashcardsByLesson(String lessonId) async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableFlashcards, where: 'lessonId =?', whereArgs: [lessonId]);
  }
  
  @override
  Future<void> deleteFlashcardsByTopic({required String userId, required String subjectName, required String topicName}) async {
    final db = await _db;
    final lessons = await db.query(DatabaseHelper.tableLessons, where: 'userId =? AND subjectName =? AND topicName =?', whereArgs: [userId, subjectName, topicName]);
    final lessonIds = lessons.map((l) => l['id'] as String).toList();
    if (lessonIds.isEmpty) return;

    final batch = db.batch();
    for (final lessonId in lessonIds) {
      batch.delete(DatabaseHelper.tableFlashcards, where: 'lessonId =?', whereArgs: [lessonId]);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByLesson(String lessonId) async {
    final db = await _db;
    final maps = await db.query(DatabaseHelper.tableFlashcards, where: 'lessonId =?', whereArgs: [lessonId]);
    final models = maps.map((map) => FlashcardModel.fromDatabase(map)).toList();
    return Future.wait(models.map((m) => _decryptNotes(m)));
  }
}
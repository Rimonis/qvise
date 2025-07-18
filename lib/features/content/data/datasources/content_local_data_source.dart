// lib/features/content/data/datasources/content_local_data_source.dart

import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import 'package:sqflite/sqflite.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/lesson_model.dart';

abstract class ContentLocalDataSource {
  Future<void> initDatabase();
  Future<List<SubjectModel>> getSubjects(String userId);
  Future<SubjectModel?> getSubject(String userId, String subjectName);
  Future<void> insertOrUpdateSubject(SubjectModel subject);
  Future<void> deleteSubject(String userId, String subjectName);
  Future<List<TopicModel>> getTopicsBySubject(String userId, String subjectName);
  Future<TopicModel?> getTopic(
      String userId, String subjectName, String topicName);
  Future<void> insertOrUpdateTopic(TopicModel topic);
  Future<void> deleteTopic(String userId, String subjectName, String topicName);
  Future<List<LessonModel>> getLessonsByTopic(
      String userId, String subjectName, String topicName);
  Future<List<LessonModel>> getAllLessons(String userId);
  Future<List<LessonModel>> getUnsyncedLessons(String userId);
  Future<LessonModel?> getLesson(String lessonId);
  Future<void> insertOrUpdateLesson(LessonModel lesson);
  Future<void> deleteLesson(String lessonId);
  Future<void> markLessonAsSynced(String lessonId);
  Future<void> updateSubjectProficiency(
      String userId, String subjectName, double proficiency);
  Future<void> updateTopicProficiency(
      String userId, String subjectName, String topicName, double proficiency);
  Future<List<LessonModel>> getModifiedSince(DateTime since);
  Future<List<LessonModel>> getUnpushedChanges();
  Future<void> markAsSynced(String lessonId);
}

class ContentLocalDataSourceImpl extends TransactionalDataSource
    implements ContentLocalDataSource {
  @override
  Future<void> initDatabase() async {
    await database;
  }

  @override
  Future<List<SubjectModel>> getSubjects(String userId) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'userId = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => SubjectModel.fromDatabase(map)).toList();
  }

  @override
  Future<SubjectModel?> getSubject(String userId, String subjectName) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'userId = ? AND name = ? AND is_deleted = 0',
      whereArgs: [userId, subjectName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SubjectModel.fromDatabase(maps.first);
  }

  @override
  Future<void> insertOrUpdateSubject(SubjectModel subject) async {
    final db = await database;
    await db.insert(
      'subjects',
      subject.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSubject(String userId, String subjectName) async {
    final db = await database;
    await db.update(
      'subjects',
      {'is_deleted': 1},
      where: 'userId = ? AND name = ?',
      whereArgs: [userId, subjectName],
    );
  }

  @override
  Future<List<TopicModel>> getTopicsBySubject(
      String userId, String subjectName) async {
    final db = await database;
    final maps = await db.query(
      'topics',
      where: 'userId = ? AND subjectName = ? AND is_deleted = 0',
      whereArgs: [userId, subjectName],
      orderBy: 'name ASC',
    );
    return maps.map((map) => TopicModel.fromDatabase(map)).toList();
  }

  @override
  Future<TopicModel?> getTopic(
      String userId, String subjectName, String topicName) async {
    final db = await database;
    final maps = await db.query(
      'topics',
      where: 'userId = ? AND subjectName = ? AND name = ? AND is_deleted = 0',
      whereArgs: [userId, subjectName, topicName],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TopicModel.fromDatabase(maps.first);
  }

  @override
  Future<void> insertOrUpdateTopic(TopicModel topic) async {
    final db = await database;
    await db.insert(
      'topics',
      topic.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTopic(
      String userId, String subjectName, String topicName) async {
    final db = await database;
    await db.update(
      'topics',
      {'is_deleted': 1},
      where: 'userId = ? AND subjectName = ? AND name = ?',
      whereArgs: [userId, subjectName, topicName],
    );
  }

  @override
  Future<List<LessonModel>> getLessonsByTopic(
      String userId, String subjectName, String topicName) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'userId = ? AND subjectName = ? AND topicName = ? AND is_deleted = 0',
      whereArgs: [userId, subjectName, topicName],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<LessonModel>> getAllLessons(String userId) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'userId = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'nextReviewDate ASC',
    );
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<LessonModel>> getUnsyncedLessons(String userId) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'userId = ? AND isSynced = 0 AND is_deleted = 0',
      whereArgs: [userId],
    );
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<LessonModel?> getLesson(String lessonId) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LessonModel.fromDatabase(maps.first);
  }

  @override
  Future<void> insertOrUpdateLesson(LessonModel lesson) async {
    final db = await database;
    await db.insert(
      'lessons',
      lesson.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    final db = await database;
    await db.update(
      'lessons',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<void> markLessonAsSynced(String lessonId) async {
    final db = await database;
    await db.update(
      'lessons',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  @override
  Future<void> updateSubjectProficiency(
      String userId, String subjectName, double proficiency) async {
    final db = await database;
    await db.update(
      'subjects',
      {'proficiency': proficiency},
      where: 'userId = ? AND name = ?',
      whereArgs: [userId, subjectName],
    );
  }

  @override
  Future<void> updateTopicProficiency(
      String userId, String subjectName, String topicName, double proficiency) async {
    final db = await database;
    await db.update(
      'topics',
      {'proficiency': proficiency},
      where: 'userId = ? AND subjectName = ? AND name = ?',
      whereArgs: [userId, subjectName, topicName],
    );
  }

  @override
  Future<List<LessonModel>> getModifiedSince(DateTime since) async {
    final db = await database;
    final results = await db.query(
      'lessons',
      where: 'updated_at > ? AND is_deleted = 0',
      whereArgs: [since.millisecondsSinceEpoch],
    );
    return results.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<LessonModel>> getUnpushedChanges() async {
    final db = await database;
    final results = await db.query(
      'lessons',
      where: 'isSynced = 0 AND is_deleted = 0',
    );
    return results.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> markAsSynced(String lessonId) async {
    final db = await database;
    await db.update(
      'lessons',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }
}

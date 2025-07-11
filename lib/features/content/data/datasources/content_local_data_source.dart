// lib/features/content/data/datasources/content_local_data_source.dart
import 'package:qvise/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/lesson_model.dart';

abstract class ContentLocalDataSource {
  Future<List<SubjectModel>> getSubjects(String userId);
  Future<void> insertOrUpdateSubject(SubjectModel subject);
  Future<void> deleteSubject(String userId, String subjectName);
  Future<List<TopicModel>> getTopicsBySubject(String userId, String subjectName);
  Future<void> insertOrUpdateTopic(TopicModel topic);
  Future<void> deleteTopic(String userId, String subjectName, String topicName);
  Future<List<LessonModel>> getLessonsByTopic(String userId, String subjectName, String topicName);
  Future<List<LessonModel>> getAllLessons(String userId);
  Future<void> insertOrUpdateLesson(LessonModel lesson);
  Future<void> deleteLesson(String userId, String lessonId);
}

class ContentLocalDataSourceImpl implements ContentLocalDataSource {
  final DatabaseHelper _dbHelper;

  ContentLocalDataSourceImpl(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  @override
  Future<List<SubjectModel>> getSubjects(String userId) async {
    final db = await _db;
    final maps = await db.query(DatabaseHelper.tableSubjects, where: 'userId =?', whereArgs: [userId]);
    return maps.map((map) => SubjectModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> insertOrUpdateSubject(SubjectModel subject) async {
    final db = await _db;
    await db.insert(
      DatabaseHelper.tableSubjects,
      subject.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSubject(String userId, String subjectName) async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableSubjects, where: 'userId =? AND name =?', whereArgs: [userId, subjectName]);
  }

  @override
  Future<List<TopicModel>> getTopicsBySubject(String userId, String subjectName) async {
    final db = await _db;
    final maps = await db.query(DatabaseHelper.tableTopics, where: 'userId =? AND subjectName =?', whereArgs: [userId, subjectName]);
    return maps.map((map) => TopicModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> insertOrUpdateTopic(TopicModel topic) async {
    final db = await _db;
    await db.insert(
      DatabaseHelper.tableTopics,
      topic.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTopic(String userId, String subjectName, String topicName) async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableTopics, where: 'userId =? AND subjectName =? AND name =?', whereArgs: [userId, subjectName, topicName]);
  }

  @override
  Future<List<LessonModel>> getLessonsByTopic(String userId, String subjectName, String topicName) async {
    final db = await _db;
    final maps = await db.query(DatabaseHelper.tableLessons, where: 'userId =? AND subjectName =? AND topicName =?', whereArgs: [userId, subjectName, topicName]);
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<List<LessonModel>> getAllLessons(String userId) async {
    final db = await _db;
    final maps = await db.query(DatabaseHelper.tableLessons, where: 'userId =?', whereArgs: [userId]);
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }

  @override
  Future<void> insertOrUpdateLesson(LessonModel lesson) async {
    final db = await _db;
    await db.insert(
      DatabaseHelper.tableLessons,
      lesson.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteLesson(String userId, String lessonId) async {
    final db = await _db;
    await db.delete(DatabaseHelper.tableLessons, where: 'userId =? AND id =?', whereArgs: [userId, lessonId]);
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/lesson_model.dart';

abstract class ContentLocalDataSource {
  // Database initialization
  Future<void> initDatabase();
  
  // Subject operations
  Future<List<SubjectModel>> getSubjects(String userId);
  Future<SubjectModel?> getSubject(String userId, String subjectName);
  Future<void> insertOrUpdateSubject(SubjectModel subject);
  Future<void> deleteSubject(String userId, String subjectName);
  
  // Topic operations
  Future<List<TopicModel>> getTopicsBySubject(String userId, String subjectName);
  Future<TopicModel?> getTopic(String userId, String subjectName, String topicName);
  Future<void> insertOrUpdateTopic(TopicModel topic);
  Future<void> deleteTopic(String userId, String subjectName, String topicName);
  
  // Lesson operations
  Future<List<LessonModel>> getLessonsByTopic(String userId, String subjectName, String topicName);
  Future<List<LessonModel>> getAllLessons(String userId);
  Future<List<LessonModel>> getUnsyncedLessons(String userId);
  Future<LessonModel?> getLesson(String lessonId);
  Future<void> insertOrUpdateLesson(LessonModel lesson);
  Future<void> deleteLesson(String lessonId);
  Future<void> markLessonAsSynced(String lessonId);
  
  // Proficiency updates
  Future<void> updateSubjectProficiency(String userId, String subjectName, double proficiency);
  Future<void> updateTopicProficiency(String userId, String subjectName, String topicName, double proficiency);
}

class ContentLocalDataSourceImpl implements ContentLocalDataSource {
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'qvise_content.db');
    
    return await openDatabase(
      path,
      version: 2, // Incremented version for schema update
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }
  
  Future<void> _createDB(Database db, int version) async {
    // Subjects table
    await db.execute('''
      CREATE TABLE subjects(
        name TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL,
        lessonCount INTEGER NOT NULL,
        topicCount INTEGER NOT NULL,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        PRIMARY KEY (userId, name)
      )
    ''');
    
    // Topics table
    await db.execute('''
      CREATE TABLE topics(
        name TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        userId TEXT NOT NULL,
        proficiency REAL NOT NULL,
        lessonCount INTEGER NOT NULL,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        PRIMARY KEY (userId, subjectName, name)
      )
    ''');
    
    // Lessons table with new fields
    await db.execute('''
      CREATE TABLE lessons(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        topicName TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        lockedAt INTEGER,
        nextReviewDate INTEGER NOT NULL,
        lastReviewedAt INTEGER,
        reviewStage INTEGER NOT NULL,
        proficiency REAL NOT NULL,
        isLocked INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0,
        flashcardCount INTEGER NOT NULL DEFAULT 0,
        fileCount INTEGER NOT NULL DEFAULT 0,
        noteCount INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_lessons_user ON lessons(userId)');
    await db.execute('CREATE INDEX idx_lessons_subject_topic ON lessons(userId, subjectName, topicName)');
    await db.execute('CREATE INDEX idx_lessons_sync ON lessons(isSynced)');
    await db.execute('CREATE INDEX idx_lessons_review ON lessons(nextReviewDate)');
    await db.execute('CREATE INDEX idx_lessons_locked ON lessons(isLocked)');
  }
  
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to lessons table
      await db.execute('ALTER TABLE lessons ADD COLUMN lockedAt INTEGER');
      await db.execute('ALTER TABLE lessons ADD COLUMN isLocked INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE lessons ADD COLUMN flashcardCount INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE lessons ADD COLUMN fileCount INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE lessons ADD COLUMN noteCount INTEGER NOT NULL DEFAULT 0');
      
      // Add new index
      await db.execute('CREATE INDEX idx_lessons_locked ON lessons(isLocked)');
    }
  }
  
  @override
  Future<void> initDatabase() async {
    await database;
  }
  
  // Subject operations
  @override
  Future<List<SubjectModel>> getSubjects(String userId) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'userId = ?',
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
      where: 'userId = ? AND name = ?',
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
    await db.delete(
      'subjects',
      where: 'userId = ? AND name = ?',
      whereArgs: [userId, subjectName],
    );
  }
  
  // Topic operations
  @override
  Future<List<TopicModel>> getTopicsBySubject(String userId, String subjectName) async {
    final db = await database;
    final maps = await db.query(
      'topics',
      where: 'userId = ? AND subjectName = ?',
      whereArgs: [userId, subjectName],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => TopicModel.fromDatabase(map)).toList();
  }
  
  @override
  Future<TopicModel?> getTopic(String userId, String subjectName, String topicName) async {
    final db = await database;
    final maps = await db.query(
      'topics',
      where: 'userId = ? AND subjectName = ? AND name = ?',
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
  Future<void> deleteTopic(String userId, String subjectName, String topicName) async {
    final db = await database;
    await db.delete(
      'topics',
      where: 'userId = ? AND subjectName = ? AND name = ?',
      whereArgs: [userId, subjectName, topicName],
    );
  }
  
  // Lesson operations
  @override
  Future<List<LessonModel>> getLessonsByTopic(String userId, String subjectName, String topicName) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'userId = ? AND subjectName = ? AND topicName = ?',
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
      where: 'userId = ?',
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
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    
    return maps.map((map) => LessonModel.fromDatabase(map)).toList();
  }
  
  @override
  Future<LessonModel?> getLesson(String lessonId) async {
    final db = await database;
    final maps = await db.query(
      'lessons',
      where: 'id = ?',
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
    await db.delete(
      'lessons',
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
  
  // Proficiency updates
  @override
  Future<void> updateSubjectProficiency(String userId, String subjectName, double proficiency) async {
    final db = await database;
    await db.update(
      'subjects',
      {'proficiency': proficiency},
      where: 'userId = ? AND name = ?',
      whereArgs: [userId, subjectName],
    );
  }
  
  @override
  Future<void> updateTopicProficiency(String userId, String subjectName, String topicName, double proficiency) async {
    final db = await database;
    await db.update(
      'topics',
      {'proficiency': proficiency},
      where: 'userId = ? AND subjectName = ? AND name = ?',
      whereArgs: [userId, subjectName, topicName],
    );
  }
}
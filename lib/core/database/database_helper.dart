// lib/core/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'migration_manager.dart';

class DatabaseHelper {
  static const _databaseName = "qvise_app.db";
  static const _databaseVersion = 3; // Incremented for new migrations

  // --- Table and Column Definitions ---
  static const tableUsers = 'users';
  static const tableSubjects = 'subjects';
  static const tableTopics = 'topics';
  static const tableLessons = 'lessons';
  static const tableFlashcards = 'flashcards';
  static const tableSyncQueue = 'sync_queue';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database!= null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE $tableUsers(
        id TEXT PRIMARY KEY, 
        data TEXT
      )
    ''');
    batch.execute('''
      CREATE TABLE $tableSubjects(
        name TEXT, 
        userId TEXT, 
        proficiency REAL, 
        lessonCount INTEGER, 
        topicCount INTEGER, 
        lastStudied INTEGER, 
        createdAt INTEGER,
        PRIMARY KEY (userId, name)
      )
    ''');
    batch.execute('''
      CREATE TABLE $tableTopics(
        name TEXT, 
        subjectName TEXT, 
        userId TEXT, 
        proficiency REAL, 
        lessonCount INTEGER, 
        lastStudied INTEGER, 
        createdAt INTEGER,
        PRIMARY KEY (userId, subjectName, name)
      )
    ''');
    batch.execute('''
      CREATE TABLE $tableLessons(
        id TEXT PRIMARY KEY, 
        userId TEXT, 
        subjectName TEXT, 
        topicName TEXT, 
        title TEXT, 
        createdAt INTEGER, 
        updatedAt INTEGER,
        nextReviewDate INTEGER, 
        lastReviewedAt INTEGER, 
        reviewStage INTEGER, 
        proficiency REAL, 
        isLocked INTEGER
      )
    ''');
    batch.execute('''
      CREATE TABLE $tableFlashcards(
        id TEXT PRIMARY KEY, 
        lessonId TEXT, 
        userId TEXT, 
        frontContent TEXT, 
        backContent TEXT, 
        tag TEXT, 
        hints TEXT, 
        difficulty REAL, 
        masteryLevel REAL, 
        createdAt INTEGER, 
        updatedAt INTEGER,
        lastReviewedAt INTEGER, 
        reviewCount INTEGER, 
        correctCount INTEGER, 
        isFavorite INTEGER, 
        isActive INTEGER, 
        notes TEXT, 
        syncStatus TEXT
      )
    ''');
    batch.execute('''
      CREATE TABLE $tableSyncQueue(
        id TEXT PRIMARY KEY,
        entityId TEXT NOT NULL,
        entityType TEXT NOT NULL,
        operationType TEXT NOT NULL,
        payload TEXT,
        createdAt INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await batch.commit();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await MigrationManager.onUpgrade(db, oldVersion, newVersion);
  }
}
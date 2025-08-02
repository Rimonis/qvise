// lib/core/data/unit_of_work.dart

import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import 'package:qvise/features/content/data/datasources/content_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart';
import 'package:qvise/features/files/data/datasources/file_local_data_source.dart';
import 'package:qvise/features/notes/data/datasources/note_local_data_source.dart'; // ADD THIS
import 'package:sqflite/sqflite.dart';

abstract class IUnitOfWork {
  ContentLocalDataSource get content;
  FlashcardLocalDataSource get flashcard;
  FileLocalDataSource get file;
  NoteLocalDataSource get note; // ADD THIS
  Future<T> transaction<T>(Future<T> Function() action);
}

class SqliteUnitOfWork implements IUnitOfWork {
  @override
  final ContentLocalDataSource content;
  @override
  final FlashcardLocalDataSource flashcard;
  @override
  final FileLocalDataSource file;
  @override
  final NoteLocalDataSource note; // ADD THIS

  SqliteUnitOfWork({
    required this.content,
    required this.flashcard,
    required this.file,
    required this.note, // ADD THIS
  });

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    final db = await AppDatabase.database;
    return db.transaction((txn) async {
      // Inject transaction into data sources
      (content as TransactionalDataSource).setTransaction(txn);
      (flashcard as TransactionalDataSource).setTransaction(txn);
      (file as TransactionalDataSource).setTransaction(txn);
      (note as TransactionalDataSource).setTransaction(txn); // ADD THIS

      try {
        return await action();
      } finally {
        // Clean up
        (content as TransactionalDataSource).setTransaction(null);
        (flashcard as TransactionalDataSource).setTransaction(null);
        (file as TransactionalDataSource).setTransaction(null);
        (note as TransactionalDataSource).setTransaction(null); // ADD THIS
      }
    });
  }
}
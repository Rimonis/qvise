// lib/core/data/unit_of_work.dart

import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/datasources/transactional_data_source.dart';
import 'package:qvise/features/content/data/datasources/content_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart';
import 'package:sqflite/sqflite.dart';

abstract class IUnitOfWork {
  ContentLocalDataSource get content;
  FlashcardLocalDataSource get flashcard;
  Future<T> transaction<T>(Future<T> Function() action);
}

class SqliteUnitOfWork implements IUnitOfWork {
  @override
  final ContentLocalDataSource content;
  @override
  final FlashcardLocalDataSource flashcard;

  SqliteUnitOfWork({
    required this.content,
    required this.flashcard,
  });

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    final db = await AppDatabase.database;
    return db.transaction((txn) async {
      // Inject transaction into data sources
      (content as TransactionalDataSource).setTransaction(txn);
      (flashcard as TransactionalDataSource).setTransaction(txn);

      try {
        return await action();
      } finally {
        // Clean up
        (content as TransactionalDataSource).setTransaction(null);
        (flashcard as TransactionalDataSource).setTransaction(null);
      }
    });
  }
}

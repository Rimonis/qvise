// lib/core/data/providers/data_providers.dart

import 'package:qvise/core/data/database/app_database.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/features/content/data/datasources/content_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'data_providers.g.dart';

// --- Core Database Provider ---
@Riverpod(keepAlive: true)
Future<Database> database(DatabaseRef ref) async {
  return AppDatabase.database;
}

// --- Data Source Providers ---
@Riverpod(keepAlive: true)
ContentLocalDataSource contentLocalDataSource(ContentLocalDataSourceRef ref) {
  return ContentLocalDataSourceImpl();
}

@Riverpod(keepAlive: true)
FlashcardLocalDataSource flashcardLocalDataSource(
    FlashcardLocalDataSourceRef ref) {
  return FlashcardLocalDataSourceImpl();
}

// --- Unit of Work Provider ---
@Riverpod(keepAlive: true)
IUnitOfWork unitOfWork(UnitOfWorkRef ref) {
  return SqliteUnitOfWork(
    content: ref.watch(contentLocalDataSourceProvider),
    flashcard: ref.watch(flashcardLocalDataSourceProvider),
  );
}


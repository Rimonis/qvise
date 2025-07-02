// lib/features/flashcards/shared/presentation/providers/flashcard_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import '/../../../core/providers/providers.dart';
import '../../data/datasources/flashcard_local_data_source.dart';
import '../../data/datasources/flashcard_remote_data_source.dart';
import '../../data/repositories/flashcard_repository_impl.dart';

// Data sources
final flashcardLocalDataSourceProvider = Provider<FlashcardLocalDataSource>((ref) {
  return FlashcardLocalDataSourceImpl();
});

final flashcardRemoteDataSourceProvider = Provider<FlashcardRemoteDataSource>((ref) {
  return FlashcardRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

// Repository
final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepositoryImpl(
    localDataSource: ref.watch(flashcardLocalDataSourceProvider),
    remoteDataSource: ref.watch(flashcardRemoteDataSourceProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});
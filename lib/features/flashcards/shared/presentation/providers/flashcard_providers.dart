// lib/features/flashcards/shared/presentation/providers/flashcard_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/content_providers.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:qvise/core/providers/providers.dart';
import '../../data/datasources/flashcard_local_data_source.dart';
import '../../data/datasources/flashcard_remote_data_source.dart';
import '../../data/repositories/flashcard_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flashcard_providers.g.dart';

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
    contentRepository: ref.watch(contentRepositoryProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

@riverpod
Future<List<Flashcard>> flashcardsByLesson(Ref ref, String lessonId) async {
  final repository = ref.watch(flashcardRepositoryProvider);
  final result = await repository.getFlashcardsByLesson(lessonId);
  return result.fold(
    (l) => [],
    (r) => r,
  );
}
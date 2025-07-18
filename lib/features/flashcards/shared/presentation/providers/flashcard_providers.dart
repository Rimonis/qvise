// lib/features/flashcards/shared/presentation/providers/flashcard_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/features/flashcards/creation/domain/usecases/update_flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import '../../data/datasources/flashcard_remote_data_source.dart';
import '../../data/repositories/flashcard_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flashcard_providers.g.dart';

// Data sources
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
    unitOfWork: ref.watch(unitOfWorkProvider),
    connectionChecker: ref.watch(internetConnectionCheckerProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

// Provider for the update flashcard use case
final updateFlashcardProvider = Provider<UpdateFlashcard>((ref) {
  return UpdateFlashcard(ref.watch(flashcardRepositoryProvider));
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
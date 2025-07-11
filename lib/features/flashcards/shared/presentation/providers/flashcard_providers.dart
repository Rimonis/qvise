// lib/features/flashcards/shared/presentation/providers/flashcard_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/database/database_helper.dart';
import 'package:qvise/core/providers/providers.dart';
import 'package:qvise/core/security/field_encryption.dart';
import 'package:qvise/core/sync/sync_queue.dart';
import 'package:qvise/features/flashcards/shared/domain/entities/flashcard.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/flashcard_local_data_source.dart';
import '../../data/datasources/flashcard_remote_data_source.dart';
import '../../data/repositories/flashcard_repository_impl.dart';

part 'flashcard_providers.g.dart';

// Data sources
final flashcardLocalDataSourceProvider = Provider<FlashcardLocalDataSource>((ref) {
  return FlashcardLocalDataSourceImpl(
    ref.watch(databaseHelperProvider),
    ref.watch(fieldEncryptionProvider),
  );
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
    syncQueue: ref.watch(syncQueueProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

// --- UI State Providers ---

@riverpod
Future<List<Flashcard>> flashcardsByLesson(FlashcardsByLessonRef ref, String lessonId) async {
  final repository = ref.watch(flashcardRepositoryProvider);
  final result = await repository.getFlashcardsByLesson(lessonId);
  return result.fold(
    (error) => throw error, // Propagate AppError to be handled by AsyncValue.when
    (flashcards) => flashcards,
  );
}
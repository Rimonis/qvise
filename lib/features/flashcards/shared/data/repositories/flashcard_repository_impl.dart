// lib/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/sync/sync_operation.dart';
import 'package:qvise/core/sync/sync_queue.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/flashcard_local_data_source.dart';
import '../datasources/flashcard_remote_data_source.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardLocalDataSource localDataSource;
  final FlashcardRemoteDataSource remoteDataSource;
  final SyncQueue syncQueue;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final Uuid _uuid;

  FlashcardRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncQueue,
    required this.firebaseAuth,
  }) : _uuid = const Uuid();

  String get _userId => firebaseAuth.currentUser?.uid?? '';

  @override
  Future<Either<AppError, Flashcard>> createFlashcard(Flashcard flashcard) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));

      final now = DateTime.now();
      final newFlashcard = flashcard.copyWith(
        id: _uuid.v4(),
        userId: _userId,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );

      await localDataSource.upsertFlashcard(FlashcardModel.fromEntity(newFlashcard));

      final operation = SyncOperation.create(
        entityId: newFlashcard.id,
        entityType: 'flashcard',
        payload: FlashcardModel.fromEntity(newFlashcard).toJson(),
      );
      await syncQueue.enqueue(operation);

      return Right(newFlashcard);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to create flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Flashcard>> updateFlashcard(Flashcard flashcard) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));

      final updatedFlashcard = flashcard.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await localDataSource.upsertFlashcard(FlashcardModel.fromEntity(updatedFlashcard));

      final operation = SyncOperation.update(
        entityId: updatedFlashcard.id,
        entityType: 'flashcard',
        payload: FlashcardModel.fromEntity(updatedFlashcard).toJson(),
      );
      await syncQueue.enqueue(operation);

      return Right(updatedFlashcard);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to update flashcard: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AppError, void>> deleteFlashcard(String id) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      
      await localDataSource.deleteFlashcard(id);

      final operation = SyncOperation.delete(
        entityId: id,
        entityType: 'flashcard',
      );
      await syncQueue.enqueue(operation);

      return const Right(null);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to delete flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Flashcard>>> getFlashcardsByLesson(String lessonId) async {
    try {
      final models = await localDataSource.getFlashcardsByLesson(lessonId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get flashcards: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AppError, void>> syncFlashcardsToRemote(List<Flashcard> flashcards) async {
    try {
      final models = flashcards.map((f) => FlashcardModel.fromEntity(f)).toList();
      await remoteDataSource.syncFlashcards(models);
      
      final syncedFlashcards = flashcards.map((f) => f.copyWith(syncStatus: SyncStatus.synced)).toList();
      for (final card in syncedFlashcards) {
        await localDataSource.upsertFlashcard(FlashcardModel.fromEntity(card));
      }
      return const Right(null);
    } catch (e) {
      return Left(AppError.sync(message: 'Failed to sync flashcards to remote: ${e.toString()}'));
    }
  }
}

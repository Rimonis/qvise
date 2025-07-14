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

  String get _userId => firebaseAuth.currentUser?.uid ?? '';

  @override
  Future<Either<AppError, Flashcard>> createFlashcard(Flashcard flashcard) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AppError.auth(message: 'User not authenticated'));
      }

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
      if (_userId.isEmpty) {
        return const Left(AppError.auth(message: 'User not authenticated'));
      }

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
      final flashcards = models.map((model) => model.toEntity()).toList();
      return Right(flashcards);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Flashcard?>> getFlashcard(String id) async {
    try {
      final model = await localDataSource.getFlashcard(id);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, void>> syncFlashcardsToRemote(List<Flashcard> flashcards) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AppError.auth(message: 'User not authenticated'));
      }

      final models = flashcards.map((flashcard) => FlashcardModel.fromEntity(flashcard)).toList();
      
      for (final model in models) {
        await remoteDataSource.upsertFlashcard(model);
        
        // Update local sync status
        final syncedFlashcard = model.copyWith(syncStatus: SyncStatus.synced);
        await localDataSource.upsertFlashcard(syncedFlashcard);
      }

      return const Right(null);
    } catch (e) {
      return Left(AppError.sync(message: 'Failed to sync flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Flashcard>>> getPendingSyncFlashcards() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AppError.auth(message: 'User not authenticated'));
      }

      final models = await localDataSource.getPendingSyncFlashcards(_userId);
      final flashcards = models.map((model) => model.toEntity()).toList();
      return Right(flashcards);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get pending flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, void>> markFlashcardsAsSynced(List<String> flashcardIds) async {
    try {
      for (final id in flashcardIds) {
        await localDataSource.updateFlashcardSyncStatus(id, SyncStatus.synced);
      }
      return const Right(null);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to mark flashcards as synced: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Flashcard>>> createFlashcardsBatch(List<Flashcard> flashcards) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AppError.auth(message: 'User not authenticated'));
      }

      final now = DateTime.now();
      final List<Flashcard> createdFlashcards = [];
      final List<SyncOperation> operations = [];

      for (final flashcard in flashcards) {
        final newFlashcard = flashcard.copyWith(
          id: _uuid.v4(),
          userId: _userId,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pending,
        );

        await localDataSource.upsertFlashcard(FlashcardModel.fromEntity(newFlashcard));
        createdFlashcards.add(newFlashcard);

        operations.add(SyncOperation.create(
          entityId: newFlashcard.id,
          entityType: 'flashcard',
          payload: FlashcardModel.fromEntity(newFlashcard).toJson(),
        ));
      }

      // Enqueue all sync operations
      for (final operation in operations) {
        await syncQueue.enqueue(operation);
      }

      return Right(createdFlashcards);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to create flashcards batch: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteFlashcardsByLesson(String lessonId) async {
    try {
      await localDataSource.deleteFlashcardsByLesson(lessonId);
      return const Right(null);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to delete flashcards by lesson: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Flashcard>>> getDueFlashcards(String userId) async {
    try {
      final models = await localDataSource.getDueFlashcards(userId);
      final flashcards = models.map((model) => model.toEntity()).toList();
      return Right(flashcards);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get due flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Flashcard>>> getRecentFlashcards(String userId, {int limit = 20}) async {
    try {
      final models = await localDataSource.getRecentFlashcards(userId, limit: limit);
      final flashcards = models.map((model) => model.toEntity()).toList();
      return Right(flashcards);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get recent flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, void>> updateFlashcardProgress(
    String flashcardId, {
    required bool wasCorrect,
    required DateTime reviewedAt,
  }) async {
    try {
      final flashcardResult = await getFlashcard(flashcardId);
      
      return flashcardResult.fold(
        (error) => Left(error),
        (flashcard) async {
          if (flashcard == null) {
            return const Left(AppError.notFound(message: 'Flashcard not found'));
          }

          final updatedFlashcard = flashcard.copyWith(
            lastReviewedAt: reviewedAt,
            reviewCount: flashcard.reviewCount + 1,
            correctCount: wasCorrect ? flashcard.correctCount + 1 : flashcard.correctCount,
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pending,
          );

          return await updateFlashcard(updatedFlashcard).then((result) => 
            result.fold((error) => Left(error), (_) => const Right(null))
          );
        },
      );
    } catch (e) {
      return Left(AppError.database(message: 'Failed to update flashcard progress: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, int>> getFlashcardCountByLesson(String lessonId) async {
    try {
      final count = await localDataSource.countFlashcardsByLesson(lessonId);
      return Right(count);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get flashcard count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Map<String, int>>> getFlashcardStatsByUser(String userId) async {
    try {
      final stats = await localDataSource.getFlashcardStatsByUser(userId);
      return Right(stats);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get flashcard stats: ${e.toString()}'));
    }
  }
}

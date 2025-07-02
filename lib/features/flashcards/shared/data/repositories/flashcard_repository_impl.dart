// lib/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '/../../../core/error/failures.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/flashcard_local_data_source.dart';
import '../datasources/flashcard_remote_data_source.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardLocalDataSource localDataSource;
  final FlashcardRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;
  final firebase_auth.FirebaseAuth firebaseAuth;

  FlashcardRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, Flashcard>> createFlashcard(Flashcard flashcard) async {
    try {
      // Always save locally first (local-first approach)
      final flashcardModel = FlashcardModel.fromEntity(flashcard);
      final createdModel = await localDataSource.createFlashcard(flashcardModel);
      
      // Return immediately for offline use
      // Sync will happen when lesson is locked or connection is restored
      return Right(createdModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to create flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Flashcard>> updateFlashcard(Flashcard flashcard) async {
    try {
      final flashcardModel = FlashcardModel.fromEntity(flashcard);
      final updatedModel = await localDataSource.updateFlashcard(flashcardModel);
      
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to update flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFlashcard(String id) async {
    try {
      await localDataSource.deleteFlashcard(id);
      
      // If online, also delete from remote
      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.deleteFlashcard(id);
        } catch (e) {
          // Continue even if remote delete fails
          // Will be handled during next sync
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Flashcard?>> getFlashcard(String id) async {
    try {
      final flashcardModel = await localDataSource.getFlashcard(id);
      return Right(flashcardModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLesson(String lessonId) async {
    try {
      final flashcardModels = await localDataSource.getFlashcardsByLesson(lessonId);
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to get flashcards by lesson: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLessonAndTag(
    String lessonId,
    String tagId,
  ) async {
    try {
      final flashcardModels = await localDataSource.getFlashcardsByLessonAndTag(lessonId, tagId);
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to get flashcards by lesson and tag: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFavoriteFlashcards(String userId) async {
    try {
      final flashcardModels = await localDataSource.getFavoriteFlashcards(userId);
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to get favorite flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsNeedingAttention(String userId) async {
    try {
      final flashcardModels = await localDataSource.getFlashcardsNeedingAttention(userId);
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to get flashcards needing attention: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> countFlashcardsByLesson(String lessonId) async {
    try {
      final count = await localDataSource.countFlashcardsByLesson(lessonId);
      return Right(count);
    } catch (e) {
      return Left(CacheFailure('Failed to count flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> searchFlashcards(
    String userId,
    String query,
  ) async {
    try {
      final flashcardModels = await localDataSource.searchFlashcards(userId, query);
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to search flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncFlashcardsToRemote(List<String> flashcardIds) async {
    try {
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Get flashcards to sync
      final flashcardModels = <FlashcardModel>[];
      for (final id in flashcardIds) {
        final model = await localDataSource.getFlashcard(id);
        if (model != null) {
          flashcardModels.add(model);
        }
      }

      if (flashcardModels.isEmpty) {
        return const Right(null);
      }

      // Sync to remote
      await remoteDataSource.syncFlashcards(flashcardModels);

      // Update local sync status
      for (final model in flashcardModels) {
        final syncedModel = model.copyWith(syncStatus: 'synced');
        await localDataSource.updateFlashcard(syncedModel);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to sync flashcards to remote: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncFlashcardsFromRemote(String lessonId) async {
    try {
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final remoteFlashcards = await remoteDataSource.getFlashcardsByLesson(lessonId);
      
      for (final remoteModel in remoteFlashcards) {
        final localModel = await localDataSource.getFlashcard(remoteModel.id);
        
        if (localModel == null) {
          // New flashcard from remote
          await localDataSource.createFlashcard(remoteModel);
        } else if (localModel.syncStatus == 'synced') {
          // Safe to update from remote
          await localDataSource.updateFlashcard(remoteModel);
        }
        // If local has pending changes, skip to avoid conflicts
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to sync flashcards from remote: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getPendingSyncFlashcards() async {
    try {
      final flashcardModels = await localDataSource.getPendingSyncFlashcards();
      final flashcards = flashcardModels.map((model) => model.toEntity()).toList();
      
      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to get pending sync flashcards: ${e.toString()}'));
    }
  }

  String? _getCurrentUserId() {
    return firebaseAuth.currentUser?.uid;
  }
}
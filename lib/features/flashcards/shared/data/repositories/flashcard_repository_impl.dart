// lib/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/error/failures.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/flashcard_local_data_source.dart';
import '../datasources/flashcard_remote_data_source.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardLocalDataSource localDataSource;
  final FlashcardRemoteDataSource remoteDataSource;
  final ContentRepository contentRepository;
  final InternetConnectionChecker connectionChecker;
  final firebase_auth.FirebaseAuth firebaseAuth;

  FlashcardRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.contentRepository,
    required this.connectionChecker,
    required this.firebaseAuth,
  });

  @override
  Future<Either<Failure, Flashcard>> createFlashcard(
      Flashcard flashcard) async {
    try {
      await localDataSource.initDatabase();

      final flashcardModel = FlashcardModel.fromEntity(flashcard);
      final createdModel =
          await localDataSource.createFlashcard(flashcardModel);

      // Upload to remote if online
      if (await connectionChecker.hasConnection) {
        try {
          final remoteModel = await remoteDataSource.createFlashcard(createdModel);
          await localDataSource.updateFlashcard(remoteModel.copyWith(syncStatus: 'synced'));
        } catch (e) {
          // If remote fails, it remains 'pending' locally, no re-throw needed
        }
      }

      await contentRepository.updateLessonContentCount(flashcard.lessonId);

      return Right(createdModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to create flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFlashcard(String id) async {
    try {
      await localDataSource.initDatabase();
      final flashcard = await localDataSource.getFlashcard(id);
      if (flashcard == null) {
        return const Left(CacheFailure('Flashcard not found'));
      }

      await localDataSource.deleteFlashcard(id);

      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.deleteFlashcard(id);
        } catch (e) {
          // Continue even if remote delete fails
        }
      }

      await contentRepository.updateLessonContentCount(flashcard.lessonId);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete flashcard: ${e.toString()}'));
    }
  }

  // ... other methods remain the same
  @override
  Future<Either<Failure, Flashcard>> updateFlashcard(
      Flashcard flashcard) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModel = FlashcardModel.fromEntity(flashcard);
      final updatedModel =
          await localDataSource.updateFlashcard(flashcardModel);

      if (await connectionChecker.hasConnection) {
        try {
          final remoteModel = await remoteDataSource.updateFlashcard(updatedModel);
          await localDataSource.updateFlashcard(remoteModel.copyWith(syncStatus: 'synced'));
        } catch (e) {
          // If remote fails, it remains 'pending' locally
        }
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to update flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Flashcard?>> getFlashcard(String id) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModel = await localDataSource.getFlashcard(id);
      return Right(flashcardModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get flashcard: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLesson(
      String lessonId) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.getFlashcardsByLesson(lessonId);
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(
          CacheFailure('Failed to get flashcards by lesson: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsByLessonAndTag(
    String lessonId,
    String tagId,
  ) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.getFlashcardsByLessonAndTag(lessonId, tagId);
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure(
          'Failed to get flashcards by lesson and tag: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFavoriteFlashcards(
      String userId) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.getFavoriteFlashcards(userId);
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(
          CacheFailure('Failed to get favorite flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getFlashcardsNeedingAttention(
      String userId) async {
    try {
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.getFlashcardsNeedingAttention(userId);
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure(
          'Failed to get flashcards needing attention: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> countFlashcardsByLesson(String lessonId) async {
    try {
      await localDataSource.initDatabase();
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
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.searchFlashcards(userId, query);
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure('Failed to search flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncFlashcardsToRemote(
      List<String> flashcardIds) async {
    try {
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('No internet connection'));
      }

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

      await remoteDataSource.syncFlashcards(flashcardModels);

      for (final model in flashcardModels) {
        final syncedModel = model.copyWith(syncStatus: 'synced');
        await localDataSource.updateFlashcard(syncedModel);
      }

      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Failed to sync flashcards to remote: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncFlashcardsFromRemote(
      String lessonId) async {
    try {
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final remoteFlashcards =
          await remoteDataSource.getFlashcardsByLesson(lessonId);

      for (final remoteModel in remoteFlashcards) {
        final localModel = await localDataSource.getFlashcard(remoteModel.id);

        if (localModel == null) {
          await localDataSource.createFlashcard(remoteModel);
        } else if (localModel.syncStatus == 'synced') {
          await localDataSource.updateFlashcard(remoteModel);
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          'Failed to sync flashcards from remote: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getPendingSyncFlashcards() async {
    try {
      await localDataSource.initDatabase();
      final flashcardModels =
          await localDataSource.getPendingSyncFlashcards();
      final flashcards =
          flashcardModels.map((model) => model.toEntity()).toList();

      return Right(flashcards);
    } catch (e) {
      return Left(CacheFailure(
          'Failed to get pending sync flashcards: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String flashcardId) async {
    try {
      final flashcard = await getFlashcard(flashcardId);
      return flashcard.fold(
        (l) => Left(l),
        (r) async {
          if (r == null) {
            return const Left(CacheFailure('Flashcard not found'));
          }
          final updatedFlashcard = r.copyWith(isFavorite: !r.isFavorite);
          await updateFlashcard(updatedFlashcard);
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to toggle favorite: ${e.toString()}'));
    }
  }
}
// lib/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/flashcard_local_data_source.dart';
import '../datasources/flashcard_remote_data_source.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl extends BaseRepository implements FlashcardRepository {
  final FlashcardLocalDataSource localDataSource;
  final FlashcardRemoteDataSource remoteDataSource;
  final IUnitOfWork unitOfWork;
  final InternetConnectionChecker connectionChecker;
  final firebase_auth.FirebaseAuth firebaseAuth;

  FlashcardRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.unitOfWork,
    required this.connectionChecker,
    required this.firebaseAuth,
  });

  @override
  Future<Either<AppFailure, Flashcard>> createFlashcard(Flashcard flashcard) async {
    return guard(() async {
      await unitOfWork.transaction(() async {
        final flashcardModel = FlashcardModel.fromEntity(flashcard);
        await unitOfWork.flashcard.createFlashcard(flashcardModel);

        final count = await unitOfWork.flashcard.countFlashcardsByLesson(flashcard.lessonId);
        final lesson = await unitOfWork.content.getLesson(flashcard.lessonId);
        if (lesson != null) {
          await unitOfWork.content.insertOrUpdateLesson(lesson.copyWith(flashcardCount: count));
        }
      });
      
      final createdFlashcard = await localDataSource.getFlashcard(flashcard.id);

      if (await connectionChecker.hasConnection) {
        try {
          final remoteModel = await remoteDataSource.createFlashcard(createdFlashcard!);
          await localDataSource.updateFlashcard(remoteModel.copyWith(syncStatus: 'synced'));
        } catch (e) {
          // Non-critical, will sync later
        }
      }
      return createdFlashcard!.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteFlashcard(String id) async {
    return guard(() async {
      final flashcard = await localDataSource.getFlashcard(id);
      if (flashcard == null) throw AppFailure(type: FailureType.cache, message: 'Flashcard not found');

      await unitOfWork.transaction(() async {
        await unitOfWork.flashcard.deleteFlashcard(id);
        final count = await unitOfWork.flashcard.countFlashcardsByLesson(flashcard.lessonId);
        final lesson = await unitOfWork.content.getLesson(flashcard.lessonId);
        if (lesson != null) {
          await unitOfWork.content.insertOrUpdateLesson(lesson.copyWith(flashcardCount: count));
        }
      });

      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.deleteFlashcard(id);
        } catch (e) {
          // Non-critical
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, Flashcard>> updateFlashcard(Flashcard flashcard) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModel = FlashcardModel.fromEntity(flashcard);
      final updatedModel = await localDataSource.updateFlashcard(flashcardModel);

      if (await connectionChecker.hasConnection) {
        try {
          final remoteModel = await remoteDataSource.updateFlashcard(updatedModel);
          await localDataSource.updateFlashcard(remoteModel.copyWith(syncStatus: 'synced'));
        } catch (e) {
          // Non-critical
        }
      }
      return updatedModel.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, Flashcard?>> getFlashcard(String id) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModel = await localDataSource.getFlashcard(id);
      return flashcardModel?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsByLesson(String lessonId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.getFlashcardsByLesson(lessonId);
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsByLessonAndTag(String lessonId, String tagId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.getFlashcardsByLessonAndTag(lessonId, tagId);
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> getFavoriteFlashcards(String userId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.getFavoriteFlashcards(userId);
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> getFlashcardsNeedingAttention(String userId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.getFlashcardsNeedingAttention(userId);
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, int>> countFlashcardsByLesson(String lessonId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      return await localDataSource.countFlashcardsByLesson(lessonId);
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> searchFlashcards(String userId, String query) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.searchFlashcards(userId, query);
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, void>> syncFlashcardsToRemote(List<String> flashcardIds) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) throw AppFailure(type: FailureType.network, message: 'No internet connection');

      final flashcardModels = <FlashcardModel>[];
      for (final id in flashcardIds) {
        final model = await localDataSource.getFlashcard(id);
        if (model != null) flashcardModels.add(model);
      }
      if (flashcardModels.isEmpty) return;

      await remoteDataSource.syncFlashcards(flashcardModels);
      for (final model in flashcardModels) {
        await localDataSource.updateFlashcard(model.copyWith(syncStatus: 'synced'));
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> syncFlashcardsFromRemote(String lessonId) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) throw AppFailure(type: FailureType.network, message: 'No internet connection');

      final remoteFlashcards = await remoteDataSource.getFlashcardsByLesson(lessonId);
      for (final remoteModel in remoteFlashcards) {
        final localModel = await localDataSource.getFlashcard(remoteModel.id);
        if (localModel == null || localModel.syncStatus == 'synced') {
          await localDataSource.updateFlashcard(remoteModel);
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, List<Flashcard>>> getPendingSyncFlashcards() async {
    return guard(() async {
      await localDataSource.initDatabase();
      final flashcardModels = await localDataSource.getPendingSyncFlashcards();
      return flashcardModels.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, void>> toggleFavorite(String flashcardId) async {
    return guard(() async {
      final flashcardEither = await getFlashcard(flashcardId);
      final flashcard = flashcardEither.getOrElse(() => null);
      if (flashcard == null) throw AppFailure(type: FailureType.cache, message: 'Flashcard not found');
      
      final updatedFlashcard = flashcard.copyWith(isFavorite: !flashcard.isFavorite);
      await updateFlashcard(updatedFlashcard);
    });
  }
}

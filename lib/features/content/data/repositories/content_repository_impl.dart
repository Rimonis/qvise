// lib/features/content/data/repositories/content_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/events/event_bus.dart';
import '../../../../core/events/domain_event.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/create_lesson_params.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_local_data_source.dart';
import '../datasources/content_remote_data_source.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/lesson_model.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentLocalDataSource localDataSource;
  final ContentRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;
  final FirebaseAuth firebaseAuth;
  final EventBus eventBus;
  final Uuid _uuid;

  ContentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
    required this.firebaseAuth,
    required this.eventBus,
  }) : _uuid = const Uuid();

  String get _userId => firebaseAuth.currentUser?.uid ?? '';

  @override
  Future<Either<AppError, void>> deleteLesson(String lessonId) async {
    try {
      // Get lesson details before deletion for event
      final lessonResult = await getLesson(lessonId);
      if (lessonResult.isLeft()) {
        return Left(lessonResult.fold((l) => l, (r) => throw Exception()));
      }
      
      final lesson = lessonResult.fold((l) => throw Exception(), (r) => r);
      if (lesson == null) {
        return const Left(AppError.database(message: 'Lesson not found'));
      }

      // Delete from local database
      await localDataSource.deleteLesson(lessonId);

      // Delete from remote if online
      if (await connectionChecker.hasConnection) {
        await remoteDataSource.deleteLesson(lessonId);
      }

      // Publish domain event
      eventBus.publish(LessonDeletedEvent(
        lessonId: lessonId,
        userId: _userId,
        subjectName: lesson.subjectName,
        topicName: lesson.topicName,
      ));

      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTopic(String subjectName, String topicName) async {
    try {
      await localDataSource.deleteTopic(subjectName, topicName);

      if (await connectionChecker.hasConnection) {
        await remoteDataSource.deleteTopic(subjectName, topicName);
      }

      // Publish domain event
      eventBus.publish(TopicDeletedEvent(
        userId: _userId,
        subjectName: subjectName,
        topicName: topicName,
      ));

      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubject(String subjectName) async {
    try {
      await localDataSource.deleteSubject(subjectName);

      if (await connectionChecker.hasConnection) {
        await remoteDataSource.deleteSubject(subjectName);
      }

      // Publish domain event
      eventBus.publish(SubjectDeletedEvent(
        userId: _userId,
        subjectName: subjectName,
      ));

      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, List<Subject>>> getSubjects() async {
    try {
      final localSubjects = await localDataSource.getSubjects();
      final subjects = localSubjects.map((model) => model.toEntity()).toList();

      // Try to sync with remote if online
      if (await connectionChecker.hasConnection) {
        _syncSubjectsInBackground();
      }

      return Right(subjects);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, Subject?>> getSubject(String subjectName) async {
    try {
      final model = await localDataSource.getSubject(subjectName);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, List<Topic>>> getTopicsBySubject(String subjectName) async {
    try {
      final localTopics = await localDataSource.getTopicsBySubject(subjectName);
      final topics = localTopics.map((model) => model.toEntity()).toList();
      return Right(topics);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, Topic?>> getTopic(String subjectName, String topicName) async {
    try {
      final model = await localDataSource.getTopic(subjectName, topicName);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByTopic(String subjectName, String topicName) async {
    try {
      final localLessons = await localDataSource.getLessonsByTopic(subjectName, topicName);
      final lessons = localLessons.map((model) => model.toEntity()).toList();
      return Right(lessons);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getAllLessons() async {
    try {
      final localLessons = await localDataSource.getAllLessons();
      final lessons = localLessons.map((model) => model.toEntity()).toList();
      return Right(lessons);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getDueLessons() async {
    try {
      final localLessons = await localDataSource.getDueLessons();
      final lessons = localLessons.map((model) => model.toEntity()).toList();
      return Right(lessons);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, Lesson?>> getLesson(String lessonId) async {
    try {
      final model = await localDataSource.getLesson(lessonId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, Lesson>> createLesson(CreateLessonParams params) async {
    try {
      final now = DateTime.now();
      final lessonId = _uuid.v4();

      final lesson = Lesson(
        id: lessonId,
        userId: _userId,
        subjectName: params.subjectName,
        topicName: params.topicName,
        title: params.lessonTitle,
        createdAt: now,
        updatedAt: now,
        nextReviewDate: now.add(const Duration(days: 1)), // Initial review in 1 day
        reviewStage: 0,
        proficiency: 0.0,
      );

      final model = LessonModel.fromEntity(lesson);
      await localDataSource.insertLesson(model);

      // Sync to remote if online
      if (await connectionChecker.hasConnection) {
        await remoteDataSource.insertLesson(model);
      }

      // Publish domain event
      eventBus.publish(LessonCreatedEvent(
        lessonId: lessonId,
        userId: _userId,
        subjectName: params.subjectName,
        topicName: params.topicName,
        title: params.lessonTitle,
      ));

      return Right(lesson);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson) async {
    try {
      final updatedLesson = lesson.copyWith(updatedAt: DateTime.now());
      final model = LessonModel.fromEntity(updatedLesson);
      
      await localDataSource.updateLesson(model);

      if (await connectionChecker.hasConnection) {
        await remoteDataSource.updateLesson(model);
      }

      // Publish domain event
      eventBus.publish(LessonUpdatedEvent(
        lessonId: lesson.id,
        userId: _userId,
        changes: {}, // You might want to track specific changes
      ));

      return Right(updatedLesson);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> syncLessons() async {
    try {
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure());
      }

      eventBus.publish(const SyncStartedEvent(
        userId: _userId,
        syncType: 'manual',
      ));

      final stopwatch = Stopwatch()..start();

      // Implement full sync logic here
      // This is a simplified version
      final remoteLessons = await remoteDataSource.getAllLessons();
      int syncedCount = 0;

      for (final remoteLesson in remoteLessons) {
        await localDataSource.insertOrUpdateLesson(remoteLesson);
        syncedCount++;
      }

      stopwatch.stop();

      eventBus.publish(SyncCompletedEvent(
        userId: _userId,
        syncType: 'manual',
        itemsSynced: syncedCount,
        duration: stopwatch.elapsed,
        success: true,
      ));

      return const Right(null);
    } catch (e) {
      eventBus.publish(SyncCompletedEvent(
        userId: _userId,
        syncType: 'manual',
        itemsSynced: 0,
        duration: Duration.zero,
        success: false,
        errorMessage: e.toString(),
      ));
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUnsyncedLessons() async {
    try {
      final hasUnsynced = await localDataSource.hasUnsyncedLessons();
      return Right(hasUnsynced);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> recalculateProficiencies() async {
    try {
      // Implement proficiency recalculation logic
      // This would typically involve analyzing flashcard performance
      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> lockLesson(String lessonId) async {
    try {
      final lessonResult = await getLesson(lessonId);
      if (lessonResult.isLeft()) {
        return Left(lessonResult.fold((l) => l, (r) => throw Exception()));
      }
      
      final lesson = lessonResult.fold((l) => throw Exception(), (r) => r);
      if (lesson == null) {
        return const Left(ContentNotFoundFailure(message: 'Lesson not found'));
      }

      final lockedLesson = lesson.lock();
      await updateLesson(lockedLesson);

      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  @override
  Future<Either<Failure, void>> updateLessonContentCount(String lessonId) async {
    try {
      // Implementation would query flashcard/file counts and update lesson
      return const Right(null);
    } catch (e) {
      return Left(FailureFactory.fromException(e as Exception));
    }
  }

  // Private helper methods
  Future<void> _syncSubjectsInBackground() async {
    try {
      final remoteSubjects = await remoteDataSource.getSubjects();
      for (final subject in remoteSubjects) {
        await localDataSource.insertOrUpdateSubject(subject);
      }
    } catch (e) {
      // Log error but don't throw - this is background sync
    }
  }
}

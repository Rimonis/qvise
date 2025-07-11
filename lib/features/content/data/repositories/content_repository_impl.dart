// lib/features/content/data/repositories/content_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/events/event_bus.dart';
import 'package:qvise/core/events/domain_event.dart';
import 'package:uuid/uuid.dart';
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

  String get _userId => firebaseAuth.currentUser?.uid?? '';

  @override
  Future<Either<AppError, void>> deleteLesson(String lessonId) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      
      await localDataSource.deleteLesson(_userId, lessonId);
      
      // Fire an event to let the flashcard feature handle its own cleanup
      eventBus.fire(LessonDeletedEvent(lessonId));

      if (await connectionChecker.hasConnection) {
        await remoteDataSource.deleteLesson(lessonId);
      }
      return const Right(null);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to delete lesson: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteTopic(String subjectName, String topicName) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));

      // Fire an event to let the flashcard feature handle cleanup before deleting the topic
      eventBus.fire(TopicDeletedEvent(
        userId: _userId,
        subjectName: subjectName,
        topicName: topicName,
      ));

      await localDataSource.deleteTopic(_userId, subjectName, topicName);
      
      if (await connectionChecker.hasConnection) {
        // This remote call should also be handled by a server-side function for atomicity
        await remoteDataSource.deleteLessonsByTopic(_userId, subjectName, topicName);
      }
      return const Right(null);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to delete topic: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, Lesson>> createLesson(CreateLessonParams params) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));

      final now = DateTime.now();
      final lesson = Lesson(
        id: _uuid.v4(),
        userId: _userId,
        subjectName: params.subjectName,
        topicName: params.topicName,
        title: params.lessonTitle,
        createdAt: now,
        updatedAt: now,
        nextReviewDate: now,
        reviewStage: 0,
        proficiency: 0.0,
        isLocked: false,
      );

      final lessonModel = LessonModel.fromEntity(lesson);
      await localDataSource.insertOrUpdateLesson(lessonModel);

      if (await connectionChecker.hasConnection) {
        await remoteDataSource.createLesson(lessonModel);
      }

      return Right(lesson);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to create lesson: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Subject>>> getSubjects() async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      final subjectModels = await localDataSource.getSubjects(_userId);
      return Right(subjectModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get subjects: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Topic>>> getTopicsBySubject(String subjectName) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      final topicModels = await localDataSource.getTopicsBySubject(_userId, subjectName);
      return Right(topicModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get topics: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<AppError, List<Lesson>>> getLessonsByTopic(String subjectName, String topicName) async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      final lessonModels = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
      return Right(lessonModels.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get lessons: ${e.toString()}'));
    }
  }

  @override
  Future<Either<AppError, List<Lesson>>> getDueLessons() async {
    try {
      if (_userId.isEmpty) return const Left(AppError.auth(message: 'User not authenticated'));
      final lessons = await localDataSource.getAllLessons(_userId);
      final now = DateTime.now();
      final dueLessons = lessons
       .where((lesson) => lesson.isLocked && (lesson.nextReviewDate.isBefore(now) |

| lesson.nextReviewDate.isAtSameMomentAs(now)))
       .map((m) => m.toEntity())
       .toList();
      return Right(dueLessons);
    } catch (e) {
      return Left(AppError.database(message: 'Failed to get due lessons: ${e.toString()}'));
    }
  }
}

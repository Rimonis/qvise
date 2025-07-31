// lib/features/content/data/repositories/content_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:uuid/uuid.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/error/app_failure.dart';
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

class ContentRepositoryImpl extends BaseRepository implements ContentRepository {
  final ContentLocalDataSource localDataSource;
  final ContentRemoteDataSource remoteDataSource;
  final IUnitOfWork unitOfWork;
  final InternetConnectionChecker connectionChecker;
  final FirebaseAuth firebaseAuth;
  final _uuid = const Uuid();

  ContentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.unitOfWork,
    required this.connectionChecker,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';

  @override
  Future<Either<AppFailure, List<Subject>>> getSubjects() async {
    return guard(() async {
      await localDataSource.initDatabase();
      final subjects = await localDataSource.getSubjects(_userId);
      return subjects.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Subject?>> getSubject(String subjectName) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final subject = await localDataSource.getSubject(_userId, subjectName);
      return subject?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Topic>>> getTopicsBySubject(
      String subjectName) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final topics =
          await localDataSource.getTopicsBySubject(_userId, subjectName);
      return topics.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Topic?>> getTopic(String subjectName, String topicName) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final topic = await localDataSource.getTopic(_userId, subjectName, topicName);
      return topic?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final lessons = await localDataSource.getLessonsByTopic(
          _userId, subjectName, topicName);
      return lessons.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Lesson?>> getLesson(String lessonId) async {
    return guard(() async {
      await localDataSource.initDatabase();
      final lesson = await localDataSource.getLesson(lessonId);
      return lesson?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getAllLessons() async {
    return guard(() async {
      await localDataSource.initDatabase();
      final lessons = await localDataSource.getAllLessons(_userId);
      return lessons.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getDueLessons() async {
    return guard(() async {
      await localDataSource.initDatabase();
      final lessons = await localDataSource.getAllLessons(_userId);
      final now = DateTime.now();
      final dueLessons = lessons.where((lesson) => 
        lesson.nextReviewDate.isBefore(now) || lesson.nextReviewDate.isAtSameMomentAs(now)
      ).toList();
      return dueLessons.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Lesson>> createLesson(
      CreateLessonParams params) async {
    return guard(() async {
      await localDataSource.initDatabase();
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network,
            message: 'Network connection required to create lessons');
      }

      final now = DateTime.now();
      final lessonModel = LessonModel(
        id: _uuid.v4(),
        userId: _userId,
        subjectName: params.subjectName,
        topicName: params.topicName,
        title: params.lessonTitle,
        createdAt: now,
        updatedAt: now,
        nextReviewDate: now.add(const Duration(days: 1)),
        reviewStage: 0,
        proficiency: 0.0,
        isSynced: false,
      );

      final syncedLesson = await remoteDataSource.createLesson(lessonModel);
      await localDataSource.insertOrUpdateLesson(syncedLesson);
      await _updateContentHierarchy(params.subjectName, params.topicName, now);

      return syncedLesson.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteLesson(String lessonId) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'Network connection required');
      }

      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson == null) {
        throw const AppFailure(type: FailureType.cache, message: 'Lesson not found');
      }

      await unitOfWork.transaction(() async {
        // Delete files first (includes remote cleanup)
        await unitOfWork.file.deleteFilesByLesson(lessonId);
        await unitOfWork.flashcard.deleteFlashcardsByLesson(lessonId);
        await unitOfWork.content.deleteLesson(lessonId);
      });

      try {
        await remoteDataSource.deleteLesson(lessonId);
      } catch (e) {
        debugPrint('Non-critical failure: Could not delete remote lesson $lessonId: $e');
      }

      await _cleanupEmptyTopicAndSubject(lesson.subjectName, lesson.topicName);
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteTopic(
      String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'Network connection required');
      }

      await unitOfWork.transaction(() async {
        final lessons = await unitOfWork.content
            .getLessonsByTopic(_userId, subjectName, topicName);
        
        // Delete files for all lessons in this topic
        for (final lesson in lessons) {
          await unitOfWork.file.deleteFilesByLesson(lesson.id);
          await unitOfWork.flashcard.deleteFlashcardsByLesson(lesson.id);
          await unitOfWork.content.deleteLesson(lesson.id);
        }
        await unitOfWork.content.deleteTopic(_userId, subjectName, topicName);
      });

      try {
        await remoteDataSource.deleteLessonsByTopic(_userId, subjectName, topicName);
      } catch (e) {
        debugPrint(
            'Non-critical failure: Could not delete remote lessons for topic $topicName: $e');
      }

      await _cleanupEmptySubject(subjectName);
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteSubject(String subjectName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'Network connection required');
      }

      await unitOfWork.transaction(() async {
        final topics =
            await unitOfWork.content.getTopicsBySubject(_userId, subjectName);
        for (final topic in topics) {
          final lessons = await unitOfWork.content
              .getLessonsByTopic(_userId, subjectName, topic.name);
          
          // Delete files for all lessons in this subject
          for (final lesson in lessons) {
            await unitOfWork.file.deleteFilesByLesson(lesson.id);
            await unitOfWork.flashcard.deleteFlashcardsByLesson(lesson.id);
            await unitOfWork.content.deleteLesson(lesson.id);
          }
          await unitOfWork.content.deleteTopic(_userId, subjectName, topic.name);
        }
        await unitOfWork.content.deleteSubject(_userId, subjectName);
      });

      try {
        await remoteDataSource.deleteLessonsBySubject(_userId, subjectName);
      } catch (e) {
        debugPrint(
            'Non-critical failure: Could not delete remote lessons for subject $subjectName: $e');
      }
    });
  }

  @override
  Future<Either<AppFailure, Lesson>> updateLesson(Lesson lesson) async {
    return guard(() async {
      final localLesson = await localDataSource.getLesson(lesson.id);
      final newVersion = (localLesson?.version ?? 0) + 1;
      final updatedLesson = LessonModel.fromEntity(lesson).copyWith(
        version: newVersion,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await localDataSource.insertOrUpdateLesson(updatedLesson);

      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.updateLesson(updatedLesson);
          final syncedLesson = updatedLesson.copyWith(isSynced: true);
          await localDataSource.insertOrUpdateLesson(syncedLesson);
        } catch (e) {
          debugPrint('Non-critical failure: Could not sync lesson update: $e');
        }
      }

      return updatedLesson.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, void>> syncLessons() async {
    return guard(() async {
      await localDataSource.initDatabase();
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'Network connection required');
      }

      final unsyncedLessons =
          await localDataSource.getUnsyncedLessons(_userId);
      for (final lesson in unsyncedLessons) {
        await remoteDataSource.updateLesson(lesson);
        await localDataSource.markLessonAsSynced(lesson.id);
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> lockLesson(String lessonId) async {
    return guard(() async {
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'Network connection required');
      }
      
      await remoteDataSource.lockLesson(lessonId);
      
      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson != null) {
        final lockedLesson = lesson.copyWith(
          isLocked: true,
          lockedAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now(),
        );
        await localDataSource.insertOrUpdateLesson(lockedLesson);
      }
    });
  }

  @override
  Future<Either<AppFailure, bool>> hasUnsyncedLessons() async {
    return guard(() async {
      final unsyncedLessons = await localDataSource.getUnsyncedLessons(_userId);
      return unsyncedLessons.isNotEmpty;
    });
  }

  @override
  Future<Either<AppFailure, void>> recalculateProficiencies() async {
    return guard(() async {
      // Implementation would calculate proficiencies based on lesson performance
      // This is a placeholder for now
    });
  }

  Future<void> _updateContentHierarchy(
      String subjectName, String topicName, DateTime now) async {
    final subject = await localDataSource.getSubject(_userId, subjectName);
    final topic = await localDataSource.getTopic(_userId, subjectName, topicName);

    final updatedSubject = subject?.copyWith(
          lastStudied: now,
        ) ??
        SubjectModel(
          name: subjectName,
          userId: _userId,
          proficiency: 0.0,
          lessonCount: 1,
          topicCount: topic == null ? 1 : 0,
          lastStudied: now,
          createdAt: now,
        );

    final updatedTopic = topic?.copyWith(
          lastStudied: now,
        ) ??
        TopicModel(
          name: topicName,
          subjectName: subjectName,
          userId: _userId,
          proficiency: 0.0,
          lessonCount: 1,
          lastStudied: now,
          createdAt: now,
        );

    await localDataSource.insertOrUpdateSubject(updatedSubject);
    await localDataSource.insertOrUpdateTopic(updatedTopic);
  }

  Future<void> _cleanupEmptyTopicAndSubject(
      String subjectName, String topicName) async {
    final remainingLessons =
        await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
    if (remainingLessons.isEmpty) {
      await localDataSource.deleteTopic(_userId, subjectName, topicName);
      await _cleanupEmptySubject(subjectName);
    }
  }

  Future<void> _cleanupEmptySubject(String subjectName) async {
    final remainingTopics =
        await localDataSource.getTopicsBySubject(_userId, subjectName);
    if (remainingTopics.isEmpty) {
      await localDataSource.deleteSubject(_userId, subjectName);
    }
  }
}
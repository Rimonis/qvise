// lib/features/content/data/repositories/content_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:qvise/core/data/repositories/base_repository.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/create_lesson_params.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_local_data_source.dart';
import '../datasources/content_remote_data_source.dart';
import '../models/lesson_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';

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
  Future<Either<AppFailure, Lesson>> updateLesson(Lesson lesson) async {
    return guard(() async {
      final localLesson = await localDataSource.getLesson(lesson.id);
      final newVersion = (localLesson?.version ?? 1) + 1;

      final lessonModel = LessonModel.fromEntity(lesson).copyWith(
        version: newVersion,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await localDataSource.insertOrUpdateLesson(lessonModel);

      // Attempt to sync immediately if online
      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.updateLesson(lessonModel);
          await localDataSource.markLessonAsSynced(lesson.id);
        } catch (e) {
          // Non-critical error, sync coordinator will handle it later
          debugPrint('Failed to immediately sync updated lesson: $e');
        }
      }

      await recalculateProficiencies();
      return lessonModel.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Subject>>> getSubjects() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final subjects = await localDataSource.getSubjects(_userId);
      return subjects.map((s) => s.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Subject?>> getSubject(String subjectName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final subject = await localDataSource.getSubject(_userId, subjectName);
      return subject?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Topic>>> getTopicsBySubject(
      String subjectName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final topics =
          await localDataSource.getTopicsBySubject(_userId, subjectName);
      return topics.map((t) => t.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Topic?>> getTopic(
      String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final topic =
          await localDataSource.getTopic(_userId, subjectName, topicName);
      return topic?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final lessons = await localDataSource.getLessonsByTopic(
          _userId, subjectName, topicName);
      return lessons.map((l) => l.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getAllLessons() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final lessons = await localDataSource.getAllLessons(_userId);
      return lessons.map((l) => l.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getDueLessons() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final lessons = await localDataSource.getAllLessons(_userId);
      final now = DateTime.now();
      return lessons
          .where((lesson) =>
              lesson.isLocked &&
              (lesson.nextReviewDate.isBefore(now) ||
                  lesson.nextReviewDate.isAtSameMomentAs(now)))
          .map((l) => l.toEntity())
          .toList();
    });
  }

  @override
  Future<Either<AppFailure, Lesson?>> getLesson(String lessonId) async {
    return guard(() async {
      final lesson = await localDataSource.getLesson(lessonId);
      return lesson?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, Lesson>> createLesson(
      CreateLessonParams params) async {
    return guard(() async {
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

      // Perform high-latency remote operation first
      final syncedLesson = await remoteDataSource.createLesson(lessonModel);

      // Prepare local data models
      final subject = await _prepareSubjectModel(params, now);
      final topic = await _prepareTopicModel(params, now);

      // Then perform fast, local transactional database operations
      await localDataSource.createLessonAndHierarchy(
        lesson: syncedLesson,
        subjectToUpdate: subject,
        topicToUpdate: topic,
      );

      await recalculateProficiencies();

      return syncedLesson.toEntity();
    });
  }

  Future<SubjectModel> _prepareSubjectModel(CreateLessonParams params, DateTime now) async {
    final subject = await localDataSource.getSubject(_userId, params.subjectName);
    if (params.isNewSubject || subject == null) {
      return SubjectModel(
        name: params.subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        topicCount: 1,
        lastStudied: now,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      return subject.copyWith(
        lessonCount: subject.lessonCount + 1,
        topicCount: params.isNewTopic ? subject.topicCount + 1 : subject.topicCount,
        lastStudied: now,
        updatedAt: now,
      );
    }
  }

  Future<TopicModel> _prepareTopicModel(CreateLessonParams params, DateTime now) async {
    final topic = await localDataSource.getTopic(_userId, params.subjectName, params.topicName);
    if (params.isNewTopic || topic == null) {
      return TopicModel(
        name: params.topicName,
        subjectName: params.subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        lastStudied: now,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      return topic.copyWith(
        lessonCount: topic.lessonCount + 1,
        lastStudied: now,
        updatedAt: now,
      );
    }
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
        throw const AppFailure(
            type: FailureType.cache, message: 'Lesson not found');
      }

      final filesToDelete = await unitOfWork.file.getFilesByLessonId(lessonId);

      try {
        await remoteDataSource.deleteLesson(lessonId, _userId);
      } catch (e) {
        debugPrint(
            'Non-critical failure: Could not delete remote lesson $lessonId: $e');
      }

      await localDataSource.deleteLesson(lessonId); // This will cascade locally

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e; // Rethrow to satisfy return type
          });
        }
      }
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

      final lessons = await localDataSource.getLessonsByTopic(
          _userId, subjectName, topicName);
      final lessonIds = lessons.map((l) => l.id).toList();
      final filesToDelete = await unitOfWork.file.getFilesByLessonIds(lessonIds);

      try {
        await remoteDataSource.deleteLessonsByTopic(
            _userId, subjectName, topicName);
      } catch (e) {
        debugPrint(
            'Non-critical failure: Could not delete remote topic $topicName: $e');
      }

      await localDataSource.deleteTopic(
          _userId, subjectName, topicName); // This will cascade locally

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e; // Rethrow to satisfy return type
          });
        }
      }
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

      final topics =
          await localDataSource.getTopicsBySubject(_userId, subjectName);
      final lessonIds = <String>[];
      for (var topic in topics) {
        final lessons = await localDataSource.getLessonsByTopic(
            _userId, subjectName, topic.name);
        lessonIds.addAll(lessons.map((l) => l.id));
      }
      final filesToDelete = await unitOfWork.file.getFilesByLessonIds(lessonIds);

      try {
        await remoteDataSource.deleteLessonsBySubject(_userId, subjectName);
      } catch (e) {
        debugPrint(
            'Non-critical failure: Could not delete remote subject $subjectName: $e');
      }

      await localDataSource.deleteSubject(
          _userId, subjectName); // This will cascade locally

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e; // Rethrow to satisfy return type
          });
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> syncLessons() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
            type: FailureType.network, message: 'No internet connection');
      }

      final unsyncedLessons = await localDataSource.getUnsyncedLessons(_userId);
      if (unsyncedLessons.isNotEmpty) {
        await remoteDataSource.syncLessons(unsyncedLessons);
        for (final lesson in unsyncedLessons) {
          await localDataSource.markLessonAsSynced(lesson.id);
        }
      }

      final remoteLessons = await remoteDataSource.getUserLessons(_userId);
      for (final lesson in remoteLessons) {
        await localDataSource.insertOrUpdateLesson(lesson);
      }
    });
  }

  @override
  Future<Either<AppFailure, bool>> hasUnsyncedLessons() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final unsyncedLessons = await localDataSource.getUnsyncedLessons(_userId);
      return unsyncedLessons.isNotEmpty;
    });
  }

  @override
  Future<Either<AppFailure, void>> recalculateProficiencies() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
            type: FailureType.auth, message: 'User not authenticated');
      }
      final subjects = await localDataSource.getSubjects(_userId);

      for (final subject in subjects) {
        final topics =
            await localDataSource.getTopicsBySubject(_userId, subject.name);
        double totalSubjectProficiency = 0;
        for (final topic in topics) {
          final lessons = await localDataSource.getLessonsByTopic(
              _userId, subject.name, topic.name);
          if (lessons.isNotEmpty) {
            final topicProficiency = lessons.fold<double>(
                    0, (sum, lesson) => sum + lesson.proficiency) /
                lessons.length;
            await localDataSource.updateTopicProficiency(
                _userId, subject.name, topic.name, topicProficiency);
            totalSubjectProficiency += topicProficiency;
          }
        }
        if (topics.isNotEmpty) {
          final subjectProficiency = totalSubjectProficiency / topics.length;
          await localDataSource.updateSubjectProficiency(
              _userId, subject.name, subjectProficiency);
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> lockLesson(String lessonId) async {
    return guard(() async {
      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson == null) {
        throw const AppFailure(
            type: FailureType.cache, message: 'Lesson not found');
      }
      final updatedLesson = lesson.copyWith(
          isLocked: true,
          lockedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: lesson.version + 1,
          isSynced: false);
      await localDataSource.insertOrUpdateLesson(updatedLesson);
      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.updateLesson(updatedLesson);
          await localDataSource.markLessonAsSynced(lessonId);
        } catch (e) {
          // Sync coordinator will handle
        }
      }
    });
  }
}
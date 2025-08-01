// lib/features/content/data/repositories/content_repository_impl.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  final firebase_auth.FirebaseAuth firebaseAuth;
  final Uuid _uuid = const Uuid();

  String get _userId => firebaseAuth.currentUser?.uid ?? '';

  ContentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.unitOfWork,
    required this.connectionChecker,
    required this.firebaseAuth,
  });

  @override
  Future<Either<AppFailure, Lesson>> createLesson(CreateLessonParams params) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
          type: FailureType.network,
          message: 'Network connection required to create lessons'
        );
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

      // FIXED: All local operations in single transaction
      await unitOfWork.transaction(() async {
        await _updateContentHierarchy(
          params.subjectName,
          params.topicName,
          now,
          isNewSubject: params.isNewSubject,
          isNewTopic: params.isNewTopic,
        );
        await unitOfWork.content.insertOrUpdateLesson(syncedLesson);
        await _recalculateProficienciesInTransaction();
      });

      return syncedLesson.toEntity();
    });
  }

  Future<void> _updateContentHierarchy(
    String subjectName,
    String topicName,
    DateTime now, {
    required bool isNewSubject,
    required bool isNewTopic,
  }) async {
    // Handle subject
    final existingSubject = await unitOfWork.content.getSubject(_userId, subjectName);
    if (isNewSubject || existingSubject == null) {
      final newSubject = SubjectModel(
        name: subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        topicCount: 1,
        lastStudied: now,
        createdAt: now,
        updatedAt: now,
      );
      await unitOfWork.content.insertOrUpdateSubject(newSubject);
    } else {
      final updatedSubject = existingSubject.copyWith(
        lessonCount: existingSubject.lessonCount + 1,
        topicCount: isNewTopic ? existingSubject.topicCount + 1 : existingSubject.topicCount,
        lastStudied: now,
        updatedAt: now,
      );
      await unitOfWork.content.insertOrUpdateSubject(updatedSubject);
    }

    // Handle topic
    final existingTopic = await unitOfWork.content.getTopic(_userId, subjectName, topicName);
    if (isNewTopic || existingTopic == null) {
      final newTopic = TopicModel(
        name: topicName,
        subjectName: subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        lastStudied: now,
        createdAt: now,
        updatedAt: now,
      );
      await unitOfWork.content.insertOrUpdateTopic(newTopic);
    } else {
      final updatedTopic = existingTopic.copyWith(
        lessonCount: existingTopic.lessonCount + 1,
        lastStudied: now,
        updatedAt: now,
      );
      await unitOfWork.content.insertOrUpdateTopic(updatedTopic);
    }
  }

  // FIXED: Version that works within transaction
  Future<void> _recalculateProficienciesInTransaction() async {
    final lessons = await unitOfWork.content.getAllLessons(_userId);
    final subjects = await unitOfWork.content.getSubjects(_userId);
    
    for (final subject in subjects) {
      final subjectLessons = lessons.where((l) => l.subjectName == subject.name).toList();
      if (subjectLessons.isNotEmpty) {
        final avgProficiency = subjectLessons
            .map((l) => l.proficiency)
            .reduce((a, b) => a + b) / subjectLessons.length;
        
        await unitOfWork.content.updateSubjectProficiency(
          _userId,
          subject.name,
          avgProficiency
        );
      }
      
      final topics = await unitOfWork.content.getTopicsBySubject(_userId, subject.name);
      for (final topic in topics) {
        final topicLessons = subjectLessons
            .where((l) => l.topicName == topic.name)
            .toList();
        if (topicLessons.isNotEmpty) {
          final avgProficiency = topicLessons
              .map((l) => l.proficiency)
              .reduce((a, b) => a + b) / topicLessons.length;
          
          await unitOfWork.content.updateTopicProficiency(
            _userId,
            subject.name,
            topic.name,
            avgProficiency
          );
        }
      }
    }
  }

  @override
  Future<Either<AppFailure, List<Subject>>> getSubjects() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      final subject = await localDataSource.getSubject(_userId, subjectName);
      return subject?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Topic>>> getTopicsBySubject(String subjectName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      final topics = await localDataSource.getTopicsBySubject(_userId, subjectName);
      return topics.map((t) => t.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, Topic?>> getTopic(String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      final topic = await localDataSource.getTopic(_userId, subjectName, topicName);
      return topic?.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
      return lessons.map((l) => l.toEntity()).toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Lesson>>> getAllLessons() async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
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
  Future<Either<AppFailure, Lesson>> updateLesson(Lesson lesson) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      final lessonModel = LessonModel.fromEntity(lesson);
      await localDataSource.insertOrUpdateLesson(lessonModel);
      
      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.updateLesson(lessonModel);
        } catch (e) {
          debugPrint('Non-critical failure: Could not update remote lesson: $e');
        }
      }
      
      return lesson;
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteLesson(String lessonId) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
          type: FailureType.network,
          message: 'Network connection required'
        );
      }

      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson == null) {
        throw const AppFailure(
          type: FailureType.cache,
          message: 'Lesson not found'
        );
      }

      final filesToDelete = await unitOfWork.file.getFilesByLessonId(lessonId);

      try {
        await remoteDataSource.deleteLesson(lessonId, _userId);
      } catch (e) {
        debugPrint('Non-critical failure: Could not delete remote lesson $lessonId: $e');
      }

      await localDataSource.deleteLesson(lessonId);

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e;
          });
        }
      }
    });
  }

  @override
  Future<Either<AppFailure, void>> deleteTopic(String subjectName, String topicName) async {
    return guard(() async {
      if (_userId.isEmpty) {
        throw const AppFailure(
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
          type: FailureType.network,
          message: 'Network connection required'
        );
      }

      final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
      final lessonIds = lessons.map((l) => l.id).toList();
      final filesToDelete = await unitOfWork.file.getFilesByLessonIds(lessonIds);

      try {
        await remoteDataSource.deleteLessonsByTopic(_userId, subjectName, topicName);
      } catch (e) {
        debugPrint('Non-critical failure: Could not delete remote topic $topicName: $e');
      }

      await localDataSource.deleteTopic(_userId, subjectName, topicName);

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e;
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
          type: FailureType.network,
          message: 'Network connection required'
        );
      }

      final lessons = await localDataSource.getAllLessons(_userId);
      final lessonIds = lessons.where((l) => l.subjectName == subjectName).map((l) => l.id).toList();
      final filesToDelete = await unitOfWork.file.getFilesByLessonIds(lessonIds);

      try {
        await remoteDataSource.deleteLessonsBySubject(_userId, subjectName);
      } catch (e) {
        debugPrint('Non-critical failure: Could not delete remote subject $subjectName: $e');
      }

      await localDataSource.deleteSubject(_userId, subjectName);

      for (final file in filesToDelete) {
        final localFile = File(file.filePath);
        if (await localFile.exists()) {
          await localFile.delete().catchError((e) {
            debugPrint('Failed to delete file from storage: $e');
            throw e;
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      if (!await connectionChecker.hasConnection) {
        throw const AppFailure(
          type: FailureType.network,
          message: 'No internet connection'
        );
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
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
          type: FailureType.auth,
          message: 'User not authenticated'
        );
      }
      
      final lessons = await localDataSource.getAllLessons(_userId);
      final subjects = await localDataSource.getSubjects(_userId);
      
      for (final subject in subjects) {
        final subjectLessons = lessons.where((l) => l.subjectName == subject.name).toList();
        if (subjectLessons.isNotEmpty) {
          final avgProficiency = subjectLessons
              .map((l) => l.proficiency)
              .reduce((a, b) => a + b) / subjectLessons.length;
          
          await localDataSource.updateSubjectProficiency(
            _userId,
            subject.name,
            avgProficiency
          );
        }
        
        final topics = await localDataSource.getTopicsBySubject(_userId, subject.name);
        for (final topic in topics) {
          final topicLessons = subjectLessons
              .where((l) => l.topicName == topic.name)
              .toList();
          if (topicLessons.isNotEmpty) {
            final avgProficiency = topicLessons
                .map((l) => l.proficiency)
                .reduce((a, b) => a + b) / topicLessons.length;
            
            await localDataSource.updateTopicProficiency(
              _userId,
              subject.name,
              topic.name,
              avgProficiency
            );
          }
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
          type: FailureType.cache,
          message: 'Lesson not found'
        );
      }

      final lockedLesson = lesson.copyWith(
        isLocked: true,
        lockedAt: DateTime.now(),
      );
      
      await localDataSource.insertOrUpdateLesson(lockedLesson);
      
      if (await connectionChecker.hasConnection) {
        try {
          await remoteDataSource.lockLesson(lessonId);
        } catch (e) {
          debugPrint('Non-critical failure: Could not lock remote lesson: $e');
        }
      }
    });
  }
}
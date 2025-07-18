// lib/features/content/data/repositories/content_repository_impl.dart
import 'package:dartz/dartz.dart';
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
          print('Failed to immediately sync updated lesson: $e');
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
      final lessons =
          await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
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
        await unitOfWork.flashcard.deleteFlashcardsByLesson(lessonId);
        await unitOfWork.content.deleteLesson(lessonId);
      });

      try {
        await remoteDataSource.deleteLesson(lessonId);
      } catch (e) {
        print('Non-critical failure: Could not delete remote lesson $lessonId: $e');
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
        for (final lesson in lessons) {
          await unitOfWork.flashcard.deleteFlashcardsByLesson(lesson.id);
          await unitOfWork.content.deleteLesson(lesson.id);
        }
        await unitOfWork.content.deleteTopic(_userId, subjectName, topicName);
      });

      try {
        await remoteDataSource.deleteLessonsByTopic(_userId, subjectName, topicName);
      } catch (e) {
        print(
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
          for (final lesson in lessons) {
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
        print(
            'Non-critical failure: Could not delete remote lessons for subject $subjectName: $e');
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
      await _rebuildContentHierarchy();
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
        throw const AppFailure(type: FailureType.cache, message: 'Lesson not found');
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

  Future<void> _updateContentHierarchy(
      String subjectName, String topicName, DateTime now) async {
    var topic = await localDataSource.getTopic(_userId, subjectName, topicName);
    if (topic == null) {
      topic = TopicModel(
        name: topicName,
        subjectName: subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        lastStudied: now,
        createdAt: now,
      );
    } else {
      topic = topic.copyWith(lessonCount: topic.lessonCount + 1, lastStudied: now);
    }
    await localDataSource.insertOrUpdateTopic(topic);

    var subject = await localDataSource.getSubject(_userId, subjectName);
    if (subject == null) {
      subject = SubjectModel(
        name: subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: 1,
        topicCount: 1,
        lastStudied: now,
        createdAt: now,
      );
    } else {
      final topicCount =
          (await localDataSource.getTopicsBySubject(_userId, subjectName)).length;
      subject = subject.copyWith(
          lessonCount: subject.lessonCount + 1,
          topicCount: topicCount,
          lastStudied: now);
    }
    await localDataSource.insertOrUpdateSubject(subject);
    await recalculateProficiencies();
  }

  Future<void> _cleanupEmptyTopicAndSubject(
      String subjectName, String topicName) async {
    final topicLessons =
        await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
    if (topicLessons.isEmpty) {
      await localDataSource.deleteTopic(_userId, subjectName, topicName);
      await _cleanupEmptySubject(subjectName);
    } else {
      final topic = await localDataSource.getTopic(_userId, subjectName, topicName);
      if (topic != null) {
        await localDataSource
            .insertOrUpdateTopic(topic.copyWith(lessonCount: topicLessons.length));
      }
      await _updateSubjectCounts(subjectName);
      await recalculateProficiencies();
    }
  }

  Future<void> _cleanupEmptySubject(String subjectName) async {
    final subjectTopics =
        await localDataSource.getTopicsBySubject(_userId, subjectName);
    if (subjectTopics.isEmpty) {
      await localDataSource.deleteSubject(_userId, subjectName);
    } else {
      await _updateSubjectCounts(subjectName);
      await recalculateProficiencies();
    }
  }

  Future<void> _updateSubjectCounts(String subjectName) async {
    final subject = await localDataSource.getSubject(_userId, subjectName);
    if (subject != null) {
      final topics =
          await localDataSource.getTopicsBySubject(_userId, subjectName);
      int totalLessons = 0;
      for (final topic in topics) {
        final lessons = await localDataSource.getLessonsByTopic(
            _userId, subjectName, topic.name);
        totalLessons += lessons.length;
      }
      await localDataSource.insertOrUpdateSubject(subject.copyWith(
          topicCount: topics.length, lessonCount: totalLessons));
    }
  }

  Future<void> _rebuildContentHierarchy() async {
    final lessons = await localDataSource.getAllLessons(_userId);
    final subjectMap = <String, Map<String, List<LessonModel>>>{};

    for (final lesson in lessons) {
      subjectMap.putIfAbsent(lesson.subjectName, () => {});
      subjectMap[lesson.subjectName]!
          .putIfAbsent(lesson.topicName, () => []);
      subjectMap[lesson.subjectName]![lesson.topicName]!.add(lesson);
    }

    for (final subjectEntry in subjectMap.entries) {
      final subjectName = subjectEntry.key;
      final topicsMap = subjectEntry.value;
      DateTime lastStudied = DateTime(1970);
      int totalLessons = 0;

      for (final topicEntry in topicsMap.entries) {
        final topicName = topicEntry.key;
        final topicLessons = topicEntry.value;
        totalLessons += topicLessons.length;
        for (final lesson in topicLessons) {
          if (lesson.lastReviewedAt != null &&
              lesson.lastReviewedAt!.isAfter(lastStudied)) {
            lastStudied = lesson.lastReviewedAt!;
          }
        }
        final topic = TopicModel(
          name: topicName,
          subjectName: subjectName,
          userId: _userId,
          proficiency: 0.0,
          lessonCount: topicLessons.length,
          lastStudied: lastStudied,
          createdAt: topicLessons
              .map((l) => l.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
        );
        await localDataSource.insertOrUpdateTopic(topic);
      }

      final subject = SubjectModel(
        name: subjectName,
        userId: _userId,
        proficiency: 0.0,
        lessonCount: totalLessons,
        topicCount: topicsMap.length,
        lastStudied: lastStudied,
        createdAt: DateTime.now(),
      );
      await localDataSource.insertOrUpdateSubject(subject);
    }
    await recalculateProficiencies();
  }
}
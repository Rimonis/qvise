import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
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
  final _uuid = const Uuid();
  
  ContentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectionChecker,
    required this.firebaseAuth,
  });
  
  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  
  @override
  Future<Either<Failure, List<Subject>>> getSubjects() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final subjects = await localDataSource.getSubjects(_userId);
      return Right(subjects.map((s) => s.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get subjects: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Subject>> getSubject(String subjectName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final subject = await localDataSource.getSubject(_userId, subjectName);
      if (subject == null) {
        return Left(CacheFailure('Subject not found'));
      }
      
      return Right(subject.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get subject: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<Topic>>> getTopicsBySubject(String subjectName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final topics = await localDataSource.getTopicsBySubject(_userId, subjectName);
      return Right(topics.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get topics: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Topic>> getTopic(String subjectName, String topicName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final topic = await localDataSource.getTopic(_userId, subjectName, topicName);
      if (topic == null) {
        return Left(CacheFailure('Topic not found'));
      }
      
      return Right(topic.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get topic: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByTopic(String subjectName, String topicName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
      return Right(lessons.map((l) => l.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get lessons: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<Lesson>>> getAllLessons() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final lessons = await localDataSource.getAllLessons(_userId);
      return Right(lessons.map((l) => l.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get all lessons: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, List<Lesson>>> getDueLessons() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final lessons = await localDataSource.getAllLessons(_userId);
      final now = DateTime.now();
      
      // Only include locked lessons that are due for review
      final dueLessons = lessons
          .where((lesson) => lesson.isLocked && 
                           (lesson.nextReviewDate.isBefore(now) || lesson.nextReviewDate.isAtSameMomentAs(now)))
          .map((l) => l.toEntity())
          .toList();
      
      return Right(dueLessons);
    } catch (e) {
      return Left(CacheFailure('Failed to get due lessons: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Lesson>> getLesson(String lessonId) async {
    try {
      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson == null) {
        return Left(CacheFailure('Lesson not found'));
      }
      
      return Right(lesson.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get lesson: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Lesson>> createLesson(CreateLessonParams params) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      // Check network connection
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('Network connection required to create lessons'));
      }
      
      // Create lesson model
      final now = DateTime.now();
      final lessonModel = LessonModel(
        id: _uuid.v4(),
        userId: _userId,
        subjectName: params.subjectName,
        topicName: params.topicName,
        title: params.lessonTitle,
        createdAt: now,
        nextReviewDate: now.add(const Duration(days: 1)), // First review after 1 day
        reviewStage: 0,
        proficiency: 0.0,
        isSynced: false,
      );
      
      // Create lesson in Firestore first
      final syncedLesson = await remoteDataSource.createLesson(lessonModel);
      
      // Save to local database
      await localDataSource.insertOrUpdateLesson(syncedLesson);
      
      // Update or create topic and subject
      await _updateContentHierarchy(params.subjectName, params.topicName, now);
      
      return Right(syncedLesson.toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to create lesson: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson) async {
    try {
      final lessonModel = LessonModel.fromEntity(lesson);
      
      // Update locally first
      await localDataSource.insertOrUpdateLesson(lessonModel);
      
      // Sync to remote if online
      if (await connectionChecker.hasConnection) {
        await remoteDataSource.updateLesson(lessonModel);
        await localDataSource.markLessonAsSynced(lesson.id);
      }
      
      // Recalculate proficiencies
      await recalculateProficiencies();
      
      return Right(lesson);
    } catch (e) {
      return Left(CacheFailure('Failed to update lesson: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteLesson(String lessonId) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      // Check network connection
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('Network connection required to delete content'));
      }
      
      // Get lesson details before deletion
      final lesson = await localDataSource.getLesson(lessonId);
      if (lesson == null) {
        return Left(CacheFailure('Lesson not found'));
      }
      
      // Delete from remote
      await remoteDataSource.deleteLesson(lessonId);
      
      // Delete from local
      await localDataSource.deleteLesson(lessonId);
      
      // Check if topic is empty and delete if necessary
      await _cleanupEmptyTopicAndSubject(lesson.subjectName, lesson.topicName);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete lesson: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteTopic(String subjectName, String topicName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      // Check network connection
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('Network connection required to delete content'));
      }
      
      // Delete all lessons in the topic from remote
      await remoteDataSource.deleteLessonsByTopic(_userId, subjectName, topicName);
      
      // Delete lessons from local
      final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
      for (final lesson in lessons) {
        await localDataSource.deleteLesson(lesson.id);
      }
      
      // Delete topic
      await localDataSource.deleteTopic(_userId, subjectName, topicName);
      
      // Check if subject is empty and delete if necessary
      await _cleanupEmptySubject(subjectName);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete topic: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteSubject(String subjectName) async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      // Check network connection
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('Network connection required to delete content'));
      }
      
      // Delete all lessons in the subject from remote
      await remoteDataSource.deleteLessonsBySubject(_userId, subjectName);
      
      // Delete all topics and lessons from local
      final topics = await localDataSource.getTopicsBySubject(_userId, subjectName);
      for (final topic in topics) {
        final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topic.name);
        for (final lesson in lessons) {
          await localDataSource.deleteLesson(lesson.id);
        }
        await localDataSource.deleteTopic(_userId, subjectName, topic.name);
      }
      
      // Delete subject
      await localDataSource.deleteSubject(_userId, subjectName);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete subject: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> syncLessons() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      if (!await connectionChecker.hasConnection) {
        return const Left(NetworkFailure('No internet connection'));
      }
      
      // Get unsynced lessons
      final unsyncedLessons = await localDataSource.getUnsyncedLessons(_userId);
      
      if (unsyncedLessons.isNotEmpty) {
        // Sync to remote
        await remoteDataSource.syncLessons(unsyncedLessons);
        
        // Mark as synced
        for (final lesson in unsyncedLessons) {
          await localDataSource.markLessonAsSynced(lesson.id);
        }
      }
      
      // Get all lessons from remote
      final remoteLessons = await remoteDataSource.getUserLessons(_userId);
      
      // Update local database
      for (final lesson in remoteLessons) {
        await localDataSource.insertOrUpdateLesson(lesson);
      }
      
      // Rebuild content hierarchy
      await _rebuildContentHierarchy();
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to sync lessons: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> hasUnsyncedLessons() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      final unsyncedLessons = await localDataSource.getUnsyncedLessons(_userId);
      return Right(unsyncedLessons.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure('Failed to check unsynced lessons: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> recalculateProficiencies() async {
    try {
      if (_userId.isEmpty) {
        return const Left(AuthFailure('User not authenticated'));
      }
      
      // Get all subjects
      final subjects = await localDataSource.getSubjects(_userId);
      
      for (final subject in subjects) {
        // Get all topics in subject
        final topics = await localDataSource.getTopicsBySubject(_userId, subject.name);
        double totalSubjectProficiency = 0;
        
        for (final topic in topics) {
          // Get all lessons in topic
          final lessons = await localDataSource.getLessonsByTopic(_userId, subject.name, topic.name);
          
          if (lessons.isNotEmpty) {
            // Calculate topic proficiency as average of lesson proficiencies
            final topicProficiency = lessons.fold<double>(
              0,
              (sum, lesson) => sum + lesson.proficiency,
            ) / lessons.length;
            
            // Update topic proficiency
            await localDataSource.updateTopicProficiency(_userId, subject.name, topic.name, topicProficiency);
            
            totalSubjectProficiency += topicProficiency;
          }
        }
        
        if (topics.isNotEmpty) {
          // Calculate subject proficiency as average of topic proficiencies
          final subjectProficiency = totalSubjectProficiency / topics.length;
          
          // Update subject proficiency
          await localDataSource.updateSubjectProficiency(_userId, subject.name, subjectProficiency);
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to recalculate proficiencies: ${e.toString()}'));
    }
  }
  
  // Helper methods
  Future<void> _updateContentHierarchy(String subjectName, String topicName, DateTime now) async {
    // Check if topic exists
    var topic = await localDataSource.getTopic(_userId, subjectName, topicName);
    if (topic == null) {
      // Create new topic
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
      // Update existing topic
      topic = topic.copyWith(
        lessonCount: topic.lessonCount + 1,
        lastStudied: now,
      );
    }
    await localDataSource.insertOrUpdateTopic(topic);
    
    // Check if subject exists
    var subject = await localDataSource.getSubject(_userId, subjectName);
    if (subject == null) {
      // Create new subject
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
      // Update existing subject
      final topicCount = (await localDataSource.getTopicsBySubject(_userId, subjectName)).length;
      subject = subject.copyWith(
        lessonCount: subject.lessonCount + 1,
        topicCount: topicCount,
        lastStudied: now,
      );
    }
    await localDataSource.insertOrUpdateSubject(subject);
    
    // Recalculate proficiencies
    await recalculateProficiencies();
  }
  
  Future<void> _cleanupEmptyTopicAndSubject(String subjectName, String topicName) async {
    // Check if topic has any lessons left
    final topicLessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topicName);
    if (topicLessons.isEmpty) {
      // Delete empty topic
      await localDataSource.deleteTopic(_userId, subjectName, topicName);
      
      // Check if subject is empty
      await _cleanupEmptySubject(subjectName);
    } else {
      // Update topic lesson count
      final topic = await localDataSource.getTopic(_userId, subjectName, topicName);
      if (topic != null) {
        await localDataSource.insertOrUpdateTopic(
          topic.copyWith(lessonCount: topicLessons.length),
        );
      }
      
      // Update subject lesson count
      await _updateSubjectCounts(subjectName);
      
      // Recalculate proficiencies
      await recalculateProficiencies();
    }
  }
  
  Future<void> _cleanupEmptySubject(String subjectName) async {
    // Check if subject has any topics left
    final subjectTopics = await localDataSource.getTopicsBySubject(_userId, subjectName);
    if (subjectTopics.isEmpty) {
      // Delete empty subject
      await localDataSource.deleteSubject(_userId, subjectName);
    } else {
      // Update subject counts
      await _updateSubjectCounts(subjectName);
      
      // Recalculate proficiencies
      await recalculateProficiencies();
    }
  }
  
  Future<void> _updateSubjectCounts(String subjectName) async {
    final subject = await localDataSource.getSubject(_userId, subjectName);
    if (subject != null) {
      final topics = await localDataSource.getTopicsBySubject(_userId, subjectName);
      int totalLessons = 0;
      
      for (final topic in topics) {
        final lessons = await localDataSource.getLessonsByTopic(_userId, subjectName, topic.name);
        totalLessons += lessons.length;
      }
      
      await localDataSource.insertOrUpdateSubject(
        subject.copyWith(
          topicCount: topics.length,
          lessonCount: totalLessons,
        ),
      );
    }
  }
  
  Future<void> _rebuildContentHierarchy() async {
    // Get all lessons
    final lessons = await localDataSource.getAllLessons(_userId);
    
    // Group by subject and topic
    final subjectMap = <String, Map<String, List<LessonModel>>>{};
    
    for (final lesson in lessons) {
      subjectMap.putIfAbsent(lesson.subjectName, () => {});
      subjectMap[lesson.subjectName]!.putIfAbsent(lesson.topicName, () => []);
      subjectMap[lesson.subjectName]![lesson.topicName]!.add(lesson);
    }
    
    // Create/update subjects and topics
    for (final subjectEntry in subjectMap.entries) {
      final subjectName = subjectEntry.key;
      final topicsMap = subjectEntry.value;
      
      DateTime lastStudied = DateTime(1970);
      int totalLessons = 0;
      
      for (final topicEntry in topicsMap.entries) {
        final topicName = topicEntry.key;
        final topicLessons = topicEntry.value;
        
        totalLessons += topicLessons.length;
        
        // Find latest study date
        for (final lesson in topicLessons) {
          if (lesson.lastReviewedAt != null && lesson.lastReviewedAt!.isAfter(lastStudied)) {
            lastStudied = lesson.lastReviewedAt!;
          }
        }
        
        // Create/update topic
        final topic = TopicModel(
          name: topicName,
          subjectName: subjectName,
          userId: _userId,
          proficiency: 0.0, // Will be calculated later
          lessonCount: topicLessons.length,
          lastStudied: lastStudied,
          createdAt: topicLessons.map((l) => l.createdAt).reduce((a, b) => a.isBefore(b) ? a : b),
        );
        
        await localDataSource.insertOrUpdateTopic(topic);
      }
      
      // Create/update subject
      final subject = SubjectModel(
        name: subjectName,
        userId: _userId,
        proficiency: 0.0, // Will be calculated later
        lessonCount: totalLessons,
        topicCount: topicsMap.length,
        lastStudied: lastStudied,
        createdAt: DateTime.now(), // Use current time for subjects
      );
      
      await localDataSource.insertOrUpdateSubject(subject);
    }
    
    // Recalculate all proficiencies
    await recalculateProficiencies();
  }
}
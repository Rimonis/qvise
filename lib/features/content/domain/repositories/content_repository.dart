// lib/features/content/domain/repositories/content_repository.dart

import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import '../entities/subject.dart';
import '../entities/topic.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';

abstract class ContentRepository {
  Future<Either<AppFailure, List<Subject>>> getSubjects();
  Future<Either<AppFailure, Subject?>> getSubject(String subjectName);
  Future<Either<AppFailure, List<Topic>>> getTopicsBySubject(String subjectName);
  Future<Either<AppFailure, Topic?>> getTopic(String subjectName, String topicName);
  Future<Either<AppFailure, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName);
  Future<Either<AppFailure, List<Lesson>>> getAllLessons();
  Future<Either<AppFailure, List<Lesson>>> getDueLessons();
  Future<Either<AppFailure, Lesson?>> getLesson(String lessonId);
  Future<Either<AppFailure, Lesson>> createLesson(CreateLessonParams params);
  Future<Either<AppFailure, Lesson>> updateLesson(Lesson lesson);
  Future<Either<AppFailure, void>> deleteLesson(String lessonId);
  Future<Either<AppFailure, void>> deleteTopic(
      String subjectName, String topicName);
  Future<Either<AppFailure, void>> deleteSubject(String subjectName);
  Future<Either<AppFailure, void>> syncLessons();
  Future<Either<AppFailure, bool>> hasUnsyncedLessons();
  Future<Either<AppFailure, void>> recalculateProficiencies();
  Future<Either<AppFailure, void>> lockLesson(String lessonId);
}
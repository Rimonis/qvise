// lib/features/content/domain/repositories/content_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/app_error.dart';
import '../entities/subject.dart';
import '../entities/topic.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';

abstract class ContentRepository {
  Future<Either<AppError, List<Subject>>> getSubjects();
  Future<Either<AppError, Subject?>> getSubject(String subjectName);
  Future<Either<AppError, List<Topic>>> getTopicsBySubject(String subjectName);
  Future<Either<AppError, Topic?>> getTopic(String subjectName, String topicName);
  Future<Either<AppError, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName);
  Future<Either<AppError, List<Lesson>>> getAllLessons();
  Future<Either<AppError, List<Lesson>>> getDueLessons();
  Future<Either<AppError, Lesson?>> getLesson(String lessonId);
  Future<Either<AppError, Lesson>> createLesson(CreateLessonParams params);
  Future<Either<AppError, Lesson>> updateLesson(Lesson lesson);
  Future<Either<AppError, void>> deleteLesson(String lessonId);
  Future<Either<AppError, void>> deleteTopic(
      String subjectName, String topicName);
  Future<Either<AppError, void>> deleteSubject(String subjectName);
  Future<Either<AppError, void>> syncLessons();
  Future<Either<AppError, bool>> hasUnsyncedLessons();
  Future<Either<AppError, void>> recalculateProficiencies();
  Future<Either<AppError, void>> lockLesson(String lessonId);
  Future<Either<AppError, void>> updateLessonContentCount(String lessonId);
}

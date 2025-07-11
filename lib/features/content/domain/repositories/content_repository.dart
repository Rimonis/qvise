// lib/features/content/domain/repositories/content_repository.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import '../entities/subject.dart';
import '../entities/topic.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';

abstract class ContentRepository {
  Future<Either<AppError, List<Subject>>> getSubjects();
  Future<Either<AppError, List<Topic>>> getTopicsBySubject(String subjectName);
  Future<Either<AppError, List<Lesson>>> getLessonsByTopic(String subjectName, String topicName);
  Future<Either<AppError, List<Lesson>>> getDueLessons();
  Future<Either<AppError, Lesson>> createLesson(CreateLessonParams params);
  Future<Either<AppError, void>> deleteLesson(String lessonId);
  Future<Either<AppError, void>> deleteTopic(String subjectName, String topicName);
}
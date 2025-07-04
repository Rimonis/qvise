// lib/features/content/domain/repositories/content_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subject.dart';
import '../entities/topic.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';

abstract class ContentRepository {
  Future<Either<Failure, List<Subject>>> getSubjects();
  Future<Either<Failure, Subject?>> getSubject(String subjectName);
  Future<Either<Failure, List<Topic>>> getTopicsBySubject(String subjectName);
  Future<Either<Failure, Topic?>> getTopic(String subjectName, String topicName);
  Future<Either<Failure, List<Lesson>>> getLessonsByTopic(
      String subjectName, String topicName);
  Future<Either<Failure, List<Lesson>>> getAllLessons();
  Future<Either<Failure, List<Lesson>>> getDueLessons();
  Future<Either<Failure, Lesson?>> getLesson(String lessonId);
  Future<Either<Failure, Lesson>> createLesson(CreateLessonParams params);
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson);
  Future<Either<Failure, void>> deleteLesson(String lessonId);
  Future<Either<Failure, void>> deleteTopic(
      String subjectName, String topicName);
  Future<Either<Failure, void>> deleteSubject(String subjectName);
  Future<Either<Failure, void>> syncLessons();
  Future<Either<Failure, bool>> hasUnsyncedLessons();
  Future<Either<Failure, void>> recalculateProficiencies();
  Future<Either<Failure, void>> lockLesson(String lessonId);
  Future<Either<Failure, void>> updateLessonContentCount(String lessonId);
}
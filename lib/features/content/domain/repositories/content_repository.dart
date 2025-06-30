import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subject.dart';
import '../entities/topic.dart';
import '../entities/lesson.dart';
import '../entities/create_lesson_params.dart';

abstract class ContentRepository {
  // Subject operations
  Future<Either<Failure, List<Subject>>> getSubjects();
  Future<Either<Failure, Subject>> getSubject(String subjectName);
  
  // Topic operations  
  Future<Either<Failure, List<Topic>>> getTopicsBySubject(String subjectName);
  Future<Either<Failure, Topic>> getTopic(String subjectName, String topicName);
  
  // Lesson operations
  Future<Either<Failure, List<Lesson>>> getLessonsByTopic(String subjectName, String topicName);
  Future<Either<Failure, List<Lesson>>> getAllLessons();
  Future<Either<Failure, List<Lesson>>> getDueLessons();
  Future<Either<Failure, Lesson>> getLesson(String lessonId);
  Future<Either<Failure, Lesson>> createLesson(CreateLessonParams params);
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson);
  
  // Deletion operations (online only)
  Future<Either<Failure, void>> deleteLesson(String lessonId);
  Future<Either<Failure, void>> deleteTopic(String subjectName, String topicName);
  Future<Either<Failure, void>> deleteSubject(String subjectName);
  
  // Sync operations
  Future<Either<Failure, void>> syncLessons();
  Future<Either<Failure, bool>> hasUnsyncedLessons();
  
  // Proficiency calculations
  Future<Either<Failure, void>> recalculateProficiencies();
}
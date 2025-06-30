import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';

class GetLessonsByTopic {
  final ContentRepository repository;

  GetLessonsByTopic(this.repository);

  Future<Either<Failure, List<Lesson>>> call(String subjectName, String topicName) async {
    return await repository.getLessonsByTopic(subjectName, topicName);
  }
}
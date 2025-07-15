// lib/features/content/domain/usecases/get_lessons_by_topic.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/entities/lesson.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class GetLessonsByTopic {
  final ContentRepository repository;

  GetLessonsByTopic(this.repository);

  Future<Either<AppFailure, List<Lesson>>> call(String subjectName, String topicName) async {
    return await repository.getLessonsByTopic(subjectName, topicName);
  }
}

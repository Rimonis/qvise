// lib/features/content/domain/usecases/get_lessons_by_topic.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/lesson.dart';
import '../repositories/content_repository.dart';

class GetLessonsByTopicParams {
  final String subjectName;
  final String topicName;

  GetLessonsByTopicParams({
    required this.subjectName,
    required this.topicName,
  });
}

class GetLessonsByTopic implements UseCase<List<Lesson>, GetLessonsByTopicParams> {
  final ContentRepository repository;

  GetLessonsByTopic(this.repository);

  @override
  Future<Either<AppError, List<Lesson>>> call(GetLessonsByTopicParams params) async {
    return await repository.getLessonsByTopic(params.subjectName, params.topicName);
  }
}

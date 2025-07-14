// lib/features/content/domain/usecases/get_topics_by_subject.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/topic.dart';
import '../repositories/content_repository.dart';

class GetTopicsBySubjectParams {
  final String subjectName;

  GetTopicsBySubjectParams({required this.subjectName});
}

class GetTopicsBySubject implements UseCase<List<Topic>, GetTopicsBySubjectParams> {
  final ContentRepository repository;

  GetTopicsBySubject(this.repository);

  @override
  Future<Either<AppError, List<Topic>>> call(GetTopicsBySubjectParams params) async {
    return await repository.getTopicsBySubject(params.subjectName);
  }
}

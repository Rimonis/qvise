// lib/features/content/domain/usecases/delete_topic.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/content_repository.dart';

class DeleteTopicParams {
  final String subjectName;
  final String topicName;

  DeleteTopicParams({
    required this.subjectName,
    required this.topicName,
  });
}

class DeleteTopic implements VoidUseCase<DeleteTopicParams> {
  final ContentRepository repository;

  DeleteTopic(this.repository);

  @override
  Future<Either<AppError, void>> call(DeleteTopicParams params) async {
    return await repository.deleteTopic(params.subjectName, params.topicName);
  }
}

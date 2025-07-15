// lib/features/content/domain/usecases/delete_topic.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class DeleteTopic {
  final ContentRepository repository;

  DeleteTopic(this.repository);

  Future<Either<AppFailure, void>> call(String subjectName, String topicName) async {
    return await repository.deleteTopic(subjectName, topicName);
  }
}

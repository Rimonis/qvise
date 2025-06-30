import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';


class DeleteTopic {
  final ContentRepository repository;

  DeleteTopic(this.repository);

  Future<Either<Failure, void>> call(String subjectName, String topicName) async {
    return await repository.deleteTopic(subjectName, topicName);
  }
}
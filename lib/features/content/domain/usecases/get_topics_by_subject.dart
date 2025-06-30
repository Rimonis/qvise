import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/entities/topic.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';


class GetTopicsBySubject {
  final ContentRepository repository;

  GetTopicsBySubject(this.repository);

  Future<Either<Failure, List<Topic>>> call(String subjectName) async {
    return await repository.getTopicsBySubject(subjectName);
  }
}
import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';


class GetSubjects {
  final ContentRepository repository;

  GetSubjects(this.repository);

  Future<Either<Failure, List<Subject>>> call() async {
    return await repository.getSubjects();
  }
}
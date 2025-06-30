import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';

class DeleteSubject {
  final ContentRepository repository;

  DeleteSubject(this.repository);

  Future<Either<Failure, void>> call(String subjectName) async {
    return await repository.deleteSubject(subjectName);
  }
}
import 'package:dartz/dartz.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import '../../../../../core/error/failures.dart';

class DeleteLesson {
  final ContentRepository repository;

  DeleteLesson(this.repository);

  Future<Either<Failure, void>> call(String lessonId) async {
    return await repository.deleteLesson(lessonId);
  }
}
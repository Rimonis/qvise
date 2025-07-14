// lib/features/content/domain/usecases/get_subjects.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../entities/subject.dart';
import '../repositories/content_repository.dart';

class GetSubjects implements UseCase<List<Subject>, NoParams> {
  final ContentRepository repository;

  GetSubjects(this.repository);

  @override
  Future<Either<AppError, List<Subject>>> call(NoParams params) async {
    return await repository.getSubjects();
  }
}

// lib/features/content/domain/usecases/delete_subject.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class DeleteSubject {
  final ContentRepository repository;

  DeleteSubject(this.repository);

  Future<Either<AppFailure, void>> call(String subjectName) async {
    return await repository.deleteSubject(subjectName);
  }
}

// lib/features/content/domain/usecases/get_subjects.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_failure.dart';
import 'package:qvise/features/content/domain/entities/subject.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';

class GetSubjects {
  final ContentRepository repository;

  GetSubjects(this.repository);

  Future<Either<AppFailure, List<Subject>>> call() async {
    return await repository.getSubjects();
  }
}
